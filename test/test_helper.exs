Code.require_file("user_helper.exs", __DIR__)

IO.puts "Starting ejabberd..."
Application.ensure_all_started(:ejabberd)

ExUnit.start
