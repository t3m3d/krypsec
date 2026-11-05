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
    let plist = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<plist version=\"1.0\"><dict>\n<key>CFBundleName</key><string>Krypsec</string>\n<key>CFBundleDisplayName</key><string>Krypsec</string>\n<key>CFBundleExecutable</key><string>Krypsec</string>\n<key>CFBundleIdentifier</key><string>org.krypton-lang.krypsec</string>\n<key>CFBundlePackageType</key><string>APPL</string>\n<key>CFBundleShortVersionString</key><string>0.1.0</string>\n<key>CFBundleVersion</key><string>1</string>\n<key>LSMinimumSystemVersion</key><string>14.0</string>\n<key>NSPrincipalClass</key><string>NSApplication</string>\n<key>NSHighResolutionCapable</key><true/>\n<key>LSApplicationCategoryType</key><string>public.app-category.developer-tools</string>\n</dict></plist>\n"
    if msg_4(nsString(plist), "writeToFile:atomically:encoding:error:", nsString(contents + "/Info.plist"), 1, 4, 0) == 0 { printErr("Cannot write bundle metadata.\n") exit("1") }
    buildRun("/usr/bin/plutil", buildArgs2("-lint", contents + "/Info.plist"))
    buildRun("/usr/bin/codesign", buildArgs4("--force", "--sign", "-", bundle))
    buildRun("/usr/bin/codesign", buildArgs4("--verify", "--deep", "--strict", bundle))
    if arg("0") == "test" { buildRun(executable, buildArgs("--selftest")) }
    print("Ready: " + bundle)
    if arg("0") == "run" { buildRun("/usr/bin/open", buildArgs(bundle)) }
    drainPool(pool)
}
