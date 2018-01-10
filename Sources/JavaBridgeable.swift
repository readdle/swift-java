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