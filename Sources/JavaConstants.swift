//
// Created by Andrew on 2/10/18.
//

import Foundation

// MARK: Java Classnames
let ObjectClassname = "java/lang/Object"
let ClassClassname = "java/lang/Class"
var IntegerClassname = "java/lang/Integer"
var ByteClassname = "java/lang/Byte"
var ShortClassname = "java/lang/Short"
var LongClassname = "java/lang/Long"
var BigIntegerClassname = "java/math/BigInteger"
var BooleanClassname = "java/lang/Boolean"
var StringClassname = "java/lang/String"
var ArrayListClassname = "java/util/ArrayList"
let HashMapClassname = "java/util/HashMap"
let SetClassname = "java/util/Set"
let UriClassname = "android/net/Uri"
let DateClassname = "java/util/Date"
let HashSetClassname = "java/util/HashSet"
let ByteBufferClassname = "java/nio/ByteBuffer"
let FloatClassname = "java/lang/Float"
let DoubleClassname = "java/lang/Double"

// MARK: Java Classes
var IntegerClass = try! JNI.getJavaClass("java/lang/Integer")
var ByteClass = try! JNI.getJavaClass("java/lang/Byte")
var ShortClass = try! JNI.getJavaClass("java/lang/Short")
var LongClass = try! JNI.getJavaClass("java/lang/Long")
var BigIntegerClass = try! JNI.getJavaClass("java/math/BigInteger")
var BooleanClass = try! JNI.getJavaClass("java/lang/Boolean")
var StringClass = try! JNI.getJavaClass("java/lang/String")
let ExceptionClass = try! JNI.getJavaClass("java/lang/Exception")
let UriClass = try! JNI.getJavaClass("android/net/Uri")
let DateClass = try! JNI.getJavaClass("java/util/Date")
let VMDebugClass = try! JNI.getJavaClass("dalvik/system/VMDebug")
let HashSetClass = try! JNI.getJavaClass("java/util/HashSet")
let ByteBufferClass = try! JNI.getJavaClass("java/nio/ByteBuffer")
let FloatClass = try! JNI.getJavaClass("java/lang/Float")
let DoubleClass = try! JNI.getJavaClass("java/lang/Double")

// MARK: Java methods
let UriConstructor = JNI.api.GetStaticMethodID(JNI.env, UriClass, "parse", "(Ljava/lang/String;)Landroid/net/Uri;")
let DateConstructor = try! JNI.getJavaMethod(forClass: "java/util/Date", method: "<init>", sig: "(J)V")
let IntegerConstructor = try! JNI.getJavaMethod(forClass: IntegerClassname, method: "<init>", sig: "(I)V")
let ByteConstructor = try! JNI.getJavaMethod(forClass: ByteClassname, method: "<init>", sig: "(B)V")
let ShortConstructor = try! JNI.getJavaMethod(forClass: ShortClassname, method: "<init>", sig: "(S)V")
let LongConstructor = try! JNI.getJavaMethod(forClass: LongClassname, method: "<init>", sig: "(J)V")
let BigIntegerConstructor = try! JNI.getJavaMethod(forClass: BigIntegerClassname, method: "<init>", sig: "(Ljava/lang/String;)V")
let BooleanConstructor = try! JNI.getJavaMethod(forClass: BooleanClassname, method: "<init>", sig: "(Z)V")
let FloatConstructor = try! JNI.getJavaMethod(forClass: FloatClassname, method: "<init>", sig: "(F)V")
let DoubleConstructor = try! JNI.getJavaMethod(forClass: DoubleClassname, method: "<init>", sig: "(D)V")

let ObjectToStringMethod = try! JNI.getJavaMethod(forClass: "java/lang/Object", method: "toString", sig: "()Ljava/lang/String;")
let ClassGetNameMethod = try! JNI.getJavaMethod(forClass: ClassClassname, method: "getName", sig: "()L\(StringClassname);")
let ClassGetFieldMethod = try! JNI.getJavaMethod(forClass: ClassClassname, method: "getField", sig: "(Ljava/lang/String;)Ljava/lang/reflect/Field;")
let FieldGetTypedMethod = try! JNI.getJavaMethod(forClass: "java/lang/reflect/Field", method: "getType", sig: "()L\(ClassClassname);")
let NumberByteValueMethod = try! JNI.getJavaMethod(forClass: "java/lang/Number", method: "byteValue", sig: "()B")
let NumberShortValueMethod = try! JNI.getJavaMethod(forClass: "java/lang/Number", method: "shortValue", sig: "()S")
let NumberIntValueMethod = try! JNI.getJavaMethod(forClass: "java/lang/Number", method: "intValue", sig: "()I")
let NumberLongValueMethod = try! JNI.getJavaMethod(forClass: "java/lang/Number", method: "longValue", sig: "()J")
let NumberFloatValueMethod = try! JNI.getJavaMethod(forClass: "java/lang/Number", method: "floatValue", sig: "()F")
let NumberDoubleValueMethod = try! JNI.getJavaMethod(forClass: "java/lang/Number", method: "doubleValue", sig: "()D")
let NumberBooleanValueMethod = try! JNI.getJavaMethod(forClass: "java/lang/Boolean", method: "booleanValue", sig: "()Z")
let HashMapPutMethod = try! JNI.getJavaMethod(forClass: HashMapClassname, method: "put", sig: "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;")
let HashMapGetMethod = try! JNI.getJavaMethod(forClass: HashMapClassname, method: "get", sig: "(L\(ObjectClassname);)L\(ObjectClassname);")
let HashMapKeySetMethod = try! JNI.getJavaMethod(forClass: HashMapClassname, method: "keySet", sig: "()L\(SetClassname);")
let HashMapSizeMethod = try! JNI.getJavaMethod(forClass: HashMapClassname, method: "size", sig: "()I")
let SetToArrayMethod = try! JNI.getJavaMethod(forClass: SetClassname, method: "toArray", sig: "()[L\(ObjectClassname);")
let ArrayListGetMethod = try! JNI.getJavaMethod(forClass: ArrayListClassname, method: "get", sig: "(I)L\(ObjectClassname);")
let ArrayListSizeMethod = try! JNI.getJavaMethod(forClass: ArrayListClassname, method: "size", sig: "()I")
let CollectionAddMethod = try! JNI.getJavaMethod(forClass: "java/util/Collection", method: "add", sig: "(Ljava/lang/Object;)Z")
let CollectionIteratorMethod = try! JNI.getJavaMethod(forClass: "java/util/Collection", method: "iterator", sig: "()Ljava/util/Iterator;")
let CollectionSizeMethod = try! JNI.getJavaMethod(forClass: "java/util/Collection", method: "size", sig: "()I")
let IteratorNextMethod = try! JNI.getJavaMethod(forClass: "java/util/Iterator", method: "next", sig: "()Ljava/lang/Object;")
let DateGetTimeMethod = try! JNI.getJavaMethod(forClass: "java/util/Date", method: "getTime", sig:"()J")
let VMDebugDumpReferenceTablesMethod = JNI.api.GetStaticMethodID(JNI.env, VMDebugClass, "dumpReferenceTables", "()V")
let ByteBufferArray = try! JNI.getJavaMethod(forClass: "java/nio/ByteBuffer", method: "array", sig: "()[B")
let ByteBufferWrap = JNI.api.GetStaticMethodID(JNI.env, ByteBufferClass, "wrap", "([B)Ljava/nio/ByteBuffer;")!