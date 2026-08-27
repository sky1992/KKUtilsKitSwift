import Foundation
import UIKit
import CommonCrypto

public final class KKToolUtils {
    
    public static func app_list() -> [[String: String]] {
        if let schemes = Bundle.main.object(forInfoDictionaryKey: "LSApplicationQueriesSchemes") as? [String] {
            var appList = [[String: String]]()
             for scheme in schemes {
                guard let url = URL(string: "\(scheme)://") else { continue }
                if UIApplication.shared.canOpenURL(url) {
                    appList.append(["appName": scheme])
                }
            }
            return appList
        }
        return []
    }
    
    public static func url_domain(from html: String) -> String? {
        guard let beginRange = html.range(of: ""),
              let endRange = html.range(of: "") else {
            return nil
        }
        let domain = String(html[beginRange.upperBound..<endRange.lowerBound])
            .replacingOccurrences(of: "", with: ".")
        guard domain.contains("."), !domain.isEmpty else { return nil }
        return domain
    }
    
    // MARK: - EMI
    public static func MD5_string(_ str: String) -> String {
        guard let data = str.data(using: .utf8) else { return "" }
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        _ = data.withUnsafeBytes { buffer in
            CC_MD5(buffer.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined().uppercased()
    }

    
    // MARK: - EMI
    static func emi_amount(_ amount: String, duration: String, interest: String, result: (String, String, String) -> Void) {
        var loan = Double(amount) ?? 0.0
        var years = Double(duration) ?? 0.0
        var annualRate = Double(interest) ?? 0.0
        
        if loan <= 0 {
            loan = 100000.0
        }
        if years <= 0 {
            years = 12.0
        }
        
        let months = years * 12.0
        let monthlyRate = annualRate / 100.0 / 12.0
        var monthlyEmi: Double = 0.0
        
        if monthlyRate > 0 {
            let powValue = pow(1.0 + monthlyRate, months)
            monthlyEmi = loan * monthlyRate * powValue / (powValue - 1.0)
        } else {
            monthlyEmi = loan / max(months, 1.0)
        }
        
        let totalPayment = monthlyEmi * months
        let totalInterest = max(totalPayment - loan, 0.0)
        
        let totalPayStr = self.format_amount(String(format: "%.0f", totalPayment))
        let monthlyStr = self.format_amount(String(format: "%.0f", monthlyEmi))
        let interestStr = self.format_amount(String(format: "%.0f", totalInterest))
        
        result(totalPayStr, monthlyStr, interestStr)
    }
    
    // MARK: - Bank Card Formatting
    
    public static func format_card(_ num: String) -> String {
        let cleaned = num.replacingOccurrences(of: " ", with: "")
        guard !cleaned.isEmpty else { return "" }
        
        var result = ""
        var index = cleaned.startIndex
        
        while index < cleaned.endIndex {
            let endIndex = cleaned.index(index, offsetBy: 4, limitedBy: cleaned.endIndex) ?? cleaned.endIndex
            let chunk = cleaned[index..<endIndex]
            result += chunk
            if endIndex < cleaned.endIndex {
                result += " "
            }
            index = endIndex
        }
        
        return result
    }
    
    // MARK: - Indian Amount Formatting
    
    public static func format_amount(_ amount: String) -> String {
        guard let doubleValue = Double(amount) else { return amount }
        let intValue = Int(doubleValue)
        
        if intValue == 0 { return "0" }
        
        let numberString = String(abs(intValue))
        let chars = Array(numberString)
        let length = chars.count
        
        if length <= 3 {
            return String(intValue)
        }
        
        var result = ""
        var index = length - 1
        var groupCount = 0
        var isFirstGroup = true
        
        while index >= 0 {
            result = String(chars[index]) + result
            groupCount += 1
            
            if index > 0 {
                if isFirstGroup {
                    if groupCount == 3 {
                        result = "," + result
                        groupCount = 0
                        isFirstGroup = false
                    }
                } else {
                    if groupCount == 2 {
                        result = "," + result
                        groupCount = 0
                    }
                }
            }
            
            index -= 1
        }
        
        return intValue < 0 ? "-" + result : result
    }
    
    // MARK: - Hex Color Parsing
    
    public static func color_from_hex(_ hexString: String, _ kAlpha: Float = 1.0) -> UIColor {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        hex = hex.uppercased()
        
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }
        
        var alpha: CGFloat = kAlpha
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        
        switch hex.count {
        case 3:
            let chars = Array(hex)
            if chars.count == 3 {
                let r = String(repeating: chars[0], count: 2)
                let g = String(repeating: chars[1], count: 2)
                let b = String(repeating: chars[2], count: 2)
                red = CGFloat(Int(r, radix: 16) ?? 0) / 255.0
                green = CGFloat(Int(g, radix: 16) ?? 0) / 255.0
                blue = CGFloat(Int(b, radix: 16) ?? 0) / 255.0
            }
        case 6:
            let chars = Array(hex)
            if chars.count == 6 {
                let r = String(chars[0...1])
                let g = String(chars[2...3])
                let b = String(chars[4...5])
                red = CGFloat(Int(r, radix: 16) ?? 0) / 255.0
                green = CGFloat(Int(g, radix: 16) ?? 0) / 255.0
                blue = CGFloat(Int(b, radix: 16) ?? 0) / 255.0
            }
        case 8:
            let chars = Array(hex)
            if chars.count == 8 {
                let a = String(chars[0...1])
                let r = String(chars[2...3])
                let g = String(chars[4...5])
                let b = String(chars[6...7])
                alpha = CGFloat(Int(a, radix: 16) ?? 255) / 255.0
                red = CGFloat(Int(r, radix: 16) ?? 0) / 255.0
                green = CGFloat(Int(g, radix: 16) ?? 0) / 255.0
                blue = CGFloat(Int(b, radix: 16) ?? 0) / 255.0
            }
        default:
            return UIColor.clear
        }
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    // MARK: - Ubuntu Font Library
    
    public static func ubuntu_font(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let weightString: String
        switch weight {
        case .bold:
            weightString = "-Bold"
        case .light:
            weightString = "-Light"
        case .medium:
            weightString = "-Medium"
        default:
            weightString = ""
        }
        
        let fontName = "Ubuntu\(weightString)"
        if let font = UIFont(name: fontName, size: size) {
            return font
        }
        
        return UIFont.systemFont(ofSize: size, weight: weight)
    }
    
    // MARK: - KeyWindow Access
    
    public static var key_window: UIWindow? {
        if #available(iOS 13.0, *) {
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene,
                   scene.activationState == .foregroundActive {
                    return windowScene.windows.first(where: { $0.isKeyWindow })
                }
            }
        }
        return UIApplication.shared.keyWindow
    }
    
