defmodule Romeo.Connection do
  @moduledoc false

  @timeout 5_000
  @default_transport Romeo.Transports.TCP

  defstruct features: %Romeo.Connection.Features{},
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

  alias Romeo.JID

  ### PUBLIC API ###

  @doc """
  Start the connection process and connect to postgres.

  ## Options

    * `:host` - Server hostname (default: inferred by the JID);
    * `:port` - Server port (default: `#{@default_port}`);
    * `:jid` - User jabber ID;
    * `:password` - User password;
    * `:timeout` - Connect timeout in milliseconds (default: `#{@timeout}`);
    * `:require_tls` - Set to `false` if ssl should not be used (default: `true`);
    * `:ssl_opts` - A list of ssl options, see ssl docs;
    * `:socket_opts` - Options to be given to the underlying socket;
  """
  def connect(opts) do
    opts =
      opts
      |> Keyword.put_new(:timeout, @timeout)
      |> Keyword.put_new(:transport, @default_transport)
      |> Keyword.put(:owner, self())

    Connection.start_link(__MODULE__, struct(__MODULE__, opts))
  end

  def connect(_, %{transport: transport, timeout: timeout} = conn) do
    case transport.connect(conn) do
      {:ok, conn} ->
        {:ok, conn}
      {:error, error} ->
        {:backoff, timeout, conn}
    end
  end

  @doc """
  Stop the process and disconnect.

  ## Options

    * `:timeout` - Call timeout (default: `#{@timeout}`)
  """
  @spec stop(pid, Keyword.t) :: :ok
  def stop(pid, opts \\ []) do
    Connection.call(pid, :stop, opts[:timeout] || @timeout)
  end

  @doc """
  Send a message via the underlying transport.
  """
  def send(pid, msg) do
    Connection.cast(pid, {:send, msg})
  end

  ## Connection callbacks

  def init(conn) do
    {:connect, :init, conn}
  end

  def handle_cast({:send, msg}, %{transport: transport} = conn) do
    transport.send(conn, msg)
    {:noreply, conn}
  end

  def handle_info(msg, %{owner: owner, transport: transport} = conn) do
    case transport.handle_message(msg, conn) do
      {:ok, conn, stanza} ->
        Kernel.send(owner, stanza)
        {:noreply, conn}
      {:error, reason} ->
        {:stop, reason, conn}
      :unknown ->
        Logger.info fn ->
          [inspect(__MODULE__), ?\s, inspect(self()), " received message: " | inspect(msg)]
        end
        {:noreply, conn}
    end
  end
end
