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

  test "exchanging messages with others", %{romeo: romeo, juliet: juliet} do
    {:ok, romeo} = Romeo.Connection.start_link(romeo)
    assert_receive :connection_ready
    assert :ok = Romeo.Connection.send(romeo, Romeo.Stanza.presence)
    # Romeo receives presense from himself
    assert_receive {:stanza_received, xmlel(name: "presence")}

    {:ok, juliet} = Romeo.Connection.start_link(juliet)
    assert_receive :connection_ready
    assert :ok = Romeo.Connection.send(juliet, Romeo.Stanza.presence)

    # Juliet receives presence from herself and each receive each others'
    assert_receive {:stanza_received, xmlel(name: "presence")}
    assert_receive {:stanza_received, xmlel(name: "presence")}
    assert_receive {:stanza_received, xmlel(name: "presence")}

    # Juliet sends Romeo a message
    assert :ok = Romeo.Connection.send(juliet, Romeo.Stanza.chat("romeo@localhost/romeo", "Where art thou?"))
    assert_receive {:stanza_received, xmlel(name: "message") = message}
    assert attr(message, "from") == "juliet@localhost/juliet"
    assert attr(message, "to") == "romeo@localhost/romeo"
    assert subelement(message, "body") |> cdata == "Where art thou?"

    # Romeo responds
    assert :ok = Romeo.Connection.send(romeo, Romeo.Stanza.chat("juliet@localhost/juliet", "Hey babe"))
    assert_receive {:stanza_received, xmlel(name: "message") = message}
    assert attr(message, "from") == "romeo@localhost/romeo"
    assert attr(message, "to") == "juliet@localhost/juliet"
    assert subelement(message, "body") |> cdata == "Hey babe"
  end
end
