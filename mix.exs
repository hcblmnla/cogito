defmodule Cogito.MixProject do
  use Mix.Project

  def project do
    [
      app: :cogito,
      version: "0.1.2",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Cogito",
      source_url: "https://github.com/hcblmnla/cogito"
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:ex_doc, "~> 0.14", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "A very simple parser combinator"
  end

  defp package() do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/hcblmnla/cogito"}
    ]
  end
end
