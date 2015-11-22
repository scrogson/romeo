defmodule UserHelper do

  defmacro __using__(_) do
    quote do
      import UserHelper
      import ExUnit.CaptureIO
    end
  end

  def register_user(username, host \\ "localhost", password \\ "password") do
    user = build_user(username, host, password)
    :ejabberd_admin.register(username, host, password)
    user
  end

  def unregister_user(username, host \\ "localhost") do
    :ejabberd_admin.unregister(username, host)
  end

  defp build_user(username, host, password) do
    [jid: username <> "@" <> host,
     password: password,
     nickname: username,
     port: 5223]
  end
end
