defmodule ExtractousEx.MixProject do
  use Mix.Project

  @version "0.1.1"
  @dev? Mix.env() in [:dev, :test]
  @force_build? System.get_env("FORCE_BUILD") in ["1", "true"]

  def project do
    [
      app: :extractous_ex,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),

      # Docs
      name: "ExtractousEx",
      source_url: "https://github.com/Valian/extractous_ex",
      homepage_url: "https://github.com/Valian/extractous_ex",
      docs: &docs/0
    ]
  end

  defp description do
    "Elixir library for extracting text and metadata from various document formats using the Extractous Rust library"
  end

  defp package do
    [
      files: ~w(lib priv native .github mix.exs README.md LICENSE checksum-*.exs),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/Valian/extractous_ex"},
      maintainers: ["Jakub Skałecki"]
    ]
  end

  def docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:rustler, "~> 0.37", optional: not (@dev? or @force_build?)},
      {:rustler_precompiled, "~> 0.7"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false, warn_if_outdated: true}
    ]
  end
end
