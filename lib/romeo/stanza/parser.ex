defmodule Romeo.Stanza.Parser do
  @moduledoc """
  Parses XML records into related structs.
  """
  use Romeo.XML
  import Romeo.XML

  alias Romeo.Roster.Item

  def parse(xmlel(name: "message", attrs: attrs) = stanza) do
    struct(Message, parse_attrs(attrs))
    |> struct([body: get_body(stanza)])
    |> struct([html: get_html(stanza)])
    |> struct([xml: stanza])
    |> struct([delayed?: delayed?(stanza)])
  end

  def parse(xmlel(name: "presence", attrs: attrs) = stanza) do
    struct(Presence, parse_attrs(attrs))
    |> struct([show: get_show(stanza)])
    |> struct([status: get_status(stanza)])
    |> struct([xml: stanza])
  end

  def parse(xmlel(name: "iq", attrs: attrs) = stanza) do
    case :fxml.get_path_s(stanza, [{:elem, "query"}, {:attr, "xmlns"}]) do
      "jabber:iq:roster" ->
        struct(IQ, parse_attrs(attrs))
        |> struct([items: (Romeo.XML.subelement(stanza, "query") |> parse)])
        |> struct([xml: stanza])
      _ -> struct(IQ, parse_attrs(attrs)) |> struct([xml: stanza])
    end
  end

  def parse(xmlel(name: "query") = stanza) do
    stanza |> Romeo.XML.subelements("item") |> Enum.map(&parse/1) |> Enum.reverse
  end

  def parse(xmlel(name: "item", attrs: attrs) = stanza) do
    struct(Item, parse_attrs(attrs))
    |> struct([group: get_group(stanza)])
    |> struct([xml: stanza])
  end

  def parse(xmlel(name: name, attrs: attrs) = stanza) do
    [name: name]
    |> Keyword.merge(parse_attrs(attrs))
    |> Keyword.merge([xml: stanza])
    |> Enum.into(%{})
  end

  def parse(xmlcdata(content: content)), do: content

  def parse(stanza), do: stanza

  defp parse_attrs([]), do: []
  defp parse_attrs(attrs) do
    parse_attrs(attrs, [])
  end
  defp parse_attrs([{k,v}|rest], acc) do
    parse_attrs(rest, [parse_attr({k,v})|acc])
  end
  defp parse_attrs([], acc), do: acc

  defp parse_attr({key, value}) when key in ["to", "from", "jid"] do
    {String.to_atom(key), Romeo.JID.parse(value)}
  end
  defp parse_attr({key, value}) do
    {String.to_atom(key), value}
  end

  defp get_body(stanza), do: subelement(stanza, "body") |> cdata
  defp get_html(stanza), do: subelement(stanza, "html")

  defp get_show(stanza), do: subelement(stanza, "show") |> cdata
  defp get_status(stanza), do: subelement(stanza, "status") |> cdata

  defp get_group(stanza), do: subelement(stanza, "group") |> cdata

  defp delayed?(xmlel(children: children)) do
    Enum.any? children, fn child ->
      elem(child, 1) == "delay" || elem(child, 1) == "x" &&
        attr(child, "xmlns") == "jabber:x:delay"
    end
  end
end
