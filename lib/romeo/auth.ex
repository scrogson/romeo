defmodule Romeo.Auth do
  @moduledoc """
  Handles XMPP authentication mechanisms.
  """

  use Romeo.XML
  require Logger

  defmodule Mechanism do
    @doc "Authenticates using the supplied mechanism"
    @callback authenticate(String.t(), Romeo.Connection.t()) :: Romeo.Connection.t()
  end

  defmodule Error do
    defexception [:message]

    def exception(mechanism) do
      msg = "Failed to authenticate using mechanism: #{inspect(mechanism)}"
      %Romeo.Auth.Error{message: msg}
    end
  end

  @doc """
  Authenticates the client using the configured preferred mechanism.

  If the preferred mechanism is not supported it will choose PLAIN.
  """
  def authenticate!(conn) do
    preferred = conn.preferred_auth_mechanisms
    mechanisms = conn.features.mechanisms
    preferred_mechanism(preferred, mechanisms) |> do_authenticate(conn)
  end

  def handshake!(%{transport: mod, password: password, stream_id: stream_id} = conn) do
    stanza =
      :crypto.hash(:sha, "#{stream_id}#{password}")
      |> Base.encode16(case: :lower)
      |> Stanza.handshake()

    conn
    |> mod.send(stanza)
    |> mod.recv(fn
      conn, xmlel(name: "handshake") ->
        conn

      _conn, xmlel(name: "stream:error") ->
        raise Romeo.Auth.Error, "handshake error"
    end)
  end

  defp do_authenticate(mechanism, conn) do
    {:ok, conn} =
      case mechanism do
        {name, mod} ->
          Logger.info(fn -> "Authenticating with extension #{name} implemented by #{mod}" end)
          mod.authenticate(name, conn)

        _ ->
          Logger.info(fn -> "Authenticating with #{mechanism}" end)
          authenticate_with(mechanism, conn)
      end

    case success?(conn) do
      {:ok, conn} -> conn
      {:error, _conn} -> raise Romeo.Auth.Error, mechanism
    end
  end

  defp authenticate_with("PLAIN", %{transport: mod} = conn) do
    [username, password] = get_client_credentials(conn)
    payload = <<0>> <> username <> <<0>> <> password
    mod.send(conn, Romeo.Stanza.auth("PLAIN", Romeo.Stanza.base64_cdata(payload)))
  end

  defp authenticate_with("ANONYMOUS", %{transport: mod} = conn) do
    conn |> mod.send(Romeo.Stanza.auth("ANONYMOUS"))
  end

  defp authenticate_with(mechanism_name, _conn) do
    raise """
      Romeo does not include an implementation for authentication mechanism #{
      inspect(mechanism_name)
    }.
      Please provide an implementation such as

        Romeo.Connection.start_link(preferred_auth_mechanisms: [{#{inspect(mechanism_name)}, SomeModule}])

      where `SomeModule` implements the Romeo.Auth.Mechanism behaviour.
    """
  end

  defp success?(%{transport: mod} = conn) do
    mod.recv(conn, fn conn, xmlel(name: name) ->
      case name do
        "success" ->
          Logger.info(fn -> "Authenticated successfully" end)
          {:ok, conn}

        "failure" ->
          {:error, conn}
      end
    end)
  end

  defp get_client_credentials(%{jid: jid, password: password}) do
    [Romeo.JID.parse(jid).user, password]
  end

  defp preferred_mechanism([], _), do: "PLAIN"

  defp preferred_mechanism([mechanism | tail], mechanisms) do
    case acceptable_mechanism?(mechanism, mechanisms) do
      true -> mechanism
      false -> preferred_mechanism(tail, mechanisms)
    end
  end

  defp acceptable_mechanism?({name, _mod}, mechanisms),
    do: acceptable_mechanism?(name, mechanisms)

  defp acceptable_mechanism?(mechanism, mechanisms),
    do: Enum.member?(mechanisms, mechanism)
end
