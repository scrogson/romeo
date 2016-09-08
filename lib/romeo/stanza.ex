defmodule Romeo.Stanza do
  @moduledoc """
  Provides convenience functions for building XMPP stanzas.
  """

  use Romeo.XML

  @doc """
  Converts an `xml` record to an XML binary string.
  """
  def to_xml(record) when Record.is_record(record) do
    Romeo.XML.encode!(record)
  end
  def to_xml(record) when Record.is_record(record) do
    Romeo.XML.encode!(record)
  end

  def to_xml(%IQ{} = stanza) do
    xmlel(name: "iq",
      attrs: [
        {"to", to_string(stanza.to)},
        {"type", stanza.type},
        {"id", stanza.id}
      ]
    ) |> to_xml
  end

  def to_xml(%Presence{} = stanza) do
    xmlel(name: "presence",
      attrs: [
        {"to", to_string(stanza.to)},
        {"type", stanza.type}
      ]
    ) |> to_xml
  end

  def to_xml(%Message{to: to, type: type, body: body}) do
    message(to_string(to), type, body) |> to_xml
  end

  @doc """
  Starts an XML stream.

  ## Example

      iex> stanza = Romeo.Stanza.start_stream("im.capulet.lit")
      {:xmlstreamstart, "stream:stream",
       [{"to", "im.capulet.lit"}, {"version", "1.0"}, {"xml:lang", "en"},
         {"xmlns", "jabber:client"},
         {"xmlns:stream", "http://etherx.jabber.org/streams"}]}
      iex> Romeo.Stanza.to_xml(stanza)
      "<stream:stream to='im.capulet.lit' version='1.0' xml:lang='en' xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
  """
  def start_stream(server, xmlns \\ ns_jabber_client) do
    xmlstreamstart(name: "stream:stream",
      attrs: [
        {"to", server},
        {"version", "1.0"},
        {"xml:lang", "en"},
        {"xmlns", xmlns},
        {"xmlns:stream", ns_xmpp}
      ])
  end

  @doc """
  Ends the XML stream

  ## Example
      iex> stanza = Romeo.Stanza.end_stream
      {:xmlstreamend, "stream:stream"}
      iex> Romeo.Stanza.to_xml(stanza)
      "</stream:stream>"
  """
  def end_stream, do: xmlstreamend(name: "stream:stream")

  @doc """
  Generates the XML to start TLS.

  ## Example
      iex> stanza = Romeo.Stanza.start_tls
      {:xmlel, "starttls", [{"xmlns", "urn:ietf:params:xml:ns:xmpp-tls"}], []}
      iex> Romeo.Stanza.to_xml(stanza)
      "<starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls'/>"
  """
  def start_tls do
    xmlel(name: "starttls",
      attrs: [
        {"xmlns", ns_tls}
      ])
  end

  def compress(method) do
    xmlel(name: "compress",
      attrs: [
        {"xmlns", ns_compress}
      ],
      children: [
        xmlel(name: "method", children: [cdata(method)])
      ])
  end

  def handshake(hash) do
    cdata = xmlcdata(content: hash)
    xmlel(name: "handshake", children: [cdata])
  end
  
  def auth(mechanism), do: auth(mechanism, [])
  def auth(mechanism, body) do
    xmlel(name: "auth",
      attrs: [
        {"xmlns", ns_sasl},
        {"mechanism", mechanism}
      ],
      children: [body])
  end

  def bind(resource) do
    body = xmlel(name: "bind",
      attrs: [{"xmlns", ns_bind}],
      children: [
        xmlel(name: "resource",
          children: [cdata(resource)])
      ])
    iq("set", body)
  end

  def session do
    iq("set", xmlel(name: "session", attrs: [{"xmlns", ns_session}]))
  end

  def presence do
    xmlel(name: "presence")
  end

  def presence(type) do
    xmlel(name: "presence", attrs: [{"type", type}])
  end

  @doc """
  Returns a presence stanza to a given jid, of a given type.
  """
  def presence(to, type) do
    xmlel(name: "presence", attrs: [{"type", type}, {"to", to}])
  end

  def iq(type, body) do
    xmlel(name: "iq", attrs: [{"type", type}, {"id", id}], children: [body])
  end

  def iq(to, type, body) do
    iq = iq(type, body)
    xmlel(iq, attrs: [{"to", to}|xmlel(iq, :attrs)])
  end

  def get_roster do
    iq("get", xmlel(name: "query", attrs: [{"xmlns", ns_roster}]))
  end

  def set_roster_item(jid, subscription \\ "both", name \\ "", group \\ "") do
    name_to_set = case name do
      "" -> Romeo.JID.parse(jid).user
      _ -> name
    end
    group_xmlel = case group do
      "" -> []
      _ -> [xmlel(name: "group", children: [cdata(group)])]
    end
    iq("set", xmlel(
      name: "query",
      attrs: [{"xmlns", ns_roster}],
      children: [
        xmlel(name: "item", attrs: [
          {"jid", jid},
          {"subscription", subscription},
          {"name", name_to_set}
        ], children: group_xmlel)
      ]
    ))
  end

  def get_inband_register do
    iq("get", xmlel(name: "query", attrs: [{"xmlns", ns_inband_register}]))
  end

  def set_inband_register(username, password) do
    iq("set", xmlel(
      name: "query",
      attrs: [{"xmlns", ns_inband_register}],
      children: [
        xmlel(name: "username", children: [cdata(username)]),
        xmlel(name: "password", children: [cdata(password)])
      ]
    ))
  end

  def get_vcard(to) do
    iq(to, "get", xmlel(name: "vCard", attrs: [{"xmlns", ns_vcard}]))
  end

  def disco_info(to) do
    iq(to, "get", xmlel(name: "query", attrs: [{"xmlns", ns_disco_info}]))
  end

  def disco_items(to) do
    iq(to, "get", xmlel(name: "query", attrs: [{"xmlns", ns_disco_items}]))
  end

  @doc """
  Generates a stanza to join a pubsub node. (XEP-0060)
  """
  def subscribe(to, node, jid) do
    iq(to, "set", xmlel(
      name: "pubsub",
      attrs: [{"xmlns", ns_pubsub}],
      children: [
        xmlel(name: "subscribe", attrs: [{"node", node}, {"jid", jid}])
      ]))
  end

  @doc """
  Generates a presence stanza to join a MUC room.

  ## Options

  * `password` - the password for a MUC room - if required.
  * `history` - used for specifying the amount of old messages to receive once
    joined. The value of the `:history` option should be a keyword list of one
    of the following:
      * `maxchars` - limit the total number of characters in the history.
      * `maxstanzas` - limit the total number of messages in the history.
      * `seconds` - send only the messages received in the last `n` seconds.
      * `since` - send only the messages received since the UTC datetime specified.
    See http://xmpp.org/extensions/xep-0045.html#enter-managehistory
    for details.

  ## Examples
      iex> Romeo.Stanza.join("lobby@muc.localhost", "hedwigbot")
      {:xmlel, "presence", [{"to", "lobby@muc.localhost/hedwigbot"}],
       [{:xmlel, "x", [{"xmlns", "http://jabber.org/protocol/muc"}],
       [{:xmlel, "history", [{"maxstanzas", "0"}], []}]}]}
  """
  def join(room, nickname, opts \\ []) do
    history  = Keyword.get(opts, :history)
    password = Keyword.get(opts, :password)

    password = if password, do: [muc_password(password)], else: []
    history = if history, do: [history(history)], else: [history(maxstanzas: 0)]

    children = history ++ password

    xmlel(name: "presence",
      attrs: [
        {"to", "#{room}/#{nickname}"}
      ],
      children: [
        xmlel(name: "x",
          attrs: [{"xmlns", ns_muc}],
          children: children)
      ])
  end

  defp history([{key, value}]) do
    xmlel(name: "history", attrs: [{to_string(key), to_string(value)}])
  end

  defp muc_password(password) do
    xmlel(name: "password", children: [xmlcdata(content: password)])
  end

  def chat(to, body), do: message(to, "chat", body)
  def normal(to, body), do: message(to, "normal", body)
  def groupchat(to, body), do: message(to, "groupchat", body)

  def message(msg) when is_map(msg) do
    message(msg["to"], msg["type"], msg["body"])
  end
  def message(to, type, message) do
    xmlel(name: "message",
      attrs: [
        {"to", to},
        {"type", type},
        {"id", id},
        {"xml:lang", "en"}
      ],
      children: generate_body(message))
  end

  def generate_body(data) do
    cond do
      is_list(data) ->
        data
      is_tuple(data) ->
        [data]
      true ->
        [body(data)]
    end
  end

  def body(data) do
    xmlel(name: "body",
      children: [
        cdata(data)
      ])
  end

  def xhtml_im(data) when is_binary(data) do
    data
    |> :fxml_stream.parse_element
    |> xhtml_im
  end
  def xhtml_im(data) do
    xmlel(name: "html",
      attrs: [
        {"xmlns", ns_xhtml_im}
      ],
      children: [
        xmlel(name: "body",
          attrs: [
            {"xmlns", ns_xhtml}
          ],
          children: [
            data
          ])
      ])
  end

  def cdata(payload) do
    xmlcdata(content: payload)
  end

  def base64_cdata(payload) do
    xmlcdata(content: Base.encode64(payload))
  end

  @doc """
  Generates a random hex string for use as an id for a stanza.
  """
  def id do
    :crypto.rand_bytes(2) |> Base.encode16(case: :lower)
  end
end
