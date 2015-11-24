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
    {tls, opts} = Keyword.pop(opts, :tls, false)

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
end
