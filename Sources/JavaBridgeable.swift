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
extension Array: JavaBridgeable {}
extension Dictionary: JavaBridgeable {}
extension Set: JavaBridgeable {}
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
        guard let javaObject: jstring =  Array(utf16).withUnsafeBufferPointer({
            JNI.api.NewString(JNI.env, $0.baseAddress, jsize($0.count))
        }) else {
            throw JavaCodingError.cantCreateObject("String")
        }
        return javaObject
    }

}

// Error can't implement JavaBridgeable protocol
fileprivate let javaExceptionClass = JNI.GlobalFindClass("java/lang/Exception")!
fileprivate let javaExceptionConstructor = try! JNI.getJavaMethod(forClass: "java/lang/Exception", method: "<init>", sig: "(Ljava/lang/String;)V")
fileprivate let javaExceptionGetMessage = try! JNI.getJavaMethod(forClass: "java/lang/Exception", method: "getMessage", sig: "()Ljava/lang/String;")

extension Error {

    public static func from(javaObject: jobject) throws -> Error {
        let domain: String
        let code: String
        if let javaMessage = JNI.CallObjectMethod(javaObject, methodID: javaExceptionGetMessage) {
            let message = try String.from(javaObject: javaMessage)
            let parts = message.split(separator: ":")
            domain = parts.count > 0 ? String(parts[0]) : "JavaException"
            code = parts.count > 1 ? String(parts[1]) : "0"
        }
        else {
            domain = "JavaException"
            code = "0"
        }
        return NSError(domain: domain, code: Int(code) ?? 0)
    }

    public func javaObject() throws -> jobject {
        let message: String
        if let nsError = self as? NSError {
            message = "\(nsError.domain):\(nsError.code)"
        }
        else {
            message = String(reflecting: type(of: self))
        }

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
