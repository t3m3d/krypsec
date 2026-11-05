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
    print("All Krypsec self-tests passed.")
    drainPool(pool)
    emit 0
}
