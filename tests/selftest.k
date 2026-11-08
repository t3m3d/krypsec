func ksAssert(condition, message) {
    if condition == 0 { printErr("FAIL: " + message + "\n") exit("1") }
    emit 1
}
func ksSelfTest() {
    let pool = newPool()
    ksAssert(toolCount() >= 50, "catalog includes at least 50 tools")
    let i = 0
    while i < toolCount() {
        ksAssert(toolField(i, 0) != "" && toolField(i, 2) != "", "catalog entry " + toStr(i))
        let j = i + 1
        while j < toolCount() { ksAssert(toolField(i, 0) != toolField(j, 0), "unique " + toolField(i, 0) + "/" + toolField(j, 0)) j += 1 }
        i += 1
    }
    ksAssert(shellQuote("a'b") == "'a'\"'\"'b'", "shell quotes apostrophes")
    ksAssert(literalArgs("") == "", "empty arguments")
    ksAssert(literalArgs("--help") == " '--help'", "single argument")
    ksAssert(literalArgs("-o 'two words' \"\"") == " '-o' 'two words' ''", "quoted and empty arguments")
    ksAssert(literalArgs("one\\ two") == " 'one two'", "escaped space")
    ksAssert(literalArgs("'unfinished") == "!error", "reject unmatched quotes")
    ksAssert(literalArgs("unfinished\\") == "!error", "reject incomplete escape")
    ksAssert(literalArgs("hello\nworld") == "!error", "reject line injection")
    ksAssert(literalArgs("$(id); | > `id`") == " '$(id);' '|' '>' '`id`'", "shell metacharacters remain literal")
    ksAssert(ksFindIn("zsh", "/does-not-exist:/bin") == "/bin/zsh", "find installed executable")
    ksAssert(ksFindIn("krypsec-nonexistent", "/bin:/usr/bin") == "", "missing executable detected")
    ksAssert(ksFindIn("zsh", "relative:/bin") == "/bin/zsh", "ignore relative executable locations")
    let grid = gridNew(20, 4)
    grid = gridFeed(grid, "Hello\r\n" + fromCharCode(27) + "[31mSTEM", 20, 4)
    ksAssert(contains(gridRender(grid, 20, 4), "Hello"), "embedded STEM renders text")
    ksAssert(contains(gridRender(grid, 20, 4), "STEM"), "embedded STEM handles ANSI colors")
    ksAssert(lineCount(nmapOptions()) > 100, "Nmap option buttons cover the help summary")
    ksAssert(optionArgument("-p", "22,443") == " '-p' '22,443'", "option values are separate literal arguments")
    ksAssert(optionArgument("--script=", "safe") == " '--script=safe'", "equals-form options")
    ksAssert(optionArgument("-PS", "80,443") == " '-PS80,443'", "attached Nmap discovery ports")
    ksAssert(optionArgument("--output", "a'; touch /tmp/injected") == " '--output' " + shellQuote("a'; touch /tmp/injected"), "option values cannot inject shell commands")
    ksAssert(nmapTarget("https://example.com/path?q=1") == "example.com", "website URL becomes Nmap hostname")
    ksAssert(nmapTarget("192.168.1.0/24") == "192.168.1.0/24", "preserve Nmap CIDR targets")
    let parsed = optionsFromHelp("  -h, --help  Show help\n  -o, --output <FILE>  Save output\n  --mode=NAME  Mode\n  --help  Duplicate\n", "")
    ksAssert(contains(parsed, "-h||Show help|"), "discover short help flags")
    ksAssert(contains(parsed, "--help||Show help|"), "discover long aliases")
    ksAssert(contains(parsed, "-o|Value|Save output|"), "short alias takes value")
    ksAssert(contains(parsed, "--output|Value|Save output|"), "discover valued long options")
    ksAssert(contains(parsed, "--mode=|Value|Mode|"), "discover equals options")
    ksAssert(lineCount(parsed) == 5, "deduplicate discovered flags")
    ksAssert(installCommand("/opt/homebrew/bin/brew", "cask:osquery") == "'/opt/homebrew/bin/brew' install --cask 'osquery'", "cask installation uses cask syntax")
    ksAssert(toolInfoURL("cask:osquery") == "https://formulae.brew.sh/cask/osquery", "cask documentation link")
    let curlOptions = optionsFromHelp(exec("/usr/bin/curl --help all"), "")
    ksAssert(lineCount(curlOptions) > 100, "discover actual installed curl option buttons")
    print("All Krypsec self-tests passed.")
    drainPool(pool)
    emit 0
}
