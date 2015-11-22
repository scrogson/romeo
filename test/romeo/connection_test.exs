defmodule Romeo.ConnectionTest do
  use ExUnit.Case
  use UserHelper
  use Romeo.XML
  import Romeo.XML

  setup do
    romeo = register_user("romeo")
    juliet = register_user("juliet")
    Application.put_env(:ex_unit, :assert_receive_timeout, 500)
    {:ok, romeo: romeo, juliet: juliet}
  end

  test "connection no TLS", %{romeo: romeo} do
    {:ok, pid} = Romeo.Connection.start_link(romeo)

    assert_receive {:stanza_received, {:xmlstreamstart, "stream:stream", _}}
    assert_receive {:stanza_received, {:xmlel, "stream:features", _, _}}
    assert_receive {:stanza_received, {:xmlel, "success", _, _}}
    assert_receive {:stanza_received, {:xmlstreamstart, "stream:stream", _}}
    assert_receive {:stanza_received, {:xmlel, "stream:features", _, _}}
    assert_receive {:resource_bound, _}, 500
    assert_receive :connection_ready
  end
end
