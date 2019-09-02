defmodule Romeo.XMLTest do
  use ExUnit.Case, async: true

  use Romeo.XML
  import Romeo.XML

  test "encode!" do
    xml =
      xmlel(
        name: "message",
        children: [
          xmlel(
            name: "body",
            children: [
              xmlcdata(content: "testing")
            ]
          )
        ]
      )

    assert encode!(xml) ==
             ~s(<message><body>testing</body></message>)
  end

  test "attr" do
    xml = xmlel(name: "message", attrs: [{"type", "chat"}])
    assert attr(xml, "type") == "chat"
    assert attr(xml, "non-existent") == nil
    assert attr(xml, "non-existent", "default") == "default"
  end

  test "subelement" do
    xml =
      xmlel(
        name: "message",
        children: [
          xmlel(
            name: "body",
            children: [
              xmlcdata(content: "testing")
            ]
          )
        ]
      )

    assert subelement(xml, "body") ==
             {:xmlel, "body", [], [xmlcdata(content: "testing")]}

    assert subelement(xml, "non-existent") == nil
    assert subelement(xml, "non-existent", []) == []
  end

  test "cdata" do
    body =
      xmlel(
        name: "body",
        children: [
          xmlcdata(content: "testing")
        ]
      )

    assert cdata(body) == "testing"
  end

  test "empty cdata" do
    body =
      xmlel(
        name: "body",
        children: [
          xmlcdata(content: "testing")
        ]
      )

    assert cdata(body) == "testing"
  end
end
