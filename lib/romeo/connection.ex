defmodule Romeo.Connection do
  @moduledoc false

  @timeout 5_000
  @default_transport Romeo.Transports.TCP

  alias Romeo.Connection.Features

  defstruct features: %Features{},
            host: nil,
            jid: nil,
            nickname: "",
            owner: nil,
            parser: nil,
            password: nil,
            port: nil,
            preferred_auth_mechanisms: [],
            require_tls: false,
            resource: "",
            rooms: [],
            ssl_opts: [],
            socket: nil,
            socket_opts: [],
            timeout: nil,
            transport: nil

  use Connection

  require Logger

  ### PUBLIC API ###

  @doc """
  Start the connection process and connect to an XMPP server.

  ## Options

    * `:host` - Server hostname (default: inferred by the JID);
    * `:jid` - User jabber ID;
    * `:password` - User password;
    * `:port` - Server port (default: based on the transport);
    * `:require_tls` - Set to `false` if ssl should not be used (default: `true`);
    * `:ssl_opts` - A list of ssl options, see ssl docs;
    * `:socket_opts` - Options to be given to the underlying socket;
    * `:timeout` - Connect timeout in milliseconds (default: `#{@timeout}`);
    * `:transport` - Transport handles the protocol (default: `#{@default_transport}`);
  """
  def start_link(opts) do
    opts =
      opts
      |> Keyword.put_new(:timeout, @timeout)
      |> Keyword.put_new(:transport, @default_transport)
      |> Keyword.put(:owner, self)

    Connection.start_link(__MODULE__, struct(__MODULE__, opts))
  end

  @doc """
  Send a message via the underlying transport.
  """
  def send(pid, data) do
    Connection.call(pid, {:send, data})
  end

  @doc """
  Stop the process and disconnect.

  ## Options

    * `:timeout` - Call timeout (default: `#{@timeout}`)
  """
  @spec close(pid, Keyword.t) :: :ok
  def close(pid, opts \\ []) do
    Connection.call(pid, :close, opts[:timeout] || @timeout)
  end

  ## Connection callbacks

  def init(conn) do
    {:connect, :init, conn}
  end

  def connect(_, %{transport: transport, timeout: timeout} = conn) do
    case transport.connect(conn) do
      {:ok, conn} ->
        {:ok, conn}
      {:error, _} ->
        {:backoff, timeout, conn}
    end
  end

  def disconnect(info, %{socket: socket, transport: transport} = conn) do
    transport.disconnect(info, socket)
    {:connect, :reconnect, reset_connection(conn)}
  end

  defp reset_connection(conn) do
    %{conn | features: %Features{}, parser: nil, socket: nil}
  end

  def handle_call(_, _, %{socket: nil} = conn) do
    {:reply, {:error, :closed}, conn}
  end
  def handle_call({:send, data}, _, %{transport: transport} = conn) do
    case transport.send(conn, data) do
      {:ok, conn} ->
        {:reply, :ok, conn}
      {:error, _} = error ->
        {:disconnect, error, error, conn}
    end
  end
  def handle_call(:close, from, conn) do
    {:disconnect, {:close, from}, conn}
  end

  def handle_info(info, %{owner: owner, transport: transport} = conn) do
    case transport.handle_message(info, conn) do
      {:ok, conn, stanza} ->
        Kernel.send(owner, {:stanza, stanza})
        {:noreply, conn}
      {:error, _} = error ->
        {:disconnect, error, conn}
      :unknown ->
        Logger.info fn ->
          [inspect(__MODULE__), ?\s, inspect(self), " received message: " | inspect(info)]
        end
        {:noreply, conn}
    end
  end
end
