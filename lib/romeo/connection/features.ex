defmodule Romeo.Connection.Features do
  @moduledoc """
  Parses XMPP Stream features.
  """

  use Romeo.XML

  @type t :: %__MODULE__{}
  defstruct [
    amp?: false,
    compression?: false,
    registration?: false,
    stream_management?: false,
    tls?: false,
    mechanisms: []
  ]

  def parse_stream_features(features) do
    %__MODULE__{
      amp?: supports?(features, "amp"),
      compression?: supports?(features, "compression"),
      registration?: supports?(features, "register"),
      stream_management?: supports?(features, "sm"),
      tls?: supports?(features, "starttls"),
      mechanisms: supported_auth_mechanisms(features)
    }
  end

  def supported_auth_mechanisms(features) do
    case Romeo.XML.subelement(features, "mechanisms") do
      xml when Record.is_record(xml, :xmlel) ->
        mechanisms = xmlel(xml, :children)
        for mechanism <- mechanisms, into: [], do: Romeo.XML.cdata(mechanism)
      nil -> []
    end
  end

  def supports?(features, "compression") do
    case Romeo.XML.subelement(features, "compression") do
      xml when Record.is_record(xml, :xmlel) ->
        methods = xmlel(xml, :children)
        for method <- methods, into: [], do: Romeo.XML.cdata(method)
      _ -> false
    end
  end
  def supports?(features, feature) do
    case Romeo.XML.subelement(features, feature) do
      nil -> false
      _   -> true
    end
  end
end
