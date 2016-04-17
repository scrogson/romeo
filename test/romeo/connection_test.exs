defmodule Romeo.ConnectionTest do
  use ExUnit.Case

  use UserHelper
  use Romeo.XML

  setup do
    romeo  = build_user("romeo", tls: true)
    juliet = build_user("juliet", resource: "juliet", tls: true)

    setup_presence_subscriptions(romeo[:nickname], juliet[:nickname])

    {:ok, romeo: romeo, juliet: juliet}
  end

  test "connection no TLS" do
    romeo = build_user("romeo")

    {:ok, _pid} = Romeo.Connection.start_link(romeo)

    assert_receive {:resource_bound, _}
    assert_receive :connection_ready
  end

  test "connection TLS", %{romeo: romeo} do
    {:ok, _pid} = Romeo.Connection.start_link(romeo)

    assert_receive {:resource_bound, _}
    assert_receive :connection_ready
  end

  test "sending presence", %{romeo: romeo} do
    {:ok, pid} = Romeo.Connection.start_link(romeo)

    assert_receive :connection_ready

    assert :ok = Romeo.Connection.send(pid, Romeo.Stanza.presence)
    assert_receive {:stanza, %Presence{from: from, to: to} = presence}
    assert to_string(from) == "romeo@localhost/romeo"
    assert to_string(to) == "romeo@localhost/romeo"

    assert :ok = Romeo.Connection.send(pid, Romeo.Stanza.join("lobby@conference.localhost", "romeo"))
    assert_receive {:stanza, %Presence{from: from} = presence}
    assert to_string(from) == "lobby@conference.localhost/romeo"
  end

  test "resource conflict", %{romeo: romeo} do
    {:ok, pid1} = Romeo.Connection.start_link(romeo)
    assert_receive :connection_ready
    assert :ok = Romeo.Connection.send(pid1, Romeo.Stanza.presence)

    {:ok, pid2} = Romeo.Connection.start_link(romeo)
    assert_receive :connection_ready
    assert :ok = Romeo.Connection.send(pid2, Romeo.Stanza.presence)

    assert_receive {:stanza, %{name: "stream:error"}}
    assert_receive {:stanza, xmlstreamend()}
  end

  test "exchanging messages with others", %{romeo: romeo, juliet: juliet} do
    {:ok, romeo} = Romeo.Connection.start_link(romeo)
    assert_receive :connection_ready
    assert :ok = Romeo.Connection.send(romeo, Romeo.Stanza.presence)
    # Romeo receives presense from himself
    assert_receive {:stanza, %Presence{}}

    {:ok, juliet} = Romeo.Connection.start_link(juliet)
    assert_receive :connection_ready
    assert :ok = Romeo.Connection.send(juliet, Romeo.Stanza.presence)

    # Juliet receives presence from herself and each receive each others'
    assert_receive {:stanza, %Presence{}}
    assert_receive {:stanza, %Presence{}}
    assert_receive {:stanza, %Presence{}}

    # Juliet sends Romeo a message
    assert :ok = Romeo.Connection.send(juliet, Romeo.Stanza.chat("romeo@localhost/romeo", "Where art thou?"))
    assert_receive {:stanza, %Message{from: from, to: to, body: body}}
    assert to_string(from) == "juliet@localhost/juliet"
    assert to_string(to) == "romeo@localhost/romeo"
    assert body == "Where art thou?"

    # Romeo responds
    assert :ok = Romeo.Connection.send(romeo, Romeo.Stanza.chat("juliet@localhost/juliet", "Hey babe"))
    assert_receive {:stanza, %Message{from: from, to: to, body: body}}
    assert to_string(from) == "romeo@localhost/romeo"
    assert to_string(to) == "juliet@localhost/juliet"
    assert body == "Hey babe"
  end
end
