//
//  JavaJNI.swift
//  SwiftJava
//
//  Created by John Holdsworth on 13/07/2016.
//  Copyright (c) 2016 John Holdsworth. All rights reserved.
//
//  Basic JNI functionality notably initialising a JVM on Unix
//  as well as maintaining cache of currently attached JNI.env
//

@_exported import CJavaVM
import Dispatch
import Foundation

public var JNI: JNICore {
    return JNICore.instance
}

open class JNICore {

    public private(set) static var instance: JNICore!

    open let jvm: UnsafeMutablePointer<JavaVM?>
    open let api: JNINativeInterface_
    open let classLoader: jclass
    open let loadClassMethodID: jmethodID

    open var envCache = [pthread_t: UnsafeMutablePointer<JNIEnv?>?]()
    fileprivate let envLock = NSLock()

    open var threadKey: pthread_t {
        return pthread_self()
    }

    open var env: UnsafeMutablePointer<JNIEnv?>? {
        let currentThread = threadKey
        if let env = envCache[currentThread] {
            return env
        }

        let env = AttachCurrentThread()
        envLock.lock()
        envCache[currentThread] = env
        envLock.unlock()
        return env
    }

    public init(withJVM javaVM: UnsafeMutablePointer<JavaVM?>) {
        var env: UnsafeMutablePointer<JNIEnv?>?

        if withUnsafeMutablePointer(to: &env, {
            $0.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 1) {
                javaVM.pointee?.pointee.GetEnv(javaVM, $0, jint(JNI_VERSION_1_6))
            }
        }) != jint(JNI_OK) {
            fatalError("Unable to get initial JNIEnv")
        }

        let localThreadKey = pthread_self()

        self.jvm = javaVM
        self.api = env!.pointee!.pointee
        self.envCache[localThreadKey] = env
#if os(Android)
        DispatchQueue.setThreadDetachCallback(JNI_DetachCurrentThread)
#endif

        // Save ContextClassLoader for FindClass usage
        // When a thread is attached to the VM, the context class loader is the bootstrap loader.
        // https://docs.oracle.com/javase/1.5.0/docs/guide/jni/spec/invocation.html
        // https://developer.android.com/training/articles/perf-jni.html#faq_FindClass
        let threadClass = api.FindClass(env, "java/lang/Thread")
        let currentThreadMethodID = api.GetStaticMethodID(env, threadClass, "currentThread", "()Ljava/lang/Thread;")
        let getContextClassLoaderMethodID = api.GetMethodID(env, threadClass, "getContextClassLoader", "()Ljava/lang/ClassLoader;")
        let currentThread = api.CallStaticObjectMethodA(env, threadClass, currentThreadMethodID, nil)
        guard let classLoader = api.NewGlobalRef(env, api.CallObjectMethodA(env, currentThread, getContextClassLoaderMethodID, nil)),
              let classLoaderClass = api.FindClass(env, "java/lang/ClassLoader"),
              let loadClassMethodID = api.GetMethodID(env, classLoaderClass, "loadClass", "(Ljava/lang/String;)Ljava/lang/Class;") else {
            fatalError()
        }

        self.classLoader = classLoader
        self.loadClassMethodID = loadClassMethodID

        JNICore.instance = self
    }

    open func AttachCurrentThread() -> UnsafeMutablePointer<JNIEnv?>? {
        var tenv: UnsafeMutablePointer<JNIEnv?>?
        if withPointerToRawPointer(to: &tenv, {
            self.jvm.pointee?.pointee.AttachCurrentThread(self.jvm, $0, nil)
        }) != jint(JNI_OK) {
            report("Could not attach to background jvm")
        }
        return tenv
    }

    open func report(_ msg: String, _ file: StaticString = #file, _ line: Int = #line) {
        NSLog("\(msg) - at \(file):\(line)")
        if api.ExceptionCheck(env) != 0 {
            api.ExceptionDescribe(env)
        }
    }

    private func withPointerToRawPointer<T, Result>(to arg: inout T,
                                                    _ body: @escaping (UnsafeMutablePointer<UnsafeMutableRawPointer?>) throws -> Result) rethrows -> Result {
        return try withUnsafeMutablePointer(to: &arg) {
            try $0.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 1) {
                try body($0)
            }
        }
    }

    open func GetEnv() -> UnsafeMutablePointer<JNIEnv?>? {
        var tenv: UnsafeMutablePointer<JNIEnv?>?
        if withPointerToRawPointer(to: &tenv, {
            self.jvm.pointee?.pointee.GetEnv(self.jvm, $0, jint(JNI_VERSION_1_6))
        }) != jint(JNI_OK) {
            report("Unable to get initial JNIEnv")
        }
        return tenv
    }

    open func FindClass(_ name: String, _ file: StaticString = #file, _ line: Int = #line) -> jclass? {
        ExceptionReset()
        let clazz: jclass? = CallObjectMethod(classLoader, loadClassMethodID, name)
        if clazz == nil {
            report("Could not find class \(name)", file, line)
        }
        return clazz
    }

    open func DeleteLocalRef(_ local: jobject?) {
        if local != nil {
            api.DeleteLocalRef(env, local)
        }
    }

    private var thrownCache = [pthread_t: jthrowable]()
    private let thrownLock = NSLock()

    open func check<T>(_ result: T, _ locals: UnsafeMutablePointer<[jobject]>, removeLast: Bool = false, _ file: StaticString = #file, _ line: Int = #line) -> T {
        if removeLast && locals.pointee.count != 0 {
            locals.pointee.removeLast()
        }
        for local in locals.pointee {
            DeleteLocalRef(local)
        }
        if api.ExceptionCheck(env) != 0, let throwable: jthrowable = api.ExceptionOccurred(env) {
            report("Exception occured", file, line)
            thrownLock.lock()
            thrownCache[threadKey] = throwable
            thrownLock.unlock()
            api.ExceptionClear(env)
        }
        return result
    }

    open func ExceptionCheck() -> jthrowable? {
        let currentThread: pthread_t = threadKey
        if let throwable: jthrowable = thrownCache[currentThread] {
            thrownLock.lock()
            thrownCache.removeValue(forKey: currentThread)
            thrownLock.unlock()
            return throwable
        }
        return nil
    }

    open func ExceptionReset() {
        if let throwable = ExceptionCheck() {
            report("Left over exception \(throwable)")
            // TODO: make print stacktrace method
        }
    }

}

// Callbacks for C API
public func JNI_DetachCurrentThread() {
    _ = JNI.jvm.pointee?.pointee.DetachCurrentThread(JNI.jvm)
    JNI.envLock.lock()
    JNI.envCache[JNI.threadKey] = nil
    JNI.envLock.unlock()
}
