defmodule Romeo.ConnectionTest do
  use ExUnit.Case
  use UserHelper
  use Romeo.XML
  import Romeo.XML

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

  test "connection TLS" do
    romeo = build_user("romeo", tls: true)

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
