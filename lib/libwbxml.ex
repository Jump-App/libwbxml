defmodule Libwbxml do
  @moduledoc """
  Thin Elixir wrapper around the native **libwbxml** implementation.  All
  heavy lifting happens in the `wbxml_nif` shared library which is compiled
  automatically by the [`elixir_cmake`](https://hex.pm/packages/elixir_cmake)
  compiler when the dependency is first built. At runtime we only need to
  locate that `.so`/`.dylib` and load it.

  When the NIF is built as part of the Mix compilation process it is placed
  inside the priv directory of the `:libwbxml` OTP application, so the default
  lookup via `:code.priv_dir/1` is sufficient.  An explicit path can still be
  injected at runtime by setting `config :libwbxml, :libwbxml_dir, "..."` - this
  is mainly useful for testing pre-compiled artefacts.
  """

  @on_load :load_nif

  # ---------------------------------------------------------------------------
  # NIF loading helpers
  # ---------------------------------------------------------------------------

  # Returns the directory that holds `wbxml_nif.so`.  Preference order:
  # 1. Explicit path persisted by the compiler in the application environment
  #    (`config :libwbxml, :libwbxml_dir`).
  # 2. The priv directory that ships with the `:libwbxml` OTP application.
  @spec priv_dir() :: String.t()
  defp priv_dir do
    case Application.get_env(:libwbxml, :libwbxml_dir) do
      nil ->
        case :code.priv_dir(:libwbxml) do
          dir when is_list(dir) ->
            to_string(dir)

          {:error, :bad_name} ->
            raise "Unable to locate priv directory for :libwbxml - did the native compiler run?"
        end

      path when is_binary(path) ->
        path
    end
  end

  @spec load_nif() :: :ok | {:error, {atom(), String.t()}}
  def load_nif do
    nif_path = Path.join(priv_dir(), "wbxml_nif")
    :erlang.load_nif(String.to_charlist(nif_path), 0)
  end

  # ---------------------------------------------------------------------------
  # Public API - these are substituted by the NIF at load time
  # ---------------------------------------------------------------------------

  @doc """
  Decode a WBXML-encoded `binary` into a regular XML `String`.

  Returns `{:ok, xml}` on success or `{:error, reason}` when decoding fails.

  This function is executed in native code (NIF).  If the shared library
  wasn't loaded for some reason you'll get `:nif_not_loaded`.
  """
  @spec decode(binary()) :: {:ok, String.t()} | {:error, term()}
  def decode(_wbxml), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Encode an XML `String` (or any iodata) into WBXML format.

  Returns `{:ok, wbxml_binary}` on success or `{:error, reason}`.
  """
  @spec encode(String.t() | iodata()) :: {:ok, binary()} | {:error, term()}
  def encode(_xml), do: :erlang.nif_error(:nif_not_loaded)
end
