//
//  JNIHelper.swift
//  jniBridge
//
//  Created by Andrew on 10/18/17.
//

import Foundation

fileprivate extension NSLock {
    
    func sync<T>(_ block: () throws -> T) throws -> T {
        self.lock()
        defer {
            self.unlock()
        }
        return try block()
    }
}
    
private var javaClasses = [String: jclass]()
private var javaMethods = [String: jmethodID]()
private var javaStaticMethods = [String: jmethodID]()
private var javaFields = [String: jmethodID]()

private let javaClassesLock = NSLock()
private let javaMethodLock = NSLock()
private let javaStaticMethodLock = NSLock()
private let javaFieldLock = NSLock()

public extension JNICore {
    
    public var TRUE: jboolean {
        return jboolean(JNI_TRUE)
    }
    
    public var FALSE: jboolean {
        return jboolean(JNI_FALSE)
    }
    
    public enum JNIError: Error {
        
        case classNotFoundException(String)
        case methodNotFoundException(String)
        case fieldNotFoundException(String)
        
        public func `throw`() {
            switch self {
            case .classNotFoundException(let message):
                assert(JNI.api.ThrowNew(JNI.env, ExceptionClass, "ClassNotFoundaException: \(message)") == 0)
            case .methodNotFoundException(let message):
                assert(JNI.api.ThrowNew(JNI.env, ExceptionClass, "MethodNotFoundException: \(message)") == 0)
            case .fieldNotFoundException(let message):
                assert(JNI.api.ThrowNew(JNI.env, ExceptionClass, "FieldNotFoundException: \(message)") == 0)
            }
            
        }
    }
    
    // MARK: Global cache functions
    public func getJavaClass(_ className: String) throws -> jclass {
        if let javaClass = javaClasses[className] {
            return javaClass
        }
        return try javaClassesLock.sync {
            if let javaClass = javaClasses[className] {
                return javaClass
            }
            guard let javaClass = JNI.GlobalFindClass(className) else {
                JNI.api.ExceptionClear(JNI.env)
                JNI.ExceptionReset()
                throw JNIError.classNotFoundException(className)
            }
            javaClasses[className] = javaClass
            return javaClass
        }
    }
    
    public func getJavaEmptyConstructor(forClass className: String) throws -> jmethodID {
        return try getJavaMethod(forClass: className, method: "<init>", sig: "()V")
    }
    
    public func getJavaMethod(forClass className: String, method: String, sig: String) throws -> jmethodID {
        let key = "\(className).\(method)\(sig)"
        let javaClass = try getJavaClass(className)
        if let methodID = javaMethods[key] {
            return methodID
        }
        return try javaMethodLock.sync {
            if let methodID = javaMethods[key] {
                return methodID
            }
            guard let javaMethodID = JNI.api.GetMethodID(JNI.env, javaClass, method, sig) else {
                JNI.api.ExceptionClear(JNI.env)
                JNI.ExceptionReset()
                throw JNIError.methodNotFoundException(key)
            }
            javaMethods[key] = javaMethodID
            return javaMethodID
        }
    }
    
    public func getStaticJavaMethod(forClass className: String, method: String, sig: String) throws -> jmethodID {
        let key = "\(className).\(method)\(sig)"
        let javaClass = try getJavaClass(className)
        if let methodID = javaStaticMethods[key] {
            return methodID
        }
        return try javaStaticMethodLock.sync {
            if let methodID = javaStaticMethods[key] {
                return methodID
            }
            guard let javaMethodID = JNI.api.GetStaticMethodID(JNI.env, javaClass, method, sig) else {
                JNI.api.ExceptionClear(JNI.env)
                JNI.ExceptionReset()
                throw JNIError.methodNotFoundException(key)
            }
            javaStaticMethods[key] = javaMethodID
            return javaMethodID
        }
    }
    
