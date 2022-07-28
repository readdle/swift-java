import Foundation
import java_swift
import JavaCoder

public protocol JavaBridgeable: Codable {
    
    static func from(javaObject: jobject) throws -> Self

    func javaObject() throws -> jobject
}

extension JavaBridgeable {

    // Decoding SwiftValue type with JavaCoder
    public static func from(javaObject: jobject) throws -> Self {
        // ignore forPackage for basic impl
        return try JavaDecoder(forPackage: "").decode(Self.self, from: javaObject)
    }

    // Encoding SwiftValue type with JavaCoder
    public func javaObject() throws -> jobject {
        // ignore forPackage for basic impl
        return try JavaEncoder(forPackage: "").encode(self)
    }
    
}

extension Bool: JavaBridgeable {}
extension Int: JavaBridgeable {}
extension Int8: JavaBridgeable {}
extension Int16: JavaBridgeable {}
extension Int32: JavaBridgeable {}
extension Int64: JavaBridgeable {}
extension UInt: JavaBridgeable {}
extension UInt8: JavaBridgeable {}
extension UInt16: JavaBridgeable {}
extension UInt32: JavaBridgeable {}
extension UInt64: JavaBridgeable {}
extension Float: JavaBridgeable {}
extension Double: JavaBridgeable {}
extension Dictionary: JavaBridgeable where Key: Codable, Value: Codable {}
extension Set: JavaBridgeable where Element: Codable {}
extension Date: JavaBridgeable {}
extension Data: JavaBridgeable {}
extension URL: JavaBridgeable {}

extension String: JavaBridgeable {

    public static func from(javaObject: jobject) throws -> String {
        var isCopy: jboolean = 0
        if let chars = JNI.api.GetStringChars( JNI.env, javaObject, &isCopy) {
            defer {
                if isCopy != 0 {
                    JNI.api.ReleaseStringChars( JNI.env, javaObject, chars)
                }
            }
            return String(utf16CodeUnits: chars, count: Int(JNI.api.GetStringLength(JNI.env, javaObject)))
        }
        else {
            throw JavaCodingError.cantCreateObject("String")
        }
    }

    public func javaObject() throws -> jobject {
        guard let javaObject: jstring = self.withCString ({ ptr in
            JNI.api.NewStringUTF(JNI.env, ptr)
        }) else {
            throw JavaCodingError.cantCreateObject("String")
        }
        return javaObject
    }

}

// Error can't implement JavaBridgeable protocol
fileprivate let javaExceptionClass = JNI.GlobalFindClass("java/lang/Exception")!
fileprivate let javaExceptionConstructor = try! JNI.getJavaMethod(forClass: "java/lang/Exception", method: "<init>", sig: "(Ljava/lang/String;)V")

fileprivate let JavaErrorMessageKey = "JavaErrorMessageKey"
fileprivate let JavaErrorStackTrace = "JavaErrorStackTrace"

extension Error {

    public static var javaErrorMessageKey: String {
        return JavaErrorMessageKey
    }

    public static var javaErrorStackTrace: String {
        return JavaErrorStackTrace
    }

    public static func from(javaObject: jobject) throws -> Error {
        let throwable = Throwable(javaObject: javaObject)
        let className = throwable.className()
        let message = throwable.getMessage()
        let lastStackTrace = throwable.lastStackTraceString()
        let userInfo: [String: Any] = [javaErrorMessageKey: message ?? "unavailable",
                                       javaErrorStackTrace: lastStackTrace ?? "unavailable"]

        // Try extract error according to Error.javaObject()
        if let javaMessage = message {
            let parts = javaMessage.split(separator: ":")
            if parts.count > 1 {
               let domain = String(parts[0])
               let codeString = String(parts[1])
               if let code = Int(codeString) {
                   return NSError(domain: domain, code: code, userInfo: userInfo)
               }
            }
        }

        // Plan B
        let domain = className
        let code = 0
        return NSError(domain: domain, code: code, userInfo: userInfo)
    }

}

#if !HIDE_ERROR_JAVA_BRIDGEABLE
extension Error {
    public func javaObject() throws -> jobject {
        let nsError = self as NSError
        let message = "\(nsError.domain):\(nsError.code)"
        guard let javaObject = JNI.NewObject(javaExceptionClass, methodID: javaExceptionConstructor, args: [jvalue(l: try message.javaObject())]) else {
            throw JavaCodingError.cantCreateObject("java/lang/Exception")
        }
        return javaObject
    }
}

extension Error where Self: RawRepresentable, Self.RawValue: SignedInteger {

    public func javaObject() throws -> jobject {
        let domain = String(reflecting: type(of: self))
        let code: Int = numericCast(self.rawValue)
        let message = try "\(domain):\(code)".javaObject()
        guard let javaObject = JNI.NewObject(javaExceptionClass, methodID: javaExceptionConstructor, args: [jvalue(l: message)]) else {
            throw JavaCodingError.cantCreateObject("java/lang/Exception")
        }
        return javaObject
    }
}

extension Error where Self: RawRepresentable, Self.RawValue: UnsignedInteger {

    public func javaObject() throws -> jobject {
        let domain = String(reflecting: type(of: self))
        let code: Int = numericCast(self.rawValue)
        let message = try "\(domain):\(code)".javaObject()
        guard let javaObject = JNI.NewObject(javaExceptionClass, methodID: javaExceptionConstructor, args: [jvalue(l: message)]) else {
            throw JavaCodingError.cantCreateObject("java/lang/Exception")
        }
        return javaObject
    }
}
#endif
