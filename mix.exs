defmodule Libwbxml.MixProject do
  use Mix.Project

  def project do
    [
      app: :libwbxml,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: ["lib"],
      start_permanent: Mix.env() == :prod,
      compilers: compilers(),
      # Path to the directory containing CMakeLists.txt
      # elixir_cmake will look for CMakeLists.txt in this directory
      cmake_lists: Path.join(__DIR__, "native"),
      # Environment passed to the CMake invocation
      cmake_env: cmake_env(),
      package: package(),
      deps: deps()
    ]
  end

  defp deps do
    [
      {:elixir_cmake, "~> 0.8.0"}
    ]
  end

  defp compilers do
    if skip?() do
      Mix.compilers()
    else
      [:cmake] ++ Mix.compilers()
    end
  end

  # Additional environment variables passed to the CMake process. We set these
  # here because the elixir_cmake compiler passes only the build directory and
  # relies on env vars for customisation.
  defp cmake_env do
    %{
      # Flag toggling whether we build libwbxml ourselves
      "SKIP_WBXML" => if(skip?(), do: "1", else: "0")
    }
  end

  defp package do
    [
      files: [
        "lib",
        "native",
        "mix.exs"
      ],
      maintainers: ["Carson Call"],
      licenses: ["MIT"]
    ]
  end

  defp skip? do
    # Check if user explicitly disabled native build
    if Application.get_env(:libwbxml, :skip_native_build, false) do
      true
    else
      # Check if build artifacts already exist
      artifacts_exist?()
    end
  end

  # Check if the compiled NIF file already exists
  defp artifacts_exist? do
    # Check for the NIF file in the most common locations
    # This needs to work during early project configuration before app_path is available
    possible_nif_paths = [
      # When building from main project (correct path)
      "../../_build/#{Mix.env()}/lib/libwbxml/priv/#{nif_filename()}",
      # Alternative dev environment path
      # When building standalone
      "_build/#{Mix.env()}/lib/libwbxml/priv/#{nif_filename()}",
      # Alternative paths
      "priv/#{nif_filename()}"
    ]

    Enum.any?(possible_nif_paths, fn path ->
      File.exists?(Path.expand(path))
    end)
  end

  # Platform-specific NIF filename
  defp nif_filename do
    case :os.type() do
      # On macOS, it's still .so for NIFs
      {:unix, :darwin} -> "wbxml_nif.so"
      {:unix, _} -> "wbxml_nif.so"
      {:win32, _} -> "wbxml_nif.dll"
    end
  end
end