    public func getJavaField(forClass className: String, field: String, sig: String) throws -> jfieldID {
        let key = "\(className).\(field)\(sig)"
        let javaClass = try getJavaClass(className)
        if let fieldID = javaFields[key] {
            return fieldID
        }
        return try javaFieldLock.sync({
            if let fieldID = javaFields[key] {
                return fieldID
            }
            guard let fieldID = JNI.api.GetFieldID(JNI.env, javaClass, field, sig) else {
                JNI.api.ExceptionClear(JNI.env)
                JNI.ExceptionReset()
                throw JNIError.fieldNotFoundException(key)
            }
            javaFields[key] = fieldID
            return fieldID
            
        })
    }
    
    public func GlobalFindClass( _ name: String,
                                 _ file: StaticString = #file,
                                 _ line: Int = #line ) -> jclass? {
        guard let clazz: jclass = FindClass(name, file, line ) else {
            return nil
        }
        let result = api.NewGlobalRef(env, clazz)
        api.DeleteLocalRef(env, clazz)
        return result
    }
    
    // MARK: Constructors
    public func NewObject(_ clazz: jclass, methodID: jmethodID, args: [jvalue] = []) -> jobject? {
        return checkArgument(args: args, { argsPtr in
            api.NewObjectA(env, clazz, methodID, argsPtr)
        })
    }
    
    // MARK: Object methods
    public func CallBooleanMethod(_ object: jobject, methodID: jmethodID, args: [jvalue] = []) -> jboolean {
        return checkArgument(args: args, { argsPtr in
            api.CallBooleanMethodA(env, object, methodID, argsPtr)
        })
    }
    
    public func CallByteMethod(_ object: jobject, methodID: jmethodID, args: [jvalue] = []) -> jbyte {
        return checkArgument(args: args, { argsPtr in
            api.CallByteMethodA(env, object, methodID, argsPtr)
        })
    }
    
    public func CallShortMethod(_ object: jobject, methodID: jmethodID, args: [jvalue] = []) -> jshort {
        return checkArgument(args: args, { argsPtr in
            api.CallShortMethodA(env, object, methodID, argsPtr)
        })
    }
    
    public func CallIntMethod(_ object: jobject, methodID: jmethodID, args: [jvalue] = []) -> jint {
        return checkArgument(args: args, { argsPtr in
            api.CallIntMethodA(env, object, methodID, argsPtr)
        })
    }
    
    public func CallLongMethod(_ object: jobject, methodID: jmethodID, args: [jvalue] = []) -> jlong {
        return checkArgument(args: args, { argsPtr in
            api.CallLongMethodA(env, object, methodID, argsPtr)
        })
    }
    
    public func CallObjectMethod(_ object: jobject, methodID: jmethodID, args: [jvalue] = []) -> jobject? {
        return checkArgument(args: args, { argsPtr in
            api.CallObjectMethodA(env, object, methodID, argsPtr)
        })
    }
    
    // MARK: Static methods
    public func CallStaticBooleanMethod(_ clazz: jclass, methodID: jmethodID, args: [jvalue] = []) -> jboolean {
        return checkArgument(args: args, { argsPtr in
            api.CallStaticBooleanMethodA(env, clazz, methodID, argsPtr)
        })
    }
    
    public func CallStaticByteMethod(_ clazz: jclass, methodID: jmethodID, args: [jvalue] = []) -> jbyte {
        return checkArgument(args: args, { argsPtr in
            api.CallStaticByteMethodA(env, clazz, methodID, argsPtr)
        })
    }
    
    public func CallStaticShortMethod(_ clazz: jclass, methodID: jmethodID, args: [jvalue] = []) -> jshort {
        return checkArgument(args: args, { argsPtr in
            api.CallStaticShortMethodA(env, clazz, methodID, argsPtr)
        })
    }
    
    public func CallStaticIntMethod(_ clazz: jclass, methodID: jmethodID, args: [jvalue] = []) -> jint {
        return checkArgument(args: args, { argsPtr in
            api.CallStaticIntMethodA(env, clazz, methodID, argsPtr)
        })
    }
    
    public func CallStaticLongMethod(_ clazz: jclass, methodID: jmethodID, args: [jvalue] = []) -> jlong {
        return checkArgument(args: args, { argsPtr in
            api.CallStaticLongMethodA(env, clazz, methodID, argsPtr)
        })
    }
    
