defmodule Romeo.XML do
  @moduledoc """
  Provides functions for building XML stanzas with the `exml` library.
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

      Record.defrecordp :xmlel, name: "", attrs: [], children: []
      Record.defrecordp :xmlcdata, content: []
      Record.defrecordp :xmlstreamstart, name: "", attrs: []
      Record.defrecordp :xmlstreamend, name: ""
    end
  end

  def encode!(record) when Record.is_record(record) do
    :exml.to_binary(record)
  end
  def encode!(stanza) do
    Romeo.Stanza.to_xml(stanza)
  end

  @doc """
  Returns the given attribute value or default.
  """
  def attr(element, name, default \\ nil) do
    :exml_query.attr(element, name, default)
  end

  def subelement(element, name, default \\ nil) do
    :exml_query.subelement(element, name, default)
  end

  def cdata(nil), do: ""
  def cdata(element), do: :exml_query.cdata(element)
end
