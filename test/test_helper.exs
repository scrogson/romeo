Code.require_file("user_helper.exs", __DIR__)

Application.ensure_all_started(:ejabberd)
ExUnit.start()

System.at_exit(fn _ -> File.rm_rf("mnesia") end)
