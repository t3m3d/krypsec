// Run from the repository root: kcc build.ks -o .build/build && .build/build test
import "k:objc"
import "k:objk_process_macos"
func buildArgs(a) { let items = okProcessArgs() doProcessArg(items, a) emit items }
func buildArgs2(a, b) { let items = buildArgs(a) doProcessArg(items, b) emit items }
func buildArgs3(a, b, c) { let items = buildArgs2(a, b) doProcessArg(items, c) emit items }
func buildArgs4(a, b, c, d) { let items = buildArgs3(a, b, c) doProcessArg(items, d) emit items }
func buildRun(executable, arguments) {
    let result = okRunArgvCaptured(executable, arguments)
    let end = indexOf(result, "\n")
    let status = substring(result, 0, end)
    let output = substring(result, end + 1, len(result))
    if output != "" { print(output) }
    if status != "0" { printErr("Build failed: " + executable + " (exit " + status + ")\n") exit("1") }
    emit 1
}
// Quote one path for the shell string below. build.ks compiles on its own, so it
// cannot reach shellQuote in src/catalog.k.
func buildQuote(text) { emit "'" + replace(text, "'", "'\"'\"'") + "'" }
just run {
    let pool = newPool()
    let root = nsToStr(msg(msg(cls("NSFileManager"), "defaultManager"), "currentDirectoryPath"))
    let bundle = root + "/dist/Krypsec.app"
    let contents = bundle + "/Contents"
    let executable = contents + "/MacOS/Krypsec"
    let compiler = environ("KCC")
    if compiler == "" { compiler = "/usr/local/bin/kcc" }
    buildRun("/bin/mkdir", buildArgs3("-p", contents + "/MacOS", contents + "/Resources"))
    buildRun(compiler, buildArgs3(root + "/src/main.ks", "-o", executable))
    buildRun("/bin/cp", buildArgs2(root + "/resources/stem.conf", contents + "/Resources/stem.conf"))
    buildRun("/bin/cp", buildArgs2(root + "/vendor/stem/LICENSE", contents + "/Resources/STEM-LICENSE"))
    // App icon: assets/krypsec.png is the single source. One shell pipeline
    // renders the .iconset and packs Contents/Resources/Krypsec.icns, so the
    // bundle stays self-contained and signed. A missing PNG leaves the bundle
    // icon-less instead of failing the build.
    let iconScript = "src=" + buildQuote(root + "/assets/krypsec.png") + "; [ -f \"$src\" ] || exit 0; set -e; icon=" + buildQuote(root + "/.build/Krypsec.iconset") + "; rm -rf \"$icon\"; mkdir -p \"$icon\"; for s in 16 32 128 256 512; do sips -z $s $s \"$src\" --out \"$icon/icon_${s}x${s}.png\" >/dev/null; sips -z $((s * 2)) $((s * 2)) \"$src\" --out \"$icon/icon_${s}x${s}@2x.png\" >/dev/null; done; iconutil -c icns \"$icon\" -o " + buildQuote(contents + "/Resources/Krypsec.icns")
    buildRun("/bin/zsh", buildArgs2("-c", iconScript))
    let plist = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<plist version=\"1.0\"><dict>\n<key>CFBundleName</key><string>Krypsec</string>\n<key>CFBundleDisplayName</key><string>Krypsec</string>\n<key>CFBundleExecutable</key><string>Krypsec</string>\n<key>CFBundleIdentifier</key><string>org.krypton-lang.krypsec</string>\n<key>CFBundleIconFile</key><string>Krypsec</string>\n<key>CFBundlePackageType</key><string>APPL</string>\n<key>CFBundleShortVersionString</key><string>0.1.0</string>\n<key>CFBundleVersion</key><string>1</string>\n<key>LSMinimumSystemVersion</key><string>14.0</string>\n<key>NSPrincipalClass</key><string>NSApplication</string>\n<key>NSHighResolutionCapable</key><true/>\n<key>LSApplicationCategoryType</key><string>public.app-category.developer-tools</string>\n</dict></plist>\n"
    if msg_4(nsString(plist), "writeToFile:atomically:encoding:error:", nsString(contents + "/Info.plist"), 1, 4, 0) == 0 { printErr("Cannot write bundle metadata.\n") exit("1") }
    buildRun("/usr/bin/plutil", buildArgs2("-lint", contents + "/Info.plist"))
    buildRun("/usr/bin/codesign", buildArgs4("--force", "--sign", "-", bundle))
    buildRun("/usr/bin/codesign", buildArgs4("--verify", "--deep", "--strict", bundle))
    if arg("0") == "test" { buildRun(executable, buildArgs("--selftest")) }
    print("Ready: " + bundle)
    if arg("0") == "run" { buildRun("/usr/bin/open", buildArgs(bundle)) }
    drainPool(pool)
}
