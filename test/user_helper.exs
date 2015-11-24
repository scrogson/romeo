defmodule UserHelper do

  defmacro __using__(_) do
    quote do
      import UserHelper
      import ExUnit.CaptureLog
    end
  end

  def build_user(username, opts \\ []) do
    {password, opts} = Keyword.pop(opts, :password, "password")
    {resource, opts} = Keyword.pop(opts, :resource, "romeo")
    {tls, _opts} = Keyword.pop(opts, :tls, false)

    register_user(username, password)

    [jid: username <> "@localhost",
     password: password,
     resource: resource,
     nickname: username,
     port: (if tls, do: 52225, else: 52222)]
  end

  def register_user(username, password \\ "password") do
    :ejabberd_admin.register(username, "localhost", password)
  end

  def unregister_user(username) do
    :ejabberd_admin.unregister(username, "localhost")
  end

  def setup_presence_subscriptions(user1, user2) do
    :mod_admin_extra.add_rosteritem(user1, "localhost", user2, "localhost", user2, "buddies", "both")
    :mod_admin_extra.add_rosteritem(user2, "localhost", user1, "localhost", user1, "buddies", "both")
  end
end
