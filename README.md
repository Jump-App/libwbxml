# libwbxml - Native WBXML encoder/decoder for Elixir

This package wraps the C reference implementation of *libwbxml* and exposes
two Elixir functions:

```elixir
{:ok, wbxml_binary} = Libwbxml.encode(xml_string)
{:ok, xml_string}   = Libwbxml.decode(wbxml_binary)
```

the dependency is compiled.
The heavy lifting happens inside a C reference implementation of *libwbxml*.
This project compiles the vendored upstream sources **together with** the Erlang
NIF (`wbxml_nif.so`) via the project's `Makefile` and the
[`elixir_make`](https://hex.pm/packages/elixir_make) compiler.
Because the compiler hook runs **before** the Elixir code is loaded,
`Libwbxml.load_nif/0` is guaranteed to succeed as long as your build tool-chain
is present.

## Configuration

```elixir
# config/config.exs
config :libwbxml,
  skip_native_build: false # set to `true` if libwbxml is pre-installed system-wide
```

* `skip_native_build: true` - skips building the static `libwbxml2.a` archive
  and links the NIF against a system-wide installation (`-lwbxml2`).  The NIF
  is still compiled so the Elixir API works.

## Compiler task

* `mix compile.libwbxml` - (re)builds native artefacts
* `mix compile.libwbxml --force` - forces rebuild even if nothing is stale
* `mix compile.libwbxml --verbose` - prints each shell command executed
* `mix clean` - removes artefacts & manifest (`{:noop, []}` when nothing to do)

The task runs automatically when the dependency is compiled; you almost never
need to invoke it manually.

## Development workflow

1. `git clone ... && cd pkgs/libwbxml`
2. `mix test` - the very first run downloads & builds *libwbxml* (approx. 10 s on a
   modern laptop). Subsequent test runs are instant.

Useful Mix tasks - executed automatically by regular `mix compile`:

* `mix compile.libwbxml` - (re)compile native artefacts
* `mix compile.libwbxml --force` - force rebuild even if nothing is stale
* `mix compile.libwbxml --verbose` - print each executed shell command

## Testing

The test-suite exercises both the Elixir wrapper and the NIF round-trip.  It
does **not** attempt to validate the *semantics* of the C library itself - we
trust the upstream test-suite for that - only that our build & FFI plumbing
is correct.

## License

MIT for the Elixir wrapper.  libwbxml itself is LGPL-2.1.
