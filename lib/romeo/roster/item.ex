defmodule Romeo.Roster.Item do
  @type jid :: Romeo.JID.t()

  @type t :: %__MODULE__{
          subscription: binary,
          name: binary,
          jid: jid,
          group: binary,
          xml: tuple
        }

  defstruct subscription: nil,
            name: nil,
            jid: nil,
            group: nil,
            xml: nil
end
