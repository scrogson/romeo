defmodule Romeo.Transports.TCP do
  @moduledoc false

  @default_port 5222
  @ssl_opts [reuse_sessions: true]
  @socket_opts [packet: :raw, mode: :binary, active: :once]

  @type state :: Romeo.Connection.t

  use Romeo.XML

  alias Romeo.Connection.Features
  alias Romeo.Connection, as: Conn

  require Logger

  import Kernel, except: [send: 2]

  @spec connect(Keyword.t) :: {:ok, state} | {:error, any}
  def connect(%Conn{host: host, port: port, socket_opts: socket_opts} = conn) do
    host = (host || host(conn.jid)) |> to_char_list
    port = (port || @default_port)

    conn = %{conn | host: host, port: port, socket_opts: socket_opts}

    case :gen_tcp.connect(host, port, socket_opts ++ @socket_opts, conn.timeout) do
      {:ok, socket} ->
        Logger.info fn -> "Established connection to #{host}" end
        parser = :fxml_stream.new(self(), :infinity, [:no_gen_server])
        start_protocol(%{conn | parser: parser, socket: {:gen_tcp, socket}})
      {:error, _} = error ->
        error
    end
  end

  def disconnect(info, {mod, socket}) do
    :ok = mod.close(socket)
    case info do
      {:close, from} ->
        Connection.reply(from, :ok)
      {:error, :closed} ->
        :error_logger.format("Connection closed~n", [])
      {:error, reason} ->
        reason = :inet.format_error(reason)
        :error_logger.format("Connection error: ~s~n", [reason])
    end
  end

  defp start_protocol(%Conn{stream_ns: stream_ns} = conn) do
    cond do
      stream_ns == ns_component_accept ->
        conn
        |> start_stream(ns_component_accept)
        |> handshake!
        |> ready
      stream_ns == ns_jabber_client ->
        conn
        |> start_stream
        |> negotiate_features
        |> maybe_start_tls
        |> authenticate
        |> bind
        |> session
        |> ready
      true ->
        raise Romeo.Error, "Unsupported stream namespace '#{stream_ns}'."
    end
  end
  
  defp start_stream(%Conn{jid: jid} = conn, xmlns \\ ns_jabber_client) do
    conn
    |> send(jid |> host |> Romeo.Stanza.start_stream(xmlns))
    |> recv(fn conn, xmlstreamstart() -> conn end)
  end
  
  defp handshake!(%Conn{stream_id: stream_id} = conn) do
    hash = :crypto.hash(:sha, "#{stream_id}#{conn.password}")
    |> Base.encode16
    |> String.downcase

    handshake = Stanza.handshake(hash)
    
    conn
    |> send(handshake)
    |> recv(fn
      conn, [xmlel(name: "handshake")] ->
        conn
      _conn, [xmlel(name: "stream:error"), xmlstreamend()] ->
        raise Romeo.Auth.Error, "handshake"
    end)
  end
  
  defp negotiate_features(%Conn{} = conn) do
    recv(conn, fn conn, xmlel(name: "stream:features") = packet ->
      %{conn | features: Features.parse_stream_features(packet)}
    end)
  end

  defp maybe_start_tls(%Conn{features: %Features{tls?: true}} = conn) do
    conn
    |> send(Stanza.start_tls)
    |> recv(fn conn, xmlel(name: "proceed") -> conn end)
    |> upgrade_to_tls
    |> start_stream
    |> negotiate_features
  end
  defp maybe_start_tls(%Conn{} = conn), do: conn

  defp upgrade_to_tls(%Conn{parser: parser, socket: {:gen_tcp, socket}} = conn) do
    Logger.info fn -> "Negotiating secure connection" end

    {:ok, socket} = :ssl.connect(socket, conn.ssl_opts ++ @ssl_opts)
    parser = :fxml_stream.reset(parser)

    Logger.info fn -> "Connection successfully secured" end
    %{conn | socket: {:ssl, socket}, parser: parser}
  end

  defp authenticate(%Conn{} = conn) do
    conn
    |> Romeo.Auth.authenticate!
    |> reset_parser
    |> start_stream
    |> negotiate_features
  end

  defp bind(%Conn{owner: owner, resource: resource} = conn) do
    stanza = Romeo.Stanza.bind(resource)
    id = Romeo.XML.attr(stanza, "id")

    conn
    |> send(stanza)
    |> recv(fn conn, xmlel(name: "iq") = stanza ->
      "result" = Romeo.XML.attr(stanza, "type")
      ^id = Romeo.XML.attr(stanza, "id")

      %Romeo.JID{resource: resource} =
        stanza
        |> Romeo.XML.subelement("bind")
        |> Romeo.XML.subelement("jid")
        |> Romeo.XML.cdata
        |> Romeo.JID.parse

      Logger.info fn -> "Bound to resource: #{resource}" end
      Kernel.send(owner, {:resource_bound, resource})
      %{conn | resource: resource}
    end)
  end

  defp session(%Conn{} = conn) do
    stanza = Romeo.Stanza.session
    id = Romeo.XML.attr(stanza, "id")

    conn
    |> send(stanza)
    |> recv(fn conn, xmlel(name: "iq") = stanza ->
      "result" = Romeo.XML.attr(stanza, "type")
      ^id = Romeo.XML.attr(stanza, "id")

      Logger.info fn -> "Session established" end
      conn
    end)
  end

  defp ready(%Conn{owner: owner} = conn) do
    Kernel.send(owner, :connection_ready)
    {:ok, conn}
  end

  defp reset_parser(%Conn{parser: parser} = conn) do
    parser = :fxml_stream.reset(parser)
    %{conn | parser: parser}
  end

  defp parse_data(%Conn{jid: jid, owner: owner, parser: parser} = conn, data, send_to_owner \\ false) do
    parser = :fxml_stream.parse(parser, data)

    stanza =
      receive do
        {:xmlstreamstart, _, _} = stanza -> stanza
        {:xmlstreamend, _} = stanza      -> stanza
        {:xmlstreamraw, stanza}          -> stanza
        {:xmlstreamcdata, stanza}        -> stanza
        {:xmlstreamerror, _} = stanza    -> stanza
        {:xmlstreamelement, stanza}      -> stanza
      end

    Logger.debug fn -> "[#{jid}][INCOMING] #{inspect data}" end

    if send_to_owner do
      Kernel.send(owner, {:stanza, stanza})
    end

    {:ok, %{conn | parser: parser}, stanza}
  end

  def send(%Conn{jid: jid, socket: {mod, socket}} = conn, stanza) do
    stanza = Romeo.XML.encode!(stanza)
    Logger.debug fn -> "[#{jid}][OUTGOING] #{inspect stanza}" end
    :ok = mod.send(socket, stanza)
    {:ok, conn}
  end

  def recv({:ok, conn}, fun), do: recv(conn, fun)
  def recv(%Conn{socket: {:gen_tcp, socket}, timeout: timeout} = conn, fun) do
    receive do
      {:xmlstreamelement, stanza} ->
        fun.(conn, stanza)
      {:tcp, ^socket, data} ->
        :ok = activate({:gen_tcp, socket})
        {:ok, conn, stanza} = parse_data(conn, data)
        fun.(conn, stanza)
      {:tcp_closed, ^socket} ->
        {:error, :closed}
      {:tcp_error, ^socket, reason} ->
        {:error, reason}
    after timeout ->
      Kernel.send(self, {:error, :timeout})
      conn
    end
  end
  def recv(%Conn{socket: {:ssl, socket}, timeout: timeout} = conn, fun) do
    receive do
      {:xmlstreamelement, stanza} ->
        fun.(conn, stanza)
      {:ssl, ^socket, data} ->
        :ok = activate({:ssl, socket})
        {:ok, conn, stanza} = parse_data(conn, data)
        fun.(conn, stanza)
      {:ssl_closed, ^socket} ->
        {:error, :closed}
      {:ssl_error, ^socket, reason} ->
        {:error, reason}
    after timeout ->
      Kernel.send(self, {:error, :timeout})
      conn
    end
  end

  def handle_message({:tcp, socket, data}, %{socket: {:gen_tcp, socket}} = conn) do
    {:ok, _, _} = handle_data(data, conn)
  end
  def handle_message({:tcp_closed, socket}, %{socket: {:gen_tcp, socket}}) do
    {:error, :closed}
  end
  def handle_message({:tcp_error, socket, reason}, %{socket: {:gen_tcp, socket}}) do
    {:error, reason}
  end
  def handle_message({:ssl, socket, data}, %{socket: {:ssl, socket}} = conn) do
    {:ok, _, _} = handle_data(data, conn)
  end
  def handle_message({:ssl_closed, socket}, %{socket: {:ssl, socket}}) do
    {:error, :closed}
  end
  def handle_message({:ssl_error, socket, reason}, %{socket: {:ssl, socket}}) do
    {:error, reason}
  end
  def handle_message(_, _), do: :unknown

  defp handle_data(data, %{socket: socket} = conn) do
    :ok = activate(socket)
    {:ok, _conn, _stanza} = parse_data(conn, data, false)
  end

  defp activate({:gen_tcp, socket}) do
    case :inet.setopts(socket, [active: :once]) do
      :ok ->
        :ok
      {:error, :closed} ->
        _ = Kernel.send(self, {:tcp_closed, socket})
        :ok
      {:error, reason} ->
        _ = Kernel.send(self, {:tcp_error, socket, reason})
        :ok
    end
  end
  defp activate({:ssl, socket}) do
    case :ssl.setopts(socket, [active: :once]) do
      :ok ->
        :ok
      {:error, :closed} ->
        _ = Kernel.send(self, {:ssl_closed, socket})
        :ok
      {:error, reason} ->
        _ = Kernel.send(self, {:ssl_error, socket, reason})
        :ok
    end
  end

  defp host(jid) do
    Romeo.JID.parse(jid).server
  end
end
