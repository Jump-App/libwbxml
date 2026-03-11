defmodule LibwbxmlTest do
  use ExUnit.Case, async: true

  @xml_fixture Path.expand("fixtures/ping_status_1.xml", __DIR__)

  setup_all do
    build_path = Mix.Project.build_path()

    # Point the Libwbxml module to the freshly-built NIF and force (re)load.
    priv_dir = Path.join(build_path, "lib/libwbxml/priv/")
    Application.put_env(:libwbxml, :libwbxml_dir, priv_dir)
    Libwbxml.load_nif()

    xml = File.read!(@xml_fixture)

    {:ok, xml: xml}
  end

  describe "encode/1" do
    test "returns a non-empty WBXML binary", %{xml: xml} do
      assert {:ok, wbxml} = Libwbxml.encode(xml)
      assert is_binary(wbxml)
      assert byte_size(wbxml) > 0
    end
  end

  describe "encode/1 and decode/1 round-trip" do
    test "decoded XML contains the expected elements", %{xml: xml} do
      {:ok, wbxml} = Libwbxml.encode(xml)
      assert {:ok, decoded_xml} = Libwbxml.decode(wbxml)

      decoded_str = to_string(decoded_xml)

      assert decoded_str =~ "<Ping"
      assert decoded_str =~ "<Status>1</Status>"
    end
  end

  # Additional error-handling coverage
  describe "decode/1 error handling" do
    test "returns error for invalid data" do
      assert {:error, _} = Libwbxml.decode(<<1, 2, 3, 4>>)
    end
  end
end
