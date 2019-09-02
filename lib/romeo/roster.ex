defmodule Romeo.Roster do
  @moduledoc """
  Helper for work with roster
  """
  @timeout 5_000

  use Romeo.XML
  alias Romeo.Connection, as: Conn
  alias Romeo.Stanza
  require Logger

  @doc """
  Returns roster items
  """
  def items(pid) do
    Logger.info(fn -> "Getting roster items" end)
    stanza = Stanza.get_roster()

    case send_stanza(pid, stanza) do
      {:ok, %IQ{type: "result"} = result} -> result.items
      _ -> :error
    end
  end

  @doc """
  Adds jid to roster
  """
  def add(pid, jid) do
    Logger.info(fn -> "Adding #{jid} to roster items" end)
    stanza = Stanza.set_roster_item(jid)

    case send_stanza(pid, stanza) do
      {:ok, _} -> :ok
      _ -> :error
    end
  end

  def add(pid, jid, name) do
    Logger.info(fn -> "Adding #{jid} to roster items" end)
    stanza = Stanza.set_roster_item(jid, "both", name)

    case send_stanza(pid, stanza) do
      {:ok, _} -> :ok
      _ -> :error
    end
  end

  @doc """
  Removes jid to roster
  """
  def remove(pid, jid) do
    Logger.info(fn -> "Removing #{jid} from roster items" end)
    stanza = Stanza.set_roster_item(jid, "remove")

    case send_stanza(pid, stanza) do
      {:ok, _} -> :ok
      _ -> :error
    end
  end

  defp send_stanza(pid, stanza) do
    id = Romeo.XML.attr(stanza, "id")
    :ok = Conn.send(pid, stanza)

    receive do
      {:stanza, %IQ{type: "result", id: ^id} = result} -> {:ok, result}
      {:stanza, %IQ{type: "error", id: ^id}} -> :error
    after
      @timeout ->
        {:error, :timeout}
    end
  end
end
