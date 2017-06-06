defmodule Exfmt.Mixfile do
  use Mix.Project

  @version "0.2.1"

  def project do
    [app: :exfmt,
     name: "exfmt",
     description: "An experimental Elixir source code style formatter",
     version: @version,
     elixir: "~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     docs: [extras: ["README.md"]],
     package: [maintainers: ["Louis Pilfold"],
               licenses: ["apache-2.0"],
               links: %{"GitHub" => "https://github.com/lpil/exfmt"},
               files: ~w(LICENCE README.md lib mix.exs)]]
  end


  def application do
    [extra_applications: []]
  end


  defp elixirc_paths(:test) do
    ["lib", "test/support"]
  end

  defp elixirc_paths(_) do
    ["lib"]
  end


  defp deps do
    [# Automatic test runner
     {:mix_test_watch, "~> 0.4", only: :dev, runtime: false},
     # Markdown processor
     {:earmark, "~> 1.2", only: :dev, runtime: false},
     # Documentation generator
     {:ex_doc, "~> 0.15", only: :dev, runtime: false}]
  end
end
