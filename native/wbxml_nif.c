#include <erl_nif.h>
#include <wbxml.h>
#include <string.h>
#include <stdlib.h>  // Include for free()


static ERL_NIF_TERM wbxml_to_xml_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    ErlNifBinary wbxml_bin;

    if (!enif_inspect_binary(env, argv[0], &wbxml_bin)) {
        return enif_make_badarg(env);
    }

    WBXMLConvWBXML2XML* conv = NULL;
    WBXMLError ret = WBXML_OK;
    WB_UTINY* xml_output = NULL;
    WB_ULONG xml_len = 0;

    ret = wbxml_conv_wbxml2xml_create(&conv);
    if (ret != WBXML_OK) goto error;

    // Set the language to ActiveSync
    wbxml_conv_wbxml2xml_set_language(conv, WBXML_LANG_ACTIVESYNC);


    ret = wbxml_conv_wbxml2xml_run(conv, wbxml_bin.data, wbxml_bin.size, &xml_output, &xml_len);
    if (ret != WBXML_OK) goto error;

    ERL_NIF_TERM result = enif_make_string_len(env, (char*)xml_output, xml_len, ERL_NIF_LATIN1);

    wbxml_conv_wbxml2xml_destroy(conv);
    free(xml_output);

    return enif_make_tuple2(env, enif_make_atom(env, "ok"), result);

error:
    if (conv) wbxml_conv_wbxml2xml_destroy(conv);
    if (xml_output) free(xml_output);

    return enif_make_tuple2(env, enif_make_atom(env, "error"), enif_make_string(env, wbxml_errors_string(ret), ERL_NIF_LATIN1));
}

static ERL_NIF_TERM xml_to_wbxml_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    ErlNifBinary xml_bin;

    if (!enif_inspect_binary(env, argv[0], &xml_bin)) {
        return enif_make_badarg(env);
    }

    WBXMLConvXML2WBXML* conv = NULL;
    WBXMLError ret = WBXML_OK;
    WB_UTINY* wbxml_output = NULL;
    WB_ULONG wbxml_len = 0;

    ret = wbxml_conv_xml2wbxml_create(&conv);
    if (ret != WBXML_OK) goto error;

    // Disable public ID
    wbxml_conv_xml2wbxml_disable_public_id(conv);

    ret = wbxml_conv_xml2wbxml_run(conv, xml_bin.data, xml_bin.size, &wbxml_output, &wbxml_len);
    if (ret != WBXML_OK) goto error;

    ErlNifBinary wbxml_bin;
    enif_alloc_binary(wbxml_len, &wbxml_bin);
    memcpy(wbxml_bin.data, wbxml_output, wbxml_len);

    wbxml_conv_xml2wbxml_destroy(conv);
    free(wbxml_output);

    return enif_make_tuple2(env, enif_make_atom(env, "ok"), enif_make_binary(env, &wbxml_bin));

error:
    if (conv) wbxml_conv_xml2wbxml_destroy(conv);
    if (wbxml_output) free(wbxml_output);

    return enif_make_tuple2(env, enif_make_atom(env, "error"), enif_make_string(env, wbxml_errors_string(ret), ERL_NIF_LATIN1));
}

static ErlNifFunc nif_funcs[] = {
    {"decode", 1, wbxml_to_xml_nif},
    {"encode", 1, xml_to_wbxml_nif}
};

static int upgrade(ErlNifEnv* env, void** priv_data, void** old_priv_data, ERL_NIF_TERM load_info) {
    // Handle any necessary state transfer or initialization for the upgrade
    return 0; // Return 0 on success
}

ERL_NIF_INIT(Elixir.Libwbxml, nif_funcs, NULL, NULL, NULL, NULL)
