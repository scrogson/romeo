defmodule Romeo.Stanza.IQ do
  use Romeo.XML

  @type jid :: Romeo.JID.t

  @type t :: %__MODULE__{
    id: binary,
    to: jid,
    from: jid,
    type: binary,
    payload: list,
    client: pid,
    matches: nil
  }

  defstruct [
    id:       nil,
    to:       nil,
    from:     nil,
    type:     nil,
    payload: [],
    client:   nil,
    matches:  nil
  ]
end
