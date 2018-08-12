import Foundation

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

extension Array: JavaBridgeable {}
extension Dictionary: JavaBridgeable {}
extension Set: JavaBridgeable {}

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
        guard let javaObject: jstring = Array(utf16).withUnsafeBufferPointer({
            JNI.api.NewString(JNI.env, $0.baseAddress, jsize($0.count))
        }) else {
            throw JavaCodingError.cantCreateObject("String")
        }
        return javaObject
    }

}

// Error can't implement JavaBridgeable protocol
private let javaExceptionClass = JNI.GlobalFindClass("java/lang/Exception")!
private let javaExceptionConstructor = try! JNI.getJavaMethod(forClass: "java/lang/Exception", method: "<init>", sig: "(Ljava/lang/String;)V")
private let javaExceptionGetMessage = try! JNI.getJavaMethod(forClass: "java/lang/Exception", method: "getMessage", sig: "()Ljava/lang/String;")

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

extension Int: JavaBridgeable {

    public static func from(javaObject: jobject) throws -> Int {
        return Int(JNI.CallIntMethod(javaObject, methodID: NumberIntValueMethod))
    }

    public func javaObject() throws -> jobject {
        // jint for macOS and Android different, that's why we make cast to jint() here
        let args = [jvalue(i: jint(self))]
        return JNI.NewObject(IntegerClass, methodID: IntegerConstructor, args: args)!
    }

}

extension Int8: JavaBridgeable {

    public static func from(javaObject: jobject) throws -> Int8 {
        return JNI.CallByteMethod(javaObject, methodID: NumberByteValueMethod)
    }

    public func javaObject() throws -> jobject {
        let args = [jvalue(b: self)]
        return JNI.NewObject(ByteClass, methodID: ByteConstructor, args: args)!
    }

}

extension Int16: JavaBridgeable {

    public static func from(javaObject: jobject) throws -> Int16 {
        return JNI.CallShortMethod(javaObject, methodID: NumberShortValueMethod)
    }

    public func javaObject() throws -> jobject {
        let args = [jvalue(s: self)]
        return JNI.NewObject(ShortClass, methodID: ShortConstructor, args: args)!
    }

}

extension Int32: JavaBridgeable {

    public static func from(javaObject: jobject) throws -> Int32 {
        return Int32(JNI.CallIntMethod(javaObject, methodID: NumberIntValueMethod))
    }

    public func javaObject() throws -> jobject {
        let args = [jvalue(i: jint(self))]
        return JNI.NewObject(IntegerClass, methodID: IntegerConstructor, args: args)!
    }

}

extension Int64: JavaBridgeable {

    public static func from(javaObject: jobject) throws -> Int64 {
        return JNI.CallLongMethod(javaObject, methodID: NumberLongValueMethod)
    }

    public func javaObject() throws -> jobject {
        let args = [jvalue(j: self)]
        return JNI.NewObject(LongClass, methodID: LongConstructor, args: args)!
    }

}

extension UInt: JavaBridgeable {

    public static func from(javaObject: jobject) throws -> UInt {
        return UInt(JNI.CallLongMethod(javaObject, methodID: NumberLongValueMethod))
    }

    public func javaObject() throws -> jobject {
        let args = [jvalue(j: Int64(self))]
        return JNI.NewObject(LongClass, methodID: LongConstructor, args: args)!
    }

}

extension UInt8: JavaBridgeable {

    public static func from(javaObject: jobject) throws -> UInt8 {
        return UInt8(JNI.CallShortMethod(javaObject, methodID: NumberShortValueMethod))
    }

    public func javaObject() throws -> jobject {
        let args = [jvalue(s: Int16(self))]
        return JNI.NewObject(ShortClass, methodID: ShortConstructor, args: args)!
    }

}

extension UInt16: JavaBridgeable {

    public static func from(javaObject: jobject) throws -> UInt16 {
        return UInt16(JNI.CallIntMethod(javaObject, methodID: NumberIntValueMethod))
    }

    public func javaObject() throws -> jobject {
        let args = [jvalue(i: jint(self))]
        return JNI.NewObject(IntegerClass, methodID: IntegerConstructor, args: args)!
    }

}

extension UInt32: JavaBridgeable {

    public static func from(javaObject: jobject) throws -> UInt32 {
        return UInt32(JNI.CallLongMethod(javaObject, methodID: NumberLongValueMethod))
    }

    public func javaObject() throws -> jobject {
        let args = [jvalue(j: Int64(self))]
        return JNI.NewObject(LongClass, methodID: LongConstructor, args: args)!
    }

}

