defmodule Mix.Tasks.Ejabberd.Gen.Config do
  use Mix.Task

  @shortdoc "Generates an ejabberd.yml file"

  @moduledoc """
  Generates an ejabberd.yml file.

      mix ejabberd.gen.config
  """

  def run([]) do
    cwd = File.cwd!
    source = Path.join(cwd, "priv/templates/ejabberd.yml.eex")
    target = Path.join(cwd, "config/ejabberd.yml")
    contents = EEx.eval_file(source, cwd: cwd)

    Mix.Generator.create_file(target, contents)
  end
end
