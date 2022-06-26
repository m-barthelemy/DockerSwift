import Foundation


extension UInt64 {
    /// Creates a bytes amount, in MegaBytes
    public static func mb(_ value: Int) -> UInt64 {
        return UInt64(value * 1024 * 1024)
    }
    
    /// Creates a bytes amount, in GigaBytes
    public static func gb(_ value: Int) -> UInt64 {
        return mb(value * 1024)
    }
    
    /// Convert the provided number of seconds to nanoseconds
    public static func milliseconds(_ value: Int) -> UInt64 {
        return UInt64(value * 1_000_000)
    }
    
    /// Convert the provided number of milliseconds to nanoseconds
    public static func seconds(_ value: Int) -> UInt64 {
        return UInt64(value * 1_000_000_000)
    }
}

extension Int64 {
    /// Creates a bytes amount, in MegaBytes
    public static func mb(_ value: Int) -> Int64 {
        return Int64(value * 1024 * 1024)
    }
    
    /// Creates a bytes amount, in GigaBytes
    public static func gb(_ value: Int) -> Int64 {
        return mb(value * 1024)
    }
}
