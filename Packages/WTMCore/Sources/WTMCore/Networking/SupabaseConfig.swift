import Foundation

/// Reads Supabase connection details injected into Info.plist by
/// Config/Debug.xcconfig / Config/Release.xcconfig (see Config/Secrets.xcconfig.example).
public enum SupabaseConfig {
    public static var url: URL {
        guard
            let string = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            !string.isEmpty,
            let url = URL(string: string)
        else {
            fatalError(
                "Missing SUPABASE_URL. Copy Config/Secrets.xcconfig.example to Config/Secrets.xcconfig and fill in your project's values."
            )
        }
        return url
    }

    public static var anonKey: String {
        guard
            let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
            !key.isEmpty
        else {
            fatalError(
                "Missing SUPABASE_ANON_KEY. Copy Config/Secrets.xcconfig.example to Config/Secrets.xcconfig and fill in your project's values."
            )
        }
        return key
    }
}
