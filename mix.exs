defmodule Libwbxml.MixProject do
  use Mix.Project

  def project do
    [
      app: :libwbxml,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: ["lib"],
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make] ++ Mix.compilers(),
      make_clean: ["clean"],
      package: package(),
      deps: deps()
    ]
  end

  defp deps do
    [
      {:elixir_make, "~> 0.9.0", runtime: false}
    ]
  end

  defp package do
    [
      files: [
        "lib",
        "vendor",
        "native",
        "Makefile",
        "mix.exs"
      ],
      maintainers: ["Carson Call"],
      licenses: ["MIT"]
    ]
  end
end
