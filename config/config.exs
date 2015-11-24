use Mix.Config

config :logger, level: :debug

config :mnesia, dir: 'mnesia'

config :sasl, sasl_error_logger: false

config :ejabberd,
  file: "config/ejabberd.yml",
  log_path: "logs/ejabberd.log"
