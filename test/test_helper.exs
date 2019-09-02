Logger.configure(level: :info)
Code.require_file("user_helper.exs", __DIR__)
ExUnit.configure(assert_receive_timeout: 2000)
ExUnit.start()