extension UInt64: JavaBridgeable {

    public static func from(javaObject: jobject) throws -> UInt64 {
        let javaString = JNI.CallObjectMethod(javaObject, methodID: ObjectToStringMethod)
        defer {
            JNI.api.DeleteLocalRef(JNI.env, javaString)
        }
        let stringRepresentation = String(javaObject: javaString)
        return UInt64(stringRepresentation)!
    }

    public func javaObject() throws -> jobject {
        var javaString = try String(self).javaObject()
        defer {
            JNI.api.DeleteLocalRef(JNI.env, javaString)
        }
        let args = [jvalue(l: javaString)]
        return JNI.NewObject(BigIntegerClass, methodID: BigIntegerConstructor, args: args)!
    }

}

extension Float: JavaBridgeable {

    public static func from(javaObject: jobject) throws -> Float {
        return JNI.api.CallFloatMethodA(JNI.env, javaObject, NumberFloatValueMethod, nil)
    }

    public func javaObject() throws -> jobject {
        let args = [jvalue(f: self)]
        return JNI.NewObject(FloatClass, methodID: FloatConstructor, args: args)!
    }

}

extension Double: JavaBridgeable {

    public static func from(javaObject: jobject) throws -> Double {
        return JNI.api.CallDoubleMethodA(JNI.env, javaObject, NumberDoubleValueMethod, nil)
    }

    public func javaObject() throws -> jobject {
        let args = [jvalue(d: self)]
        return JNI.NewObject(DoubleClass, methodID: DoubleConstructor, args: args)!
    }

}

extension Bool: JavaBridgeable {

    public static func from(javaObject: jobject) throws -> Bool {
        return (JNI.CallBooleanMethod(javaObject, methodID: NumberBooleanValueMethod) == JNI.TRUE)
    }

    public func javaObject() throws -> jobject {
        let args = [jvalue(z: self ? JNI.TRUE : JNI.FALSE)]
        return JNI.NewObject(BooleanClass, methodID: BooleanConstructor, args: args)!
    }

}

extension Date: JavaBridgeable {

    public static func from(javaObject: jobject) throws -> Date {
        let timeInterval = JNI.api.CallLongMethodA(JNI.env, javaObject, DateGetTimeMethod, nil)
        // Java save TimeInterval in UInt64 milliseconds
        return Date(timeIntervalSince1970: TimeInterval(timeInterval) / 1000.0)
    }

    public func javaObject() throws -> jobject {
        let args = [jvalue(j: jlong(self.timeIntervalSince1970 * 1000))]
        return JNI.NewObject(DateClass, methodID: DateConstructor, args: args)!
    }

}

extension URL: JavaBridgeable {

    public static func from(javaObject: jobject) throws -> URL {
        let javaString = JNI.api.CallObjectMethodA(JNI.env, javaObject, ObjectToStringMethod, nil)
        defer {
            JNI.api.DeleteLocalRef(JNI.env, javaString)
        }
        return URL(string: String(javaObject: javaString))!
    }

    public func javaObject() throws -> jobject {
        let javaString = try self.absoluteString.javaObject()
        defer {
            JNI.api.DeleteLocalRef(JNI.env, javaString)
        }
        let args = [jvalue(l: javaString)]
        return JNI.CallStaticObjectMethod(UriClass, methodID: UriConstructor!, args: args)!
    }

}

extension Data: JavaBridgeable {

    public static func from(javaObject: jobject) throws -> Data {
        let byteArray = JNI.CallObjectMethod(javaObject, methodID: ByteBufferArray)
        guard let pointer = JNI.api.GetByteArrayElements(JNI.env, byteArray, nil) else {
            throw JavaCodingError.cantFindObject("ByteBuffer")
        }
        let length = JNI.api.GetArrayLength(JNI.env, byteArray)
        defer {
            JNI.api.ReleaseByteArrayElements(JNI.env, byteArray, pointer, 0)
        }
        return Data(bytes: pointer, count: length)
    }

    public func javaObject() throws -> jobject {
        let byteArray = JNI.api.NewByteArray(JNI.env, self.count)!
        self.withUnsafeBytes({ (pointer: UnsafePointer<Int8>) -> Void in
            JNI.api.SetByteArrayRegion(JNI.env, byteArray, 0, self.count, pointer)
        })
        return JNI.CallStaticObjectMethod(ByteBufferClass, methodID: ByteBufferWrap, args: [jvalue(l: byteArray)])!
    }

}
