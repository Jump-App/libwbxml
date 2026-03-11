defmodule LibwbxmlRoundtripTest do
  use ExUnit.Case, async: true

  @fixture Path.expand("fixtures/sync_initial_no_events.xml", __DIR__)

  setup_all do
    build_path = Mix.Project.build_path()
    priv_dir = Path.join(build_path, "lib/libwbxml/priv/")
    Application.put_env(:libwbxml, :libwbxml_dir, priv_dir)
    Libwbxml.load_nif()

    xml = File.read!(@fixture)
    {:ok, xml: xml}
  end

  defp valid_string?(string) do
    String.valid?(string) and not Regex.match?(~r/[\x00-\x08\x0B\x0C\x0E-\x1F]/u, string)
  end

  defp well_formed_tags?(xml) do
    # Very lightweight tag matcher - not a full XML parser.
    # Ignores self-closing tags and attributes.
    regex = ~r/<\/?([A-Za-z0-9:_-]+)(?:\s[^>]*)?>/

    regex
    |> Regex.scan(xml)
    |> Enum.reduce([], fn [full, tag | _], stack ->
      cond do
        String.ends_with?(full, "/>") ->
          stack

        String.starts_with?(full, "</") ->
          case stack do
            [^tag | rest] -> rest
            _ -> [:error]
          end

        true ->
          [tag | stack]
      end
    end)
    |> case do
      [] -> true
      _ -> false
    end
  end

  test "encode then decode preserves well-formed XML", %{xml: xml} do
    {:ok, wbxml} = Libwbxml.encode(xml)
    assert is_binary(wbxml) and byte_size(wbxml) > 0

    {:ok, decoded} = Libwbxml.decode(wbxml)
    decoded_str = to_string(decoded)

    assert valid_string?(decoded_str)
    assert well_formed_tags?(decoded_str)
  end
end
