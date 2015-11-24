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
end
