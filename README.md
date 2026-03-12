# libwbxml - Native WBXML encoder/decoder for Elixir

This package wraps the C reference implementation of *libwbxml* and exposes
two Elixir functions:

```elixir
{:ok, wbxml_binary} = Libwbxml.encode(xml_string)
{:ok, xml_string}   = Libwbxml.decode(wbxml_binary)
```

the dependency is compiled.
The heavy lifting happens inside a C reference implementation of *libwbxml*.
This project compiles it **together with** the Erlang NIF (`wbxml_nif.so`)
via the [`elixir_make`](https://hex.pm/packages/elixir_make) compiler.
Because the compiler hook runs **before** the Elixir code is loaded,
`Libwbxml.load_nif/0` is guaranteed to succeed as long as your build tool-chain
is present.

The upstream `libwbxml` sources are vendored in `vendor/libwbxml/` and currently
pinned to `libwbxml-0.11.10` (`e58b1f19f11dbadff53e5b486b8c4b16639a656a`). See
`vendor/libwbxml/VENDORED_VERSION` for the pinned source metadata.

When release artifacts are available, `libwbxml` will prefer downloading a
precompiled NIF for the current target. Set `LIBWBXML_FORCE_BUILD=true` to skip
artifact download and force a local build from the vendored sources.

## Compiler task

* `mix compile` - builds native artefacts through `elixir_make`
* `mix clean` - removes artefacts and the native build directory
* `MIX_ENV=prod mix elixir_make.precompile` - builds release tarballs for the
  configured targets

The task runs automatically when the dependency is compiled; you almost never
need to invoke it manually.

## Development workflow

1. `git clone ...`
2. `mix test` - the very first run compiles the vendored *libwbxml* sources.
   Subsequent test runs are instant.

Useful Mix task:

* `mix compile` - (re)compile native artefacts through the project `Makefile`

## Testing

The test-suite exercises both the Elixir wrapper and the NIF round-trip.  It
does **not** attempt to validate the *semantics* of the C library itself - we
trust the upstream test-suite for that - only that our build & FFI plumbing
is correct.

## Release workflow

Create and push a version tag to trigger the release pipeline:

```sh
git tag vX.Y.Z
git push origin vX.Y.Z
```

Pushing a `v*` tag automatically runs `.github/workflows/release.yml`, which
builds the precompiled artifacts, creates or updates the corresponding GitHub
Release, and uploads the generated tarballs.

## License

MIT for the Elixir wrapper.  libwbxml itself is LGPL-2.1.
