defmodule Romeo.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [app: :romeo,
     name: "Romeo",
     version: @version,
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description,
     deps: deps,
     docs: docs,
     package: package,
     test_coverage: [tool: ExCoveralls]]
  end

  def application do
    [applications: [:logger, :connection, :exml],
     mod: {Romeo, []}]
  end

  defp description do
    "An XMPP Client for Elixir"
  end

  defp deps do
    [{:connection, "~> 1.0"},
     {:exml, github: "esl/exml"},

     # Docs deps
     {:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.10", only: :dev},

     # Test deps
     {:ejabberd, github: "processone/ejabberd", tag: "15.10", only: :test},
     {:excoveralls, "~> 0.4.2", only: :test}]
  end

  defp docs do
    [extras: docs_extras,
     main: "extra-readme"]
  end

  defp docs_extras do
    ["README.md"]
  end

  defp package do
    [files: ["lib", "priv", "mix.exs", "README.md", "LICENSE"],
       maintainers: ["Sonny Scroggin"],
       licenses: ["MIT"],
       links: %{"GitHub" => "https://github.com/scrogson/romeo"}]
  end
end
