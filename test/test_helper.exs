IO.puts "Starting ejabberd..."
Application.ensure_all_started(:ejabberd)
ExUnit.start
