// Option records: flag|value placeholder|label|exclusive group.
// Nmap starter set is available before installation. Other tools can import
// their installed version's help without running a scan or contacting targets.
func nmapOptions() {
    emit "-sT||TCP connect scan|tcp\n-sS||TCP SYN scan (privileges required)|tcp\n-sU||UDP scan (privileges required)|\n-sn||Host discovery only|scan\n-sL||List targets only|scan\n-Pn||Skip host discovery|\n-sV||Detect service versions|\n-O||Detect operating systems (privileges required)|\n-A||OS, versions, scripts and traceroute|\n-F||Fast scan|\n-p|Ports, e.g. 22,80,443|Specific ports|ports\n-p-||All ports|ports\n--top-ports|Count|Most common ports|ports\n--exclude-ports|Ports|Exclude ports|\n-r||Sequential port order|\n--open||Show open ports only|\n--reason||Explain port states|\n-v||Verbose output|verbosity\n-vv||More verbose output|verbosity\n-d||Debug output|\n-n||Disable DNS resolution|dns\n-R||Always resolve DNS|dns\n--dns-servers|Server addresses|Custom DNS servers|\n--system-dns||Use system DNS|\n--traceroute||Trace network path|\n-6||IPv6|\n-T0||Paranoid timing|timing\n-T1||Sneaky timing|timing\n-T2||Polite timing|timing\n-T3||Normal timing|timing\n-T4||Aggressive timing|timing\n-T5||Insane timing|timing\n--max-retries|Count|Retry limit|\n--host-timeout|Duration, e.g. 30s|Host timeout|\n--scan-delay|Duration|Probe delay|\n--max-scan-delay|Duration|Maximum probe delay|\n--min-rate|Packets per second|Minimum rate|\n--max-rate|Packets per second|Maximum rate|\n--min-hostgroup|Count|Minimum host group|\n--max-hostgroup|Count|Maximum host group|\n--min-parallelism|Count|Minimum parallel probes|\n--max-parallelism|Count|Maximum parallel probes|\n--min-rtt-timeout|Duration|Minimum RTT timeout|\n--max-rtt-timeout|Duration|Maximum RTT timeout|\n--initial-rtt-timeout|Duration|Initial RTT timeout|\n--version-intensity|Level 0 to 9|Version probe intensity|\n--version-light||Light version detection|versions\n--version-all||All version probes|versions\n--version-trace||Trace version probes|\n-sC||Default NSE scripts|\n--script|Scripts or categories|NSE scripts|\n--script-args|name=value,...|NSE script arguments|\n--script-args-file|File path|NSE arguments file|\n--script-help|Scripts or categories|NSE script help|\n--script-trace||Trace NSE traffic|\n--script-updatedb||Rebuild NSE database|\n--osscan-limit||Limit OS detection|\n--osscan-guess||Guess OS aggressively|\n-iL|File path|Read targets from file|\n-iR|Count|Random targets|\n--exclude|Hosts or networks|Exclude targets|\n--excludefile|File path|Read exclusions from file|\n-oN|File path|Normal output file|\n-oX|File path|XML output file|\n-oG|File path|Grepable output file|\n-oS|File path|Script-kiddie output file|\n-oA|Base path|All main output formats|\n--append-output||Append output files|\n--resume|File path|Resume scan|\n--stylesheet|Path or URL|XML stylesheet|\n--webxml||Use Nmap web stylesheet|\n--no-stylesheet||No XML stylesheet|\n--packet-trace||Trace packets|\n--iflist||List interfaces|\n--noninteractive||Disable runtime keyboard controls|\n--datadir|Directory|Nmap data directory|\n--send-eth||Send Ethernet frames|send\n--send-ip||Send IP packets|send\n--privileged||Assume privileges|privilege\n--unprivileged||Assume no raw socket privileges|privilege\n-sA||TCP ACK scan (privileges required)|tcp\n-sW||TCP window scan (privileges required)|tcp\n-sM||TCP Maimon scan (privileges required)|tcp\n-sN||TCP null scan (privileges required)|tcp\n-sF||TCP FIN scan (privileges required)|tcp\n-sX||TCP Xmas scan (privileges required)|tcp\n-sY||SCTP INIT scan (privileges required)|sctp\n-sZ||SCTP COOKIE-ECHO scan (privileges required)|sctp\n-sO||IP protocol scan (privileges required)|\n-sI|Host and optional port|Idle scan|\n-b|FTP relay host|FTP bounce scan|\n--scanflags|Flags|Custom TCP flags|\n-PS|Port list|TCP SYN discovery|\n-PA|Port list|TCP ACK discovery|\n-PU|Port list|UDP discovery|\n-PY|Port list|SCTP discovery|\n-PE||ICMP echo discovery|\n-PP||ICMP timestamp discovery|\n-PM||ICMP netmask discovery|\n-PO|Protocols|IP protocol discovery|\n-f||Fragment packets|\n--mtu|MTU|Custom packet MTU|\n-D|Decoys|Decoy hosts|\n-S|Address|Source address|\n-e|Interface|Network interface|\n-g|Port|Source port|\n--source-port|Port|Source port|\n--proxies|Proxy URLs|Proxy relays|\n--data|Hex bytes|Custom packet data|\n--data-string|Text|Custom packet text|\n--data-length|Count|Random payload length|\n--ip-options|Options|IP options|\n--ttl|Count|IP time to live|\n--spoof-mac|MAC address or vendor|Source MAC|\n--badsum||Invalid checksums|\n-V||Show version|\n-h||Show help|"
}
func starterOptions(index) {
    if toolField(index, 0) == "nmap" { emit nmapOptions() }
    let help = toolField(index, 5)
    if startsWith(help, "-") { emit help + "||Show help|" }
    emit ""
}
func optionAdd(records, flag, placeholder, label) {
    if flag == "" || flag == "-" || flag == "--" { emit records }
    if contains("\n" + records, "\n" + flag + "|") { emit records }
    if records == "" { emit flag + "|" + placeholder + "|" + label + "|" }
    emit records + "\n" + flag + "|" + placeholder + "|" + label + "|"
}
func optionFlagChar(ch) {
    let code = charCode(ch)
    emit (code >= 48 && code <= 57) || (code >= 65 && code <= 90) || (code >= 97 && code <= 122) || ch == "-" || ch == "?"
}
// Help formats vary. Recognize declarations, aliases, metavariables, and
// --flag=value, while retaining unrecognized syntax in Advanced arguments.
func optionsFromHelp(text, records) {
    let lineIndex = 0
    while lineIndex < lineCount(text) {
        let line = trim(getLine(text, lineIndex))
        if startsWith(line, "-") {
            let boundary = indexOf(line, "  ")
            if boundary < 0 { boundary = indexOf(line, "\t") }
            if boundary < 0 { boundary = indexOf(line, ": ") }
            if boundary < 0 { boundary = len(line) }
            let declaration = substring(line, 0, boundary)
            let description = trim(substring(line, boundary, len(line)))
            description = replace(description, "|", "/")
            let pos = 0
            while pos < len(declaration) {
                let ch = substring(declaration, pos, pos + 1)
                if ch == "-" && (pos == 0 || contains(" ,/|\t", substring(declaration, pos - 1, pos))) {
                    let start = pos
                    pos += 1
                    while pos < len(declaration) && optionFlagChar(substring(declaration, pos, pos + 1)) { pos += 1 }
                    let flag = substring(declaration, start, pos)
                    let rest = trim(substring(declaration, pos, len(declaration)))
                    let placeholder = ""
                    if startsWith(rest, "=") || startsWith(rest, "<") || startsWith(rest, "[") { placeholder = "Value" }
                    if rest != "" && !startsWith(rest, "-") && !startsWith(rest, ",") && !startsWith(rest, "/") && !startsWith(rest, "|") && !startsWith(rest, ":") { placeholder = "Value" }
                    // For -o, --output FILE both aliases take a value.
                    if placeholder == "" && (contains(declaration, "<") || contains(declaration, "=") || contains(declaration, " string") || contains(declaration, " FILE") || contains(declaration, " PATH") || contains(declaration, " value") || contains(declaration, " int")) { placeholder = "Value" }
                    if startsWith(rest, "=") { flag = flag + "=" }
                    records = optionAdd(records, flag, placeholder, description)
                } else { pos += 1 }
            }
        }
        lineIndex += 1
    }
    emit records
}
func optionArgument(flag, value) {
    if endsWith(flag, "=") { emit " " + shellQuote(flag + value) }
    if value == "" { emit " " + shellQuote(flag) }
    // Nmap discovery lists must attach to their switch.
    if flag == "-PS" || flag == "-PA" || flag == "-PU" || flag == "-PY" || flag == "-PO" { emit " " + shellQuote(flag + value) }
    emit " " + shellQuote(flag) + " " + shellQuote(value)
}
func ksOptionsChanged(field) { ksPreview() emit 0 }
func ksOptionClicked(self, command, sender) {
    let index = cocoaNumberVal(okGet(sender, "option.index"))
    let records = ksText("options")
    let group = part(part(records, "\n", index), "|", 3)
    let checks = ksGet("checks")
    let fields = ksGet("values")
    let i = 0
    while i < okArrayCount(checks) {
        let check = okArrayGet(checks, i)
        if i != index && group != "" && part(part(records, "\n", i), "|", 3) == group && okState(sender) != 0 { okSetState(check, 0) }
        okEnabled(okArrayGet(fields, i), okState(check) != 0)
        i += 1
    }
    ksPreview()
    emit 0
}
func ksOptionArguments() {
    let output = ""
    let checks = ksGet("checks")
    let values = ksGet("values")
    let records = ksText("options")
    let i = 0
    while i < okArrayCount(checks) {
        if okState(okArrayGet(checks, i)) != 0 {
            let record = part(records, "\n", i)
            let flag = part(record, "|", 0)
            let placeholder = part(record, "|", 1)
            let value = okText(okArrayGet(values, i))
            if placeholder != "" && trim(value) == "" { emit "!value:" + flag }
            if contains(value, "\n") || contains(value, "\r") { emit "!value:" + flag }
            output = output + optionArgument(flag, value)
        }
        i += 1
    }
    emit output
}
func ksCommandArguments() {
    let options = ksOptionArguments()
    if startsWith(options, "!value:") { emit options }
    let advanced = literalArgs(okText(ksGet("arguments")))
    let targetText = okText(ksGet("target"))
    if toolField(ksSelected(), 0) == "nmap" { targetText = nmapTarget(targetText) }
    let targets = literalArgs(targetText)
    if advanced == "!error" || targets == "!error" { emit "!error" }
    emit options + advanced + targets
}
func ksPreview() {
    if ksSelected() < 0 { okSetText(ksGet("preview"), "Select a tool") emit 0 }
    let arguments = ksCommandArguments()
    let text = toolField(ksSelected(), 2) + arguments
    if startsWith(arguments, "!value:") { text = "Enter a value for " + substring(arguments, 7, len(arguments)) }
    if arguments == "!error" { text = "Close quotes and remove control characters from target / arguments." }
    okSetText(ksGet("preview"), text)
    emit 1
}
func ksRenderOptions(records) {
    let win = cocoaGetAssocKey(appH(), "stem.win")
    let scroll = ksGet("optionsScroll")
    let width = msgRectWidth(scroll, "frame") - 18
    let countRows = lineCount(records)
    if records == "" { countRows = 0 }
    let height = countRows * 32 + 12
    if height < 160 { height = 160 }
    let oldRecords = ksText("options")
    let oldChecks = ksGet("checks")
    let oldValues = ksGet("values")
    let document = msg_frame(msg(cls("NSView"), "alloc"), "initWithFrame:", 0, 0, width, height)
    msg_1(scroll, "setDocumentView:", document)
    let checks = okArray()
    let values = okArray()
    let i = 0
    while i < countRows {
        let record = part(records, "\n", i)
        let flag = part(record, "|", 0)
        let placeholder = part(record, "|", 1)
        let label = part(record, "|", 2)
        let checkWidth = width - 244
        if placeholder == "" { checkWidth = width - 18 }
        let check = okCheckbox(win, flag + "   " + label, 10, height - 34 - i * 32, checkWidth, 26)
        msg_1(document, "addSubview:", check)
        msg_1(check, "setContentTintColor:", cocoaRGB(199, 146, 234))
        cocoaSetButtonTextColor(check, cocoaRGB(214, 219, 228))
        okToolTip(check, flag + " · " + label)
        okSet(check, "option.index", cocoaNumber(i))
        okClick(check, funcptr(ksOptionClicked))
        let field = okField(win, width - 232, height - 34 - i * 32, 220, 26)
        msg_1(document, "addSubview:", field)
        msg_1(field, "setBackgroundColor:", cocoaRGB(46, 37, 61))
        msg_1(field, "setTextColor:", cocoaRGB(214, 219, 228))
        okPlaceholder(field, placeholder)
        okToolTip(field, flag + " value: " + placeholder)
        let oldIndex = 0
        while oldIndex < okArrayCount(oldChecks) {
            if part(part(oldRecords, "\n", oldIndex), "|", 0) == flag {
                okSetState(check, okState(okArrayGet(oldChecks, oldIndex)))
                okSetText(field, okText(okArrayGet(oldValues, oldIndex)))
            }
            oldIndex += 1
        }
        okEnabled(field, okState(check) != 0)
        okHidden(field, placeholder == "")
        okFieldOnChange(field, funcptr(ksOptionsChanged))
        okArrayAdd(checks, check)
        okArrayAdd(values, field)
        i += 1
    }
    ksSet("options", nsString(records))
    ksSet("checks", checks)
    ksSet("values", values)
    let clip = msg(scroll, "contentView")
    msg_d2(clip, "scrollToPoint:", 0, height - 160)
    msg_1(scroll, "reflectScrolledClipView:", clip)
    msg(document, "release")
    okSetText(ksGet("optionsLabel"), toStr(countRows) + " option buttons · select flags and fill their values")
    ksPreview()
    emit 1
}
func ksSelectOptions(index) {
    ksSet("checks", okArray())
    ksSet("values", okArray())
    ksSet("options", nsString(""))
    okSetText(ksGet("target"), "")
    okSetText(ksGet("arguments"), "")
    if toolField(index, 0) == "nmap" { okPlaceholder(ksGet("target"), "Target: IP, hostname, or CIDR — e.g. 192.168.1.10 or example.com") }
    else { okPlaceholder(ksGet("target"), "Target / URL / file: separate multiple targets with spaces; quote paths with spaces") }
    let cached = ksGet("optioncache." + toolField(index, 0))
    let records = starterOptions(index)
    if cached != 0 { records = nsToStr(cached) }
    ksRenderOptions(records)
    emit 1
}
// Read help in an asynchronous Foundation task, never on the terminal or UI
// thread. A regular private output file avoids pipe-buffer deadlocks.
func ksLoadOptions(self, command, sender) {
    let index = ksSelected()
    if index < 0 { emit 0 }
    if ksGet("helpTask") != 0 { ksStatus("Help discovery is already running.") emit 0 }
    let path = ksFind(index)
    if path == "" { ksStatus("Install this tool, then click Load options to read its available flags.") emit 0 }
    let file = ksText("temporary") + "/help.txt"
    writeFile(file, "")
    let handle = msg_1(cls("NSFileHandle"), "fileHandleForWritingAtPath:", nsString(file))
    if handle == 0 { ksStatus("Cannot create help capture file.") emit 0 }
    let task = msg(msg(cls("NSTask"), "alloc"), "init")
    let args = okArray()
    okArrayAdd(args, nsString(toolField(index, 5)))
    if toolField(index, 0) == "curl" { okArrayAdd(args, nsString("all")) }
    msg_1(task, "setLaunchPath:", nsString(path))
    msg_1(task, "setArguments:", args)
    msg_1(task, "setStandardOutput:", handle)
    msg_1(task, "setStandardError:", handle)
    msg_1(task, "setStandardInput:", msg(cls("NSFileHandle"), "fileHandleWithNullDevice"))
    if msg_1(task, "launchAndReturnError:", 0) == 0 { msg(task, "release") msg(handle, "closeFile") ksStatus("Unable to read tool help.") emit 0 }
    ksSet("helpTask", task)
    ksSet("helpHandle", handle)
    ksSet("helpIndex", cocoaNumber(index))
    ksSet("helpTicks", cocoaNumber(0))
    ksStatus("Reading installed tool help; no target is used. Existing selections will be preserved.")
    msg(task, "release")
    emit 1
}
func ksPollHelp() {
    let task = ksGet("helpTask")
    if task == 0 { emit 0 }
    let ticks = ksNumber("helpTicks") + 1
    ksSet("helpTicks", cocoaNumber(ticks))
    if msg(task, "isRunning") != 0 {
        if ticks == 40 { msg(task, "terminate") }
        if ticks > 60 { ksStatus("Tool help did not finish. Existing option buttons remain available.") }
        emit 0
    }
    msg(ksGet("helpHandle"), "closeFile")
    let index = ksNumber("helpIndex")
    let text = readFile(ksText("temporary") + "/help.txt")
    let records = optionsFromHelp(stemStripAnsi(text), starterOptions(index))
    ksSet("helpTask", 0)
    ksSet("helpHandle", 0)
    if ticks >= 40 { ksStatus("Help discovery timed out. Existing option buttons are unchanged.") emit 0 }
    ksSet("optioncache." + toolField(index, 0), nsString(records))
    if index == ksSelected() { ksRenderOptions(records) }
    ksStatus("Loaded option buttons from installed help. Review values; Advanced arguments supports unusual or subcommand flags.")
    emit 1
}

func nmapTarget(text) {
    let target = trim(text)
    if startsWith(target, "https://") || startsWith(target, "http://") {
        let url = msg_1(cls("NSURL"), "URLWithString:", nsString(target))
        let host = nsToStr(msg(url, "host"))
        if host != "" { emit host }
    }
    emit text
}
