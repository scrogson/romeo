defmodule Romeo.ConnectionTest do
  use ExUnit.Case
  use UserHelper
  use Romeo.XML
  import Romeo.XML

  setup do
    romeo  = build_user("romeo", tls: true)
    juliet = build_user("juliet", resource: "juliet", tls: true)

    setup_presence_subscriptions(romeo[:nickname], juliet[:nickname])

    {:ok, romeo: romeo, juliet: juliet}
  end

  test "connection no TLS" do
    romeo = build_user("romeo")

    {:ok, pid} = Romeo.Connection.start_link(romeo)

    assert_receive {:stanza_received, xmlstreamstart()}
    assert_receive {:stanza_received, xmlel(name: "stream:features")}
    assert_receive {:stanza_received, xmlel(name: "success")}
    assert_receive {:stanza_received, xmlstreamstart()}
    assert_receive {:stanza_received, xmlel(name: "stream:features")}
    assert_receive {:resource_bound, _}
    assert_receive :connection_ready
  end

  test "connection TLS", %{romeo: romeo} do
    {:ok, pid} = Romeo.Connection.start_link(romeo)

    assert_receive {:stanza_received, xmlstreamstart()}
    assert_receive {:stanza_received, xmlel(name: "stream:features")}
    assert_receive {:stanza_received, xmlel(name: "proceed")}
    assert_receive {:stanza_received, xmlstreamstart()}
    assert_receive {:stanza_received, xmlel(name: "stream:features")}
    assert_receive {:stanza_received, xmlel(name: "success")}
    assert_receive {:stanza_received, xmlstreamstart()}
    assert_receive {:stanza_received, xmlel(name: "stream:features")}
    assert_receive {:resource_bound, _}
    assert_receive :connection_ready
  end

  test "sending presence", %{romeo: romeo} do
    {:ok, pid} = Romeo.Connection.start_link(romeo)

    assert_receive :connection_ready

    assert :ok = Romeo.Connection.send(pid, Romeo.Stanza.presence)
    assert_receive {:stanza_received, xmlel(name: "presence") = presence}
    assert attr(presence, "from") == "romeo@localhost/romeo"
    assert attr(presence, "to") == "romeo@localhost/romeo"

    assert :ok = Romeo.Connection.send(pid, Romeo.Stanza.join("lobby@conference.localhost", "romeo"))
    assert_receive {:stanza_received, xmlel(name: "presence") = presence}
    assert attr(presence, "from") == "lobby@conference.localhost/romeo"
  end

  test "resource conflict", %{romeo: romeo} do
    {:ok, pid1} = Romeo.Connection.start_link(romeo)
    assert_receive :connection_ready
    assert :ok = Romeo.Connection.send(pid1, Romeo.Stanza.presence)

    {:ok, pid2} = Romeo.Connection.start_link(romeo)
    assert_receive :connection_ready
    assert :ok = Romeo.Connection.send(pid2, Romeo.Stanza.presence)

    assert_receive {:stanza_received, xmlel(name: "stream:error") = error}
  end
end
