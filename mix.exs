defmodule Romeo.Mixfile do
  use Mix.Project

  @version "0.6.0"

  def project do
    [app: :romeo,
     name: "Romeo",
     version: @version,
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     deps: deps(),
     docs: docs(),
     package: package(),
     test_coverage: [tool: ExCoveralls]]
  end

  def application do
    [applications: [:logger, :connection, :fast_xml],
     mod: {Romeo, []}]
  end

  defp description do
    "An XMPP Client for Elixir"
  end

  defp deps do
    [{:connection, "~> 1.0"},
     {:fast_xml, "~> 1.1"},

     # Docs deps
     {:earmark, "~> 0.2", only: :docs},
     {:ex_doc, "~> 0.11", only: :docs},

     # Test deps
     {:ejabberd, "~> 16.6.2", only: :test},
     {:excoveralls, "~> 0.5", only: :test}]
  end

  defp docs do
    [extras: docs_extras(),
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
