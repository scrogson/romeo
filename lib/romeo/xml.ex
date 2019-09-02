defmodule Romeo.XML do
  @moduledoc """
  Provides functions for building XML stanzas with the `fast_xml` library.
  """

  require Record

  defmacro __using__(_opts) do
    quote do
      use Romeo.XMLNS
      require Record
      alias Romeo.Stanza
      alias Romeo.Stanza.IQ
      alias Romeo.Stanza.Message
      alias Romeo.Stanza.Presence

      Record.defrecordp(:xmlel, name: "", attrs: [], children: [])
      Record.defrecordp(:xmlcdata, content: [])
      Record.defrecordp(:xmlstreamstart, name: "", attrs: [])
      Record.defrecordp(:xmlstreamend, name: "")
    end
  end

  def encode!({:xmlel, _, _, _} = xml), do: :fxml.element_to_binary(xml)

  def encode!({:xmlstreamstart, name, attrs}),
    do: encode!({:xmlel, name, attrs, []}) |> String.replace("/>", ">")

  def encode!({:xmlstreamend, name}), do: "</#{name}>"

  def encode!(stanza), do: Romeo.Stanza.to_xml(stanza)

  @doc """
  Returns the given attribute value or default.
  """
  def attr(element, name, default \\ nil) do
    case :fxml.get_tag_attr_s(name, element) do
      "" -> default
      val -> val
    end
  end

  def subelement(element, name, default \\ nil) do
    case :fxml.get_subtag(element, name) do
      false -> default
      val -> val
    end
  end

  def subelements(element, name) do
    :fxml.get_subtags(element, name)
  end

  def cdata(nil), do: ""
  def cdata(element), do: :fxml.get_tag_cdata(element)
end
