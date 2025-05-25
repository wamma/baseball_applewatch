import Foundation

struct TeamSettings {
    private static let key = "myTeam"

    static var myTeam: String {
        get {
            UserDefaults.standard.string(forKey: key) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}
