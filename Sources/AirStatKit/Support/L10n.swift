import Foundation

/// 界面文案。键就是英文原文，字符串表里没有该键时原样返回，因此英文是默认语言。
///
/// 查找走 `Bundle.main`：`Scripts/build.sh` 会把 `Resources/*.lproj` 放进 `.app`。
/// 单元测试和未打包的 SwiftPM 二进制没有这张表，于是仍得到英文键。
public enum L10n {
    public static func s(_ key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: key, table: "Localizable")
    }

    public static func format(_ key: String, _ args: CVarArg...) -> String {
        String(format: s(key), locale: Locale.current, arguments: args)
    }
}
