# Changelog

## v0.2.0

- Enhancements
  - [Romeo.JID] Added `user/1` which returns the `user` portion of the JID.
  - [Romeo.JID] Added `server/1` which returns the `server` portion of the JID.
  - [Romeo.JID] Added `resource/1` which returns the `resource` portion of the JID.
  - [Romeo.JID] Added key `full` JID struct for convenient access to the full
    JID.
  - [Romeo.Stanza] Added a clause to `to_xml/1` for `%Romeo.Stanza.Message{}`.
  - [Romeo.XML] Added a clause to `encode!/1` to handle all stanza structs.

- Backward incompatible changes
  - [Romeo.Connection] No longer sends stanza messages to the owner process
    until after the connection process has finished.
  - [Romeo.Connection] Stanzas sent to the owner process are now parsed into the
    matching stanza struct. The message tuple has changed from
    `{:stanza_received, stanza}` to `{:stanza, stanza}`.

## v0.1.0

Initial release :tada:
