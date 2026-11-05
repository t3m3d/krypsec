// Native Objective-K workbench. All long-running commands use STEM PTYs.
func ksGet(key) { emit okGet(appH(), "krypsec." + key) }
func ksSet(key, value) { okSet(appH(), "krypsec." + key, value) emit 1 }
func ksText(key) { emit nsToStr(ksGet(key)) }
func ksNumber(key) { emit cocoaNumberVal(ksGet(key)) }
func ksStatus(text) { okSetText(ksGet("status"), text) emit 1 }
func ksExecutable(path) {
    emit msg_1(msg(cls("NSFileManager"), "defaultManager"), "isExecutableFileAtPath:", nsString(path))
}
func ksSearchPath() {
    emit "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:" + environ("HOME") + "/.local/bin:" + environ("HOME") + "/go/bin:" + environ("HOME") + "/.cargo/bin:" + environ("PATH")
}
func ksFindIn(name, paths) {
    let index = 0
    let entry = part(paths, ":", index)
    while entry != "" {
        let candidate = entry + "/" + name
        if startsWith(entry, "/") && ksExecutable(candidate) != 0 { emit candidate }
        index += 1
        entry = part(paths, ":", index)
    }
    emit ""
}
func ksFind(index) {
    let name = toolField(index, 2)
    let formula = toolField(index, 3)
    let found = ksFindIn(name, ksSearchPath())
    if found != "" { emit found }
    if formula != "" {
        found = ksFindIn(name, "/opt/homebrew/opt/" + formula + "/bin:/usr/local/opt/" + formula + "/bin:/opt/homebrew/opt/" + formula + "/sbin:/usr/local/opt/" + formula + "/sbin")
    }
    emit found
}
func ksPaths() { emit ksGet("paths") }
func ksPath(index) { emit nsToStr(okArrayGet(ksPaths(), index)) }
func ksSelected() { emit ksNumber("selected") }
func ksRows(self, command, table) { emit okArrayCount(ksGet("visible")) }
func ksCell(self, command, table, column, row) {
    let index = cocoaNumberVal(okArrayGet(ksGet("visible"), row))
    if nsToStr(msg(column, "identifier")) == "state" {
        if ksPath(index) != "" { emit nsString("Ready") }
        emit nsString("Install")
    }
    emit nsString(toolField(index, 0))
}
func ksDetails(index) {
    if index < 0 { emit 0 }
    ksSet("selected", cocoaNumber(index))
    okSetText(ksGet("name"), toolField(index, 0) + "  /  " + toolField(index, 1))
    okSetText(ksGet("description"), toolField(index, 4))
    let path = ksPath(index)
    let detail = "Not installed. Homebrew formula: " + toolField(index, 3)
    if toolField(index, 3) == "" { detail = "macOS built-in unavailable on this system." }
    if path != "" { detail = "Installed: " + path }
    okSetText(ksGet("installed"), detail)
    okEnabled(ksGet("run"), path != "" && ksNumber("busy") == 0)
    okEnabled(ksGet("install"), path == "" && toolField(index, 3) != "" && ksNumber("busy") == 0)
    emit 1
}
func ksClicked(table) {
    let rows = okSelection(table)
    if okSelectionCount(rows) > 0 {
        let index = cocoaNumberVal(okArrayGet(ksGet("visible"), okSelectionAt(rows, 0)))
        if index != ksSelected() { okSetText(ksGet("arguments"), toolField(index, 5)) }
        ksDetails(index)
    }
    emit 0
}
func ksFilter(field) {
    let query = toLower(okText(field))
    let visible = okArray()
    let index = 0
    while index < toolCount() {
        if query == "" || contains(toLower(toolRecord(index)), query) { okArrayAdd(visible, cocoaNumber(index)) }
        index += 1
    }
    ksSet("visible", visible)
    okSelectNone(ksGet("table"))
    okReload(ksGet("table"))
    if okArrayCount(visible) > 0 { okSelectRow(ksGet("table"), 0, 0) ksClicked(ksGet("table")) }
    else {
        ksSet("selected", cocoaNumber(-1))
        okSetText(ksGet("name"), "No matching tools")
        okSetText(ksGet("description"), "Search by tool name, category, or description.")
        okSetText(ksGet("installed"), "")
        okEnabled(ksGet("run"), 0) okEnabled(ksGet("install"), 0)
    }
    emit 0
}
func ksRefresh(self, command, sender) {
    let paths = okArray()
    let index = 0
    let ready = 0
    while index < toolCount() {
        let path = ksFind(index)
        okArrayAdd(paths, nsString(path))
        if path != "" { ready += 1 }
        index += 1
    }
    ksSet("paths", paths)
    ksSet("brew", nsString(ksFindIn("brew", ksSearchPath())))
    okReload(ksGet("table"))
    ksDetails(ksSelected())
    if ksNumber("busy") == 0 { ksStatus(toStr(ready) + " / " + toStr(toolCount()) + " tools installed. Select a tool to run or install.") }
    emit 0
}
func ksConfirm(title, text, action) {
    let alert = msg(msg(cls("NSAlert"), "alloc"), "init")
    msg_1(alert, "setMessageText:", nsString(title))
    msg_1(alert, "setInformativeText:", nsString(text))
    msg_1(alert, "addButtonWithTitle:", nsString(action))
    msg_1(alert, "addButtonWithTitle:", nsString("Cancel"))
    let result = msg(alert, "runModal")
    msg(alert, "release")
    emit result == 1000
}
// New PTY per managed job: never type a tool command into an existing process.
func ksLaunch(commandText, title) {
    if ksNumber("busy") != 0 { ksStatus("A job is running. Stop it or wait for completion.") emit 0 }
    let folder = ksText("temporary")
    let serial = ksNumber("serial") + 1
    ksSet("serial", cocoaNumber(serial))
    let marker = folder + "/result-" + toStr(serial)
    let script = folder + "/job-" + toStr(serial) + ".zsh"
    let body = "#!/bin/zsh -f\nexport TERM=xterm-256color COLORTERM=truecolor TERM_PROGRAM=krypsec\nexport PATH=" + shellQuote(ksSearchPath()) + "\ncd " + shellQuote(environ("HOME")) + " || exit 1\nprint -r -- " + shellQuote("$ " + commandText) + "\n" + commandText + "\nks_result=$?\nprint -r -- $ks_result > " + shellQuote(marker) + "\nprint -r -- \"\\n[Finished: exit $ks_result]\"\nexec /bin/zsh -f\n"
    writeFile(script, body)
    let manager = msg(cls("NSFileManager"), "defaultManager")
    let permissions = msg_2(cls("NSDictionary"), "dictionaryWithObject:forKey:", cocoaNumber(448), nsString("NSFilePosixPermissions"))
    if msg_3(manager, "setAttributes:ofItemAtPath:error:", permissions, nsString(script), 0) == 0 { ksStatus("Cannot create executable job script.") emit 0 }
    let masters = cocoaGetAssocKey(appH(), "stem.pmasters")
    let old = cocoaNumberVal(cocoaArrayGet(masters, 0))
    let cols = cocoaNumberVal(cocoaArrayGet(cocoaGetAssocKey(appH(), "stem.pcols"), 0))
    let rows = cocoaNumberVal(cocoaArrayGet(cocoaGetAssocKey(appH(), "stem.prows"), 0))
    let fresh = stemForkPty(cols, rows, script)
    if fresh < 0 { ksStatus("Unable to start a PTY session.") emit 0 }
    fdClose(old)
    cocoaArraySet(masters, 0, cocoaNumber(fresh))
    let keyView = cocoaArrayGet(cocoaGetAssocKey(appH(), "stem.pkviews"), 0)
    cocoaSetAssocKey(keyView, "ptyfd", cocoaNumber(fresh))
    cocoaSetAssocKey(appH(), "stem.master", cocoaNumber(fresh))
    cocoaSetAssocKey(appH(), "stem.focus", keyView)
    cocoaSetAssocKey(appH(), "stem.focusidx", cocoaNumber(0))
    ksSet("resetgrid", cocoaNumber(1))
    ksSet("marker", nsString(marker))
    ksSet("jobtitle", nsString(title))
    ksSet("busy", cocoaNumber(1))
    ksStatus(title + " running in STEM. Keyboard input is live; Stop sends Ctrl-C.")
    ksDetails(ksSelected())
    okEnabled(ksGet("stop"), 1)
    cocoaMakeFirstResponder(cocoaGetAssocKey(appH(), "stem.win"), keyView)
    emit 1
}
func ksRun(self, command, sender) {
    let index = ksSelected()
    if index < 0 { emit 0 }
    let path = ksFind(index)
    if path == "" { ksRefresh(0, 0, 0) ksStatus("Tool is unavailable. Install it, then run it when ready.") emit 0 }
    let arguments = literalArgs(okText(ksGet("arguments")))
    if arguments == "!error" { ksStatus("Invalid arguments: close quotes and remove control characters.") emit 0 }
    ksLaunch(shellQuote(path) + arguments, toolField(index, 0))
    emit 0
}
func ksInstall(self, command, sender) {
    let index = ksSelected()
    if index < 0 || ksNumber("busy") != 0 { emit 0 }
    let formula = toolField(index, 3)
    if formula == "" { ksStatus("This is a macOS built-in; Homebrew installation is unavailable.") emit 0 }
    let brew = ksFindIn("brew", ksSearchPath())
    if brew == "" { ksStatus("Homebrew is required. Use the Homebrew button for installation instructions, then Refresh.") emit 0 }
    let commandText = shellQuote(brew) + " install --formula " + shellQuote(formula)
    if ksConfirm("Install " + toolField(index, 0) + "?", commandText + "\n\nHomebrew will download this package and its dependencies. The tool will not run automatically.", "Install") {
        ksLaunch(commandText, "Install " + toolField(index, 0))
    }
    emit 0
}
func ksStop(self, command, sender) {
    if ksNumber("busy") == 1 {
        fdWrite(cocoaNumberVal(cocoaArrayGet(cocoaGetAssocKey(appH(), "stem.pmasters"), 0)), fromCharCode(3), 1)
        ksStatus("Interrupt sent. Waiting for the process to finish…")
    }
    emit 0
}
func ksPoll() {
    if ksNumber("busy") == 0 { emit 0 }
    let result = trim(readFile(ksText("marker")))
    if result == "" { emit 0 }
    ksSet("busy", cocoaNumber(0))
    okEnabled(ksGet("stop"), 0)
    ksRefresh(0, 0, 0)
    ksStatus(ksText("jobtitle") + " finished (exit " + result + "). Installations never auto-run tools.")
    emit 1
}
func ksBrew(self, command, sender) { shellRun("/usr/bin/open https://brew.sh") emit 0 }
func ksDocs(self, command, sender) {
    let index = ksSelected()
    if index < 0 { emit 0 }
    let formula = toolField(index, 3)
    if formula == "" { ksStatus("Use the tool's help arguments in the Arguments field, then Run.") emit 0 }
    shellRun("/usr/bin/open " + shellQuote("https://formulae.brew.sh/formula/" + formula))
    emit 0
}
func ksCloseAllowed() {
    if ksNumber("busy") == 0 { emit 1 }
    emit ksConfirm("Close running job?", "Closing Krypsec disconnects the terminal and may interrupt " + ksText("jobtitle") + ".", "Close")
}
func ksShouldClose(self, command, win) { emit ksCloseAllowed() }
func ksQuit(self, command, sender) {
    if ksCloseAllowed() { msg_1(appH(), "terminate:", appH()) }
    emit 0
}
func ksLabel(win, key, text, x, y, width, height, mask) {
    let label = okLabel(win, text, x, y, width, height)
    okAutoresizing(label, mask)
    msg_1(label, "setTextColor:", cocoaRGB(214, 219, 228))
    ksSet(key, label)
    emit label
}
func ksButton(win, key, title, x, y, width, handler) {
    let button = okButton(win, title, x, y, width, 30)
    msg_1(button, "setBezelStyle:", 1)
    okAutoresizing(button, 8)
    okClick(button, handler)
    msg_1(button, "setContentTintColor:", cocoaRGB(199, 146, 234))
    ksSet(key, button)
    emit button
}
func ksBuildWorkbench(win, width, height) {
    msg_1(win, "setBackgroundColor:", cocoaRGB(27, 21, 38))
    ksSet("selected", cocoaNumber(0))
    ksSet("busy", cocoaNumber(0))
    ksSet("serial", cocoaNumber(0))
    ksLabel(win, "brand", "KRYPSEC", 18, height - 44, 270, 28, 8)
    msg_1(ksGet("brand"), "setFont:", cocoaMonoFont(22))
    ksLabel(win, "subtitle", "macOS security toolkit · STEM", 18, height - 68, 275, 20, 8)
    let search = okField(win, 18, height - 110, 280, 28)
    msg_1(search, "setBackgroundColor:", cocoaRGB(41, 32, 55))
    msg_1(search, "setTextColor:", cocoaRGB(214, 219, 228))
    okPlaceholder(search, "Search tools or categories")
    okAutoresizing(search, 8)
    ksSet("search", search)
    okFieldOnChange(search, funcptr(ksFilter))
    let table = okTable(win, 18, 72, 280, height - 200)
    ksSet("table", table)
    msg_1(table, "setBackgroundColor:", cocoaRGB(41, 32, 55))
    msg_1(msg(table, "enclosingScrollView"), "setBackgroundColor:", cocoaRGB(41, 32, 55))
    okColumn(table, "tool", "Tool", 176)
    okColumn(table, "state", "Status", 78)
    okRowHeight(table, 27)
    okAutoresizing(msg(table, "enclosingScrollView"), 16)
    let sourceClass = okClass("KrypsecCatalogSource")
    okMethod(sourceClass, "numberOfRowsInTableView:", funcptr(ksRows), "q@:@")
    okMethod(sourceClass, "tableView:objectValueForTableColumn:row:", funcptr(ksCell), "@@:@@q")
    okRegister(sourceClass)
    let source = okNew(sourceClass)
    okDataSource(table, source)
    msg(source, "release")
    okOnClick(table, funcptr(ksClicked))
    let refresh = ksButton(win, "refresh", "Refresh", 18, 22, 104, funcptr(ksRefresh))
    okAutoresizing(refresh, 0)
    let brew = ksButton(win, "homebrew", "Homebrew", 132, 22, 166, funcptr(ksBrew))
    okAutoresizing(brew, 0)
    ksLabel(win, "name", "Select a tool", 330, height - 44, width - 350, 28, 10)
    msg_1(ksGet("name"), "setFont:", cocoaMonoFont(20))
    ksLabel(win, "description", "", 330, height - 70, width - 350, 22, 10)
    ksLabel(win, "installed", "", 330, height - 94, width - 350, 20, 10)
    let arguments = okField(win, 330, height - 132, width - 350, 28)
    okAutoresizing(arguments, 10)
    okPlaceholder(arguments, "Arguments: quoted words supported; shell operators stay literal")
    msg_1(arguments, "setBackgroundColor:", cocoaRGB(41, 32, 55))
    msg_1(arguments, "setTextColor:", cocoaRGB(214, 219, 228))
    ksSet("arguments", arguments)
    ksButton(win, "run", "Run in STEM", 330, height - 174, 140, funcptr(ksRun))
    ksButton(win, "install", "Install…", 480, height - 174, 110, funcptr(ksInstall))
    ksButton(win, "stop", "Stop", 600, height - 174, 90, funcptr(ksStop))
    ksButton(win, "docs", "Tool info", 700, height - 174, 110, funcptr(ksDocs))
    okEnabled(ksGet("stop"), 0)
    ksLabel(win, "status", "", 330, height - 203, width - 350, 23, 10)
    ksLabel(win, "hint", "Run replaces the tool terminal. Use only on systems you own or are authorized to test.", 330, 8, width - 350, 22, 2)
    msg_1(ksGet("run"), "setBezelColor:", cocoaRGB(124, 58, 237))
    msg_1(ksGet("run"), "setContentTintColor:", cocoaRGB(255, 255, 255))
    msg_1(ksGet("brand"), "setTextColor:", cocoaRGB(199, 146, 234))
    msg_1(ksGet("subtitle"), "setTextColor:", cocoaRGB(154, 163, 178))
    msg_1(ksGet("description"), "setTextColor:", cocoaRGB(154, 163, 178))
    msg_1(ksGet("installed"), "setTextColor:", cocoaRGB(158, 206, 106))
    msg_1(ksGet("hint"), "setTextColor:", cocoaRGB(154, 163, 178))
    let emptyPaths = okArray()
    let index = 0
    while index < toolCount() { okArrayAdd(emptyPaths, nsString("")) index += 1 }
    ksSet("paths", emptyPaths)
    ksSet("visible", okArray())
    ksRefresh(0, 0, 0)
    ksFilter(search)
    okSetText(arguments, toolField(0, 5))
    emit 1
}
func ksAbout(self, command, sender) {
    let alert = msg(msg(cls("NSAlert"), "alloc"), "init")
    msg_1(alert, "setMessageText:", nsString("Krypsec 0.1.0"))
    msg_1(alert, "setInformativeText:", nsString("macOS cybersecurity workbench built with Krypton and Objective-K. Embedded STEM terminal, MIT licensed. No tools run or install at launch."))
    msg_1(alert, "addButtonWithTitle:", nsString("OK"))
    msg(alert, "runModal") msg(alert, "release") emit 0
}
