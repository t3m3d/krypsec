// Curated macOS CLI catalog. Fields: name|category|executable|formula|description|help.
func catalogData() { emit "nmap|Network|nmap|nmap|Network discovery and service inspection|--help\nmasscan|Network|masscan|masscan|High-speed network port scanner|--help\nrustscan|Network|rustscan|rustscan|Fast port discovery|--help\nnetcat|Network|nc||TCP and UDP connection diagnostics|-h\nsocat|Network|socat|socat|Socket relay and network diagnostics|-h\ntcpdump|Network|tcpdump||Packet capture; capture may require privileges|--help\ntshark|Network|tshark|wireshark|Wireshark command-line packet analysis|--help\naircrack-ng|Wireless|aircrack-ng|aircrack-ng|Wireless capture analysis; macOS capture support varies|--help\nmtr|Network|mtr|mtr|Route and connectivity diagnostics|--help\niperf3|Network|iperf3|iperf3|Network throughput measurement|--help\ndig|DNS|dig||DNS record lookup|-h\ndoggo|DNS|doggo|doggo|DNS lookup and diagnostics|--help\ndnsx|DNS|dnsx|dnsx|DNS resolution toolkit|-h\nsubfinder|DNS|subfinder|subfinder|Passive subdomain discovery|-h\namass|DNS|amass|amass|Attack surface and asset discovery|-help\nhttpx|Web|httpx|httpx|ProjectDiscovery HTTP probing; verify executable identity|-h\nnuclei|Web|nuclei|nuclei|Template-based vulnerability checks|-h\nnikto|Web|nikto|nikto|Web server security checks|-Help\nsqlmap|Web|sqlmap|sqlmap|SQL injection testing|-h\nffuf|Web|ffuf|ffuf|HTTP content discovery and fuzzing|-h\ngobuster|Web|gobuster|gobuster|Web content and DNS discovery|--help\nferoxbuster|Web|feroxbuster|feroxbuster|Recursive web content discovery|--help\ntestssl|Web|testssl.sh|testssl|TLS configuration and cipher assessment|--help\ncurl|Web|curl||HTTP and TLS diagnostics|--help\nwget|Web|wget|wget|HTTP download and inspection|--help\nopenssl|Crypto|openssl|openssl@3|TLS certificates and cryptographic utilities|help\ngnupg|Crypto|gpg|gnupg|OpenPGP encryption and signatures|--help\nage|Crypto|age|age|File encryption|--help\nhashcat|Passwords|hashcat|hashcat|Password hash recovery; hardware support varies|--help\njohn|Passwords|john|john-jumbo|John the Ripper password auditing|--list=help\nhydra|Passwords|hydra|hydra|Authentication auditing|-h\ncrunch|Passwords|crunch|crunch|Wordlist generation|-h\nyara|Forensics|yara|yara|Rule-based file and malware analysis|--help\nsleuthkit|Forensics|fls|sleuthkit|Filesystem forensic investigation|-h\nexiftool|Forensics|exiftool|exiftool|File metadata inspection|-h\nbinwalk|Forensics|binwalk|binwalk|Firmware and binary inspection|--help\nradare2|Forensics|r2|radare2|Interactive reverse engineering|-h\nripgrep|Forensics|rg|ripgrep|Fast evidence and log searching|--help\njq|Forensics|jq|jq|JSON log processing|--help\nfile|Forensics|file||File type identification|--help\nstrings|Forensics|strings||Extract printable strings from binaries|-h\ntrivy|Code & cloud|trivy|trivy|Container and filesystem vulnerability scanning|--help\ngrype|Code & cloud|grype|grype|Software vulnerability scanning|--help\nsyft|Code & cloud|syft|syft|Software bill of materials generation|--help\ngitleaks|Code & cloud|gitleaks|gitleaks|Repository secret detection|--help\ntrufflehog|Code & cloud|trufflehog|trufflehog|Secret discovery|--help\nsemgrep|Code & cloud|semgrep|semgrep|Static code analysis|--help\ncheckov|Code & cloud|checkov|checkov|Infrastructure-as-code security checks|--help\nosquery|macOS|osqueryi|cask:osquery|SQL-based operating system inspection|--help\nlsof|macOS|lsof||Open files and connection inspection|-h\ncodesign|macOS|codesign||Inspect macOS code signatures|-h\nspctl|macOS|spctl||Gatekeeper assessment|--help\nsecurity|macOS|security||macOS keychain and certificate utilities|help\nlog|macOS|log||macOS unified log investigation|help\nssh|Network|ssh||Secure shell client|-?" }
func part(text, delimiter, wanted) {
    let start = 0
    let index = 0
    let pos = 0
    while pos < len(text) {
        if substring(text, pos, pos + 1) == delimiter {
            if index == wanted { emit substring(text, start, pos) }
            index += 1
            start = pos + 1
        }
        pos += 1
    }
    if index == wanted { emit substring(text, start, len(text)) }
    emit ""
}
func toolRecord(index) { emit part(catalogData(), "\n", index) }
func toolField(index, field) { emit part(toolRecord(index), "|", field) }
func toolCount() {
    let n = 1
    let i = 0
    let data = catalogData()
    while i < len(data) { if substring(data, i, i + 1) == "\n" { n += 1 } i += 1 }
    emit n
}
func shellQuote(text) { emit "'" + replace(text, "'", "'\"'\"'") + "'" }
// Parse arguments, preserving quoted/empty words. Every word is shell-quoted.
// Shell expansions, redirects, pipes and substitutions stay literal data.
// Return !error for incomplete quoting; newline/control characters are rejected.
func literalArgs(text) {
    let quote = ""
    let escaping = 0
    let started = 0
    let word = ""
    let output = ""
    let i = 0
    while i < len(text) {
        let ch = substring(text, i, i + 1)
        let code = charCode(ch)
        if code < 32 && code != 9 { emit "!error" }
        if code == 127 { emit "!error" }
        if escaping == 1 { word = word + ch escaping = 0 started = 1 }
        else {
            if ch == "\\" && quote != "'" { escaping = 1 started = 1 }
            else {
                if quote != "" {
                    if ch == quote { quote = "" } else { word = word + ch }
                } else {
                    if ch == "'" || ch == "\"" { quote = ch started = 1 }
                    else {
                        if ch == " " || ch == "\t" {
                            if started == 1 { output = output + " " + shellQuote(word) word = "" started = 0 }
                        } else { word = word + ch started = 1 }
                    }
                }
            }
        }
        i += 1
    }
    if escaping == 1 || quote != "" { emit "!error" }
    if started == 1 { output = output + " " + shellQuote(word) }
    emit output
}

func installCommand(brew, formula) {
    if startsWith(formula, "cask:") { emit shellQuote(brew) + " install --cask " + shellQuote(substring(formula, 5, len(formula))) }
    emit shellQuote(brew) + " install --formula " + shellQuote(formula)
}
func toolInfoURL(formula) {
    if startsWith(formula, "cask:") { emit "https://formulae.brew.sh/cask/" + substring(formula, 5, len(formula)) }
    emit "https://formulae.brew.sh/formula/" + formula
}