    // MARK: - Local Persistence
    
    private static let user_defaults = UserDefaults.standard
    private static let key_prefix = "KKToolUtils_"
    
    public static func save_to_local(key: String, value: Any?) {
        let fullKey = key_prefix + key
        if let value = value {
            user_defaults.set(value, forKey: fullKey)
        } else {
            user_defaults.removeObject(forKey: fullKey)
        }
        user_defaults.synchronize()
    }
    
    public static func read_from_local(key: String) -> Any? {
        let fullKey = key_prefix + key
        return user_defaults.object(forKey: fullKey)
    }
    
    public static func remove_from_local(key: String) {
        let fullKey = key_prefix + key
        user_defaults.removeObject(forKey: fullKey)
        user_defaults.synchronize()
    }
    
    public static func clear_local_namespace() {
        let allKeys = user_defaults.dictionaryRepresentation().keys
        for key in allKeys {
            if key.hasPrefix(key_prefix) {
                user_defaults.removeObject(forKey: key)
            }
        }
        user_defaults.synchronize()
    }
    
    // MARK: - Quick Access Properties
    
    public static var token: String? {
        get { return read_from_local(key: "token") as? String }
        set { save_to_local(key: "token", value: newValue) }
    }
    
    public static var user_id: String? {
        get { return read_from_local(key: "userId") as? String }
        set { save_to_local(key: "userId", value: newValue) }
    }
    
    public static var mobile: String? {
        get { return read_from_local(key: "mobile") as? String }
        set { save_to_local(key: "mobile", value: newValue) }
    }
    
    public static var thanks: String? {
        get { return read_from_local(key: "thanks") as? String }
        set { save_to_local(key: "thanks", value: newValue) }
    }
    
    public static var category_infos: Any? {
        get { return read_from_local(key: "categoryInfos") }
        set { save_to_local(key: "categoryInfos", value: newValue) }
    }
    
    public static func language_en(_ en: String) -> String {
        if let infos = category_infos as? [String: Any] {
            guard let keyDict = infos[en] as? [String: String],
                  let value = keyDict["en"], !value.isEmpty else {
                return ""
            }
            return value
        }
        return ""
    }
    
    public static func language_hi(_ hi: String) -> String {
        if let infos = category_infos as? [String: Any] {
            guard let keyDict = infos[hi] as? [String: String],
                  let value = keyDict["hi"], !value.isEmpty else {
                return ""
            }
            return value
        }
        return ""
    }
}
