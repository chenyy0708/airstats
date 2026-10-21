import Foundation
import Testing

/// 字符串表必须盖住界面上会拿去查找的英文键。没有这张表时查找原样返回英文，
/// 所以测试进程本身仍是英文；这里只检查仓库里的 `zh-Hans` 文件。
@Suite("简体中文字符串表盖住界面文案")
struct LocalizationCatalogTests {

    @Test("每个界面键都有译文，格式占位符与英文一致")
    func catalogCoversSourceKeys() throws {
        let root = repoRoot()
        let keys = try sourceKeys(in: root.appendingPathComponent("Sources"))
        let table = try parseStrings(root.appendingPathComponent(
            "Resources/zh-Hans.lproj/Localizable.strings"))
        let english = root.appendingPathComponent("Resources/en.lproj/Localizable.strings")
        #expect(FileManager.default.fileExists(atPath: english.path))

        let plist = try String(contentsOf: root.appendingPathComponent("Resources/Info.plist"),
                               encoding: .utf8)
        #expect(plist.contains("<string>zh-Hans</string>"))
        let build = try String(contentsOf: root.appendingPathComponent("Scripts/build.sh"),
                               encoding: .utf8)
        #expect(build.contains("Resources/*.lproj"))

        var missing: [String] = []
        var specifierMismatches: [String] = []
        for key in keys.sorted() {
            guard let value = table[key] else {
                missing.append(key)
                continue
            }
            if specifiers(in: key) != specifiers(in: value) {
                specifierMismatches.append(key)
            }
        }
        #expect(missing.isEmpty, "缺少译文：\n\(missing.joined(separator: "\n"))")
        #expect(specifierMismatches.isEmpty,
                "格式占位符不一致：\n\(specifierMismatches.joined(separator: "\n"))")
        #expect(table.values.contains { value in
            value.unicodeScalars.contains { (0x4E00...0x9FFF).contains($0.value) }
        })
    }

    /// 这些字符串不是字面量调用，但运行时会拿去查表：电池健康状况来自 IOKit，
    /// 温度失败原因写在采集器里。
    private static let runtimeKeys = [
        "no AppleSMC service on this machine",
        "SMC not open",
        "this Mac's SMC exposes no recognised temperature keys",
        "SMC stopped responding to sensor reads",
        "all sensor domains are powered down",
        "SMC key directory unreadable",
        "No readable CPU temperature sensor.",
        "Check Battery",
        "Permanent Battery Failure",
        "Service Battery",
        "Width",
        "Opacity",
        "Faded opacity",
    ]

    private func sourceKeys(in sources: URL) throws -> Set<String> {
        var keys = Set(Self.runtimeKeys)
        let calls = [
            "L10n.s", "L10n.format", "Text", "Button", "Toggle", "Picker", "Label",
            "LabeledContent", "confirmationDialog", "TextField", "SettingsFootnote",
            "SettingsCaution", "PanelDetailEntry", "ReadoutRow",
        ].map { NSRegularExpression.escapedPattern(for: $0) }
        let callPattern = #"\b(?:\#(calls.joined(separator: "|")))\s*\(\s*"((?:\\.|[^"\\])*)""#
        let attrPattern = #"(?:\.accessibilityLabel|\.accessibilityHint|\.accessibilityValue|\.help|\.failed|\.unsupported|\.denied)\s*\(\s*"((?:\\.|[^"\\])*)""#
        let sliderPattern = #"SettingsSlider\s*\(\s*title:\s*"((?:\\.|[^"\\])*)""#
        let call = try NSRegularExpression(pattern: callPattern)
        let attr = try NSRegularExpression(pattern: attrPattern)
        let slider = try NSRegularExpression(pattern: sliderPattern)

        let enumerator = FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil)!
        for case let url as URL in enumerator {
            guard url.pathExtension == "swift" else { continue }
            let text = try String(contentsOf: url, encoding: .utf8)
            let range = NSRange(text.startIndex..., in: text)
            for expression in [call, attr, slider] {
                for match in expression.matches(in: text, range: range) {
                    guard let slice = Range(match.range(at: 1), in: text) else { continue }
                    let raw = String(text[slice])
                    if raw.contains("\\(") { continue }
                    let key = unescape(raw)
                    if !key.isEmpty { keys.insert(key) }
                }
            }
        }
        return keys
    }

    private func parseStrings(_ url: URL) throws -> [String: String] {
        var text = try String(contentsOf: url, encoding: .utf8)
        if text.hasPrefix("\u{FEFF}") { text.removeFirst() }
        let comments = try NSRegularExpression(pattern: #"(?s)/\*.*?\*/"#)
        let ns = text as NSString
        text = comments.stringByReplacingMatches(in: text, range: NSRange(location: 0, length: ns.length),
                                                 withTemplate: "")
        let entry = try NSRegularExpression(
            pattern: #""((?:\\.|[^"\\])*)"\s*=\s*"((?:\\.|[^"\\])*)"\s*;"#)
        var table: [String: String] = [:]
        let range = NSRange(text.startIndex..., in: text)
        for match in entry.matches(in: text, range: range) {
            guard let keyRange = Range(match.range(at: 1), in: text),
                  let valueRange = Range(match.range(at: 2), in: text) else { continue }
            let key = unescape(String(text[keyRange]))
            #expect(table[key] == nil, "重复的键：\(key)")
            table[key] = unescape(String(text[valueRange]))
        }
        return table
    }

    private func unescape(_ raw: String) -> String {
        raw.replacingOccurrences(of: "\\\"", with: "\"")
            .replacingOccurrences(of: "\\\\", with: "\\")
            .replacingOccurrences(of: "\\n", with: "\n")
    }

    /// `%%` 是字面百分号，不计入占位符。
    private func specifiers(in text: String) -> [String] {
        let pattern = #"%(?!%)(?:\d+\$)?[0-9]*(?:\.[0-9]+)?(?:ll|l|h|hh|z|t|q)?[diouxXfFeEgGaAcCsSp@]"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return expression.matches(in: text, range: range).compactMap { match in
            Range(match.range, in: text).map { String(text[$0]) }
        }
    }

    private func repoRoot() -> URL {
        var url = URL(fileURLWithPath: #filePath)
        url.deleteLastPathComponent()
        url.deleteLastPathComponent()
        url.deleteLastPathComponent()
        return url
    }
}
