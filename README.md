# Krypsec

A native macOS cybersecurity workbench built in **Krypton and Objective-K**, with the **STEM terminal embedded in the app** and Cortex Mac's purple palette.

Open `dist/Krypsec.app`. Search the 55-tool catalog, select a tool, and install missing tools through Homebrew. Installation requires an explicit click and never automatically runs the tool. The Homebrew button opens its official setup instructions.

Select option checkboxes, fill any associated values, enter an IP address, hostname, website, CIDR, or file in the target field, and click **Run**. The command preview shows the selected flags and quoted values before execution. Nmap includes over 100 starter options, mutually exclusive timing/scan choices, and website-to-hostname conversion. **Load options** reads an installed tool's help asynchronously and adds the flags it advertises; curl uses its full help listing. Existing selections survive help reloads. Use **Advanced arguments** for subcommands or syntax not exposed in a tool's help. Targets and values are passed literally; shell substitutions and operators are not evaluated.

The embedded terminal supports interactive input and split panes. **Stop** sends Ctrl-C to the managed job. A new Run replaces the managed terminal session. Tool output, installation output, and exit status remain visible in the app. Installed status refreshes after jobs finish, and Refresh checks tools installed elsewhere. Only run tools against systems you own or have authorization to test. Some tools require privileges or have platform-specific limitations; the app does not automatically elevate privileges.

## Build and verify

Requires macOS 14+ on Apple Silicon and the Krypton toolchain with Objective-K/OKUI. Tested with the locally installed Krypton 2.4.9 toolchain.

```sh
mkdir -p .build
kcc build.ks -o .build/build
.build/build test
open dist/Krypsec.app
```

`KCC` selects an alternate compiler. The bundle is self-contained and ad-hoc signed for local use; distribution signing and notarization are separate. No Swift, Objective-C, generated C, web server, or WebView is used.

`src/catalog.k` contains the executable catalog and argument quoting, `src/options.k` contains the option builder and help discovery, and `src/workbench.k` contains the native interface and job management. `src/main.ks` integrates STEM from commit `6899b3c2b056d2a6b82a9d37f6168ac78ee709c1`; its MIT license is retained in `vendor/stem/LICENSE` and bundled with the app. Package commands follow the [Homebrew documentation](https://docs.brew.sh/Manpage), and Nmap starter switches follow its [official option summary](https://nmap.org/book/man-briefoptions.html). Help discovery is limited to the selected tool's advertised help; tools with additional subcommand-specific options can use Advanced arguments.
