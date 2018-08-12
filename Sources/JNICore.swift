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

@_silgen_name("JNI_OnLoad")
public func JNI_OnLoad( jvm: UnsafeMutablePointer<JavaVM?>, ptr: UnsafeRawPointer ) -> jint {
    JNI.jvm = jvm
    let env: UnsafeMutablePointer<JNIEnv?>? = JNI.GetEnv()
    JNI.api = env!.pointee!.pointee
    JNI.envCache[JNI.threadKey] = env
#if os(Android)
    DispatchQueue.setThreadDetachCallback( JNI_DetachCurrentThread )
#endif

    // Save ContextClassLoader for FindClass usage
    // When a thread is attached to the VM, the context class loader is the bootstrap loader.
    // https://docs.oracle.com/javase/1.5.0/docs/guide/jni/spec/invocation.html
    // https://developer.android.com/training/articles/perf-jni.html#faq_FindClass
    let threadClass = JNI.api.FindClass(env, "java/lang/Thread")
    let currentThreadMethodID = JNI.api.GetStaticMethodID(env, threadClass, "currentThread", "()Ljava/lang/Thread;")
    let getContextClassLoaderMethodID = JNI.api.GetMethodID(env, threadClass, "getContextClassLoader", "()Ljava/lang/ClassLoader;")
    let currentThread = JNI.api.CallStaticObjectMethodA(env, threadClass, currentThreadMethodID, nil)
    JNI.classLoader = JNI.api.NewGlobalRef(env, JNI.api.CallObjectMethodA(env, currentThread, getContextClassLoaderMethodID, nil))
    let classLoaderClass = JNI.api.FindClass(env, "java/lang/ClassLoader")
    JNI.loadClassMethodID = JNI.api.GetMethodID(env, classLoaderClass, "loadClass", "(Ljava/lang/String;)Ljava/lang/Class;")

    return jint(JNI_VERSION_1_6)
}

public func JNI_DetachCurrentThread() {
    _ = JNI.jvm?.pointee?.pointee.DetachCurrentThread( JNI.jvm )
    JNI.envLock.lock()
    JNI.envCache[JNI.threadKey] = nil
    JNI.envLock.unlock()
}

public let JNI = JNICore()

open class JNICore {

    open var jvm: UnsafeMutablePointer<JavaVM?>?
    open var api: JNINativeInterface_!
    open var classLoader: jclass!
    open var loadClassMethodID: jmethodID!

    open var envCache = [pthread_t:UnsafeMutablePointer<JNIEnv?>?]()
    fileprivate let envLock = NSLock()

    open var threadKey: pthread_t { return pthread_self() }

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

    open func AttachCurrentThread() -> UnsafeMutablePointer<JNIEnv?>? {
        var tenv: UnsafeMutablePointer<JNIEnv?>?
        if withPointerToRawPointer(to: &tenv, {
            self.jvm?.pointee?.pointee.AttachCurrentThread( self.jvm, $0, nil )
        } ) != jint(JNI_OK) {
            report( "Could not attach to background jvm" )
        }
        return tenv
    }

    open func report( _ msg: String, _ file: StaticString = #file, _ line: Int = #line ) {
        NSLog( "\(msg) - at \(file):\(line)" )
        if api?.ExceptionCheck( env ) != 0 {
            api.ExceptionDescribe( env )
        }
    }

    private func withPointerToRawPointer<T, Result>(to arg: inout T,
                                                    _ body: @escaping (UnsafeMutablePointer<UnsafeMutableRawPointer?>) throws -> Result) rethrows -> Result {
        return try withUnsafeMutablePointer(to: &arg) {
            try $0.withMemoryRebound(to: UnsafeMutableRawPointer?.self, capacity: 1) {
                try body( $0 )
            }
        }
    }

    open func GetEnv() -> UnsafeMutablePointer<JNIEnv?>? {
        var tenv: UnsafeMutablePointer<JNIEnv?>?
        if withPointerToRawPointer(to: &tenv, {
            JNI.jvm?.pointee?.pointee.GetEnv(JNI.jvm, $0, jint(JNI_VERSION_1_6) )
        } ) != jint(JNI_OK) {
            report( "Unable to get initial JNIEnv" )
        }
        return tenv
    }

    open func FindClass(_ name: String, _ file: StaticString = #file, _ line: Int = #line) -> jclass? {
        ExceptionReset()
        let clazz: jclass? = JNI.CallObjectMethod(classLoader, loadClassMethodID, name)
        if clazz == nil {
            report( "Could not find class \(name)", file, line )
        }
        return clazz
    }

    open func DeleteLocalRef( _ local: jobject? ) {
        if local != nil {
            api.DeleteLocalRef( env, local )
        }
    }

    private var thrownCache = [pthread_t: jthrowable]()
    private let thrownLock = NSLock()

    open func check<T>( _ result: T, _ locals: UnsafeMutablePointer<[jobject]>, removeLast: Bool = false, _ file: StaticString = #file, _ line: Int = #line ) -> T {
        if removeLast && locals.pointee.count != 0 {
            locals.pointee.removeLast()
        }
        for local in locals.pointee {
            DeleteLocalRef( local )
        }
        if api.ExceptionCheck( env ) != 0, let throwable: jthrowable = api.ExceptionOccurred( env ) {
            report( "Exception occured", file, line )
            thrownLock.lock()
            thrownCache[threadKey] = throwable
            thrownLock.unlock()
            api.ExceptionClear( env )
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
