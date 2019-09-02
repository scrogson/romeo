defmodule Romeo.RosterTest do
  use ExUnit.Case

  use UserHelper
  use Romeo.XML

  alias Romeo.Roster
  alias Romeo.Roster.Item

  setup do
    romeo = build_user("romeo", tls: true)
    juliet = build_user("juliet", resource: "juliet", tls: true)
    mercutio = build_user("mercutio", resource: "mercutio", tls: true)
    benvolio = build_user("benvolio", resource: "benvolio", tls: true)

    setup_presence_subscriptions(romeo[:nickname], juliet[:nickname])
    setup_presence_subscriptions(romeo[:nickname], mercutio[:nickname])

    {:ok, pid} = Romeo.Connection.start_link(romeo)
    {:ok, romeo: romeo, juliet: juliet, mercutio: mercutio, benvolio: benvolio, pid: pid}
  end

  test "getting, adding, removing roster items", %{
    benvolio: benvolio,
    mercutio: mercutio,
    pid: pid
  } do
    items = Roster.items(pid)
    assert item_by_name(items, "juliet")
    assert item_by_name(items, "mercutio")

    assert :ok = Roster.add(pid, benvolio[:jid])
    items = Roster.items(pid)
    assert item_by_name(items, "juliet")
    assert item_by_name(items, "mercutio")
    assert item_by_name(items, "benvolio")

    assert :ok = Roster.remove(pid, mercutio[:jid])
    items = Roster.items(pid)
    assert item_by_name(items, "juliet")
    assert item_by_name(items, "benvolio")
    refute item_by_name(items, "mercutio")
  end

  defp item_by_name(items, name) do
    Enum.find(items, fn item -> item.name == name end)
  end
end