    public func CallStaticObjectMethod(_ clazz: jclass, methodID: jmethodID, args: [jvalue] = []) -> jobject? {
        return checkArgument(args: args, { argsPtr in
            api.CallStaticObjectMethodA(env, clazz, methodID, argsPtr)
        })
    }
    
    public func dumpReferenceTables() {
        JNI.api.CallStaticVoidMethodA(JNI.env, VMDebugClass, VMDebugDumpReferenceTablesMethod, nil)
        JNI.api.ExceptionClear(JNI.env)
        JNI.ExceptionReset()
    }
    
    private func checkArgument<Result>(args: [jvalue], _ block: (_ argsPtr: UnsafePointer<jvalue>?) -> Result) -> Result {
        if args.count > 0 {
            var args = args
            return withUnsafePointer(to: &args[0]) { argsPtr in
                return block(argsPtr)
            }
        }
        else {
            return block(nil)
        }
    }
    
    // MARK: New API
    public func CallObjectMethod(_ object: jobject, _ methodID: jmethodID, _ args: JNIArgumentProtocol...) -> jobject? {
        return checkArgumentAndWrap(args: args, { argsPtr in
            api.CallObjectMethodA(env, object, methodID, argsPtr)
        })
    }

    public func CallStaticObjectMethod(_ clazz: jclass, _ methodID: jmethodID, _ args: JNIArgumentProtocol...) -> jobject? {
        return checkArgumentAndWrap(args: args, { argsPtr in
            api.CallStaticObjectMethodA(env, clazz, methodID, argsPtr)
        })
    }

    public func CallVoidMethod(_ object: jobject, _ methodID: jmethodID, _ args: JNIArgumentProtocol...) {
        checkArgumentAndWrap(args: args, { argsPtr in
            api.CallVoidMethodA(env, object, methodID, argsPtr)
        })
    }
    
    public func CallStaticVoidMethod(_ clazz: jclass, _ methodID: jmethodID, _ args: JNIArgumentProtocol...) {
        checkArgumentAndWrap(args: args, { argsPtr in
            api.CallStaticVoidMethodA(env, clazz, methodID, argsPtr)
        })
    }
    
    private func checkArgumentAndWrap<Result>(args: [JNIArgumentProtocol], _ block: (_ argsPtr: UnsafePointer<jvalue>?) -> Result) -> Result {
        if args.count > 0 {
            var locals = [jobject]()
            var argsValues = args.map({ $0.value(locals: &locals) })
            return withUnsafePointer(to: &argsValues[0]) { argsPtr in
                defer {
                    _ = JNI.check(Void.self, &locals)
                }
                return block(argsPtr)
            }
        }
        else {
            return block(nil)
        }
    }

    public static func getJavaClassname(javaObject: jobject?) -> String {
        let cls = JNI.api.GetObjectClass(JNI.env, javaObject)
        let javaClassName = JNI.api.CallObjectMethodA(JNI.env, cls, ClassGetNameMethod, nil)
        return String(javaObject: javaClassName).replacingOccurrences(of: ".", with: "/")
    }
    
}

extension String {

    public init( javaObject: jobject? ) {
        var isCopy: jboolean = 0
        if let javaObject: jobject = javaObject, let value: UnsafePointer<jchar> = JNI.api.GetStringChars( JNI.env, javaObject, &isCopy ) {
            self.init( utf16CodeUnits: value, count: Int(JNI.api.GetStringLength( JNI.env, javaObject )) )
            if isCopy != 0 || true {
                JNI.api.ReleaseStringChars( JNI.env, javaObject, value ) ////
            }
        }
        else {
            self.init()
        }
    }

    public func localJavaObject( _ locals: UnsafeMutablePointer<[jobject]> ) -> jobject? {
        if let javaObject: jstring = Array(utf16).withUnsafeBufferPointer({
            JNI.env?.pointee?.pointee.NewString(JNI.env, $0.baseAddress, jsize($0.count))
        }) {
            locals.pointee.append( javaObject )
            return javaObject
        }
        return nil
    }
}
