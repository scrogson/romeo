defmodule Romeo.RosterTest do
  use ExUnit.Case

  use UserHelper
  use Romeo.XML

  import Romeo.Roster

  alias Romeo.Roster.Item

  setup do
    romeo  = build_user("romeo", tls: true)
    juliet = build_user("juliet", resource: "juliet", tls: true)
    mercutio = build_user("mercutio", resource: "mercutio", tls: true)
    benvolio = build_user("benvolio", resource: "benvolio", tls: true)

    setup_presence_subscriptions(romeo[:nickname], juliet[:nickname])
    setup_presence_subscriptions(romeo[:nickname], mercutio[:nickname])

    {:ok, pid} = Romeo.Connection.start_link(romeo)
    {:ok, romeo: romeo, juliet: juliet, mercutio: mercutio, benvolio: benvolio, pid: pid}
  end

  test "getting, adding, removing roster items", %{benvolio: benvolio, mercutio: mercutio, pid: pid} do
    assert [%Item{name: "juliet"}, %Item{name: "mercutio"}] = items(pid)

    b_jid = benvolio[:jid]
    assert :ok = add(pid, b_jid)
    assert [%Item{name: "juliet"}, %Item{name: "mercutio"}, %Item{name: "benvolio"}] = items(pid)

    m_jid = mercutio[:jid]
    assert :ok = remove(pid, m_jid)
    assert [%Item{name: "juliet"}, %Item{name: "benvolio"}] = items(pid)
  end
end
