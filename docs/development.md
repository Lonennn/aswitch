# Developing ASwitch

For building and running the CLI, see the [build guide](building.md).
Run the commands below from the repository root.

## C editor setup

After cloning the repository or upgrading the MoonBit toolchain, run this command to make SDK headers available to C editor tooling such as clangd:

```bash
moon run scripts/copy_moon_headers.mbtx
```

If the editor still reports missing headers, restart its C language server.

