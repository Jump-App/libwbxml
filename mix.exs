defmodule Libwbxml.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/Jump-App/libwbxml"

  def project do
    [
      app: :libwbxml,
      version: @version,
      elixir: "~> 1.19",
      elixirc_paths: ["lib"],
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make] ++ Mix.compilers(),
      make_clean: ["clean"],
      make_force_build: System.get_env("LIBWBXML_FORCE_BUILD") == "true",
      make_precompiler: {:nif, CCPrecompiler},
      make_precompiler_filename: "wbxml_nif",
      make_precompiler_url: "#{@source_url}/releases/download/v#{@version}/@{artefact_filename}",
      package: package(),
      deps: deps()
    ]
  end

  defp deps do
    [
      {:elixir_make, "~> 0.9.0", runtime: false},
      {:cc_precompiler, "~> 0.1", runtime: false}
    ]
  end

  defp package do
    [
      files: [
        "lib",
        "native",
        "vendor",
        "checksum.exs",
        "Makefile",
        "mix.exs",
        "README.md"
      ],
      maintainers: ["Jump AI"],
      licenses: ["MIT"]
    ]
  end
end
