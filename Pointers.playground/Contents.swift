import Foundation

// UNSAFE POINTERS EM SWIFT
/// Leonardo Amorim de Oliveira
/// Tutorial: Unsafe Swift: Using Pointers and Interacting With C 
/// https://www.raywenderlich.com/7181017-unsafe-swift-using-pointers-and-interacting-with-c


//------------------------------------------------------------------------------------------//
// MARK: - Exploring Memory Layout With Unsafe Swift

/// Use MemoryLayout to tell you the size and alignment of components of some native Swift types
///     MemoryLayout<Type> is a generic type evaluated at compile time. It determines the size, alignment and stride of each 
///     specified Type and returns a number in bytes.

MemoryLayout<Int>.size          ///  returns 8 (on 64-bit)
MemoryLayout<Int>.alignment     ///  returns 8 (on 64-bit)
MemoryLayout<Int>.stride        /// returns 8 (on 64-bit)

MemoryLayout<Int16>.size        /// returns 2
MemoryLayout<Int16>.alignment   /// returns 2
MemoryLayout<Int16>.stride      /// returns 2

MemoryLayout<Bool>.size         /// returns 1
MemoryLayout<Bool>.alignment    /// returns 1
MemoryLayout<Bool>.stride       /// returns 1

MemoryLayout<Float>.size        /// returns 4
MemoryLayout<Float>.alignment   /// returns 4
MemoryLayout<Float>.stride      /// returns 4

MemoryLayout<Double>.size       /// returns 8
MemoryLayout<Double>.alignment  /// returns 8
MemoryLayout<Double>.stride     /// returns 8


//------------------------------------------------------------------------------------------//
// MARK: - Examining Struct and Class Layouts

/// Structs
struct EmptyStruct {}

MemoryLayout<EmptyStruct>.size      /// returns 0
MemoryLayout<EmptyStruct>.alignment /// returns 1
MemoryLayout<EmptyStruct>.stride    /// returns 1

struct SampleStruct {
  let number: UInt32
  let flag: Bool
}

MemoryLayout<SampleStruct>.size       /// returns 5
MemoryLayout<SampleStruct>.alignment  /// returns 4
MemoryLayout<SampleStruct>.stride     /// returns 8

/// Class
/// Classes are reference types, so MemoryLayout reports the size of a reference: Eight bytes.
class EmptyClass {}

MemoryLayout<EmptyClass>.size      /// returns 8 (on 64-bit)
MemoryLayout<EmptyClass>.stride    /// returns 8 (on 64-bit)
MemoryLayout<EmptyClass>.alignment /// returns 8 (on 64-bit)

class SampleClass {
  let number: Int64 = 0
  let flag = false
}

MemoryLayout<SampleClass>.size      /// returns 8 (on 64-bit)
MemoryLayout<SampleClass>.stride    /// returns 8 (on 64-bit)
MemoryLayout<SampleClass>.alignment /// returns 8 (on 64-bit)

/// Exploring Swift Memory Layout • Mike Ash: https://www.youtube.com/watch?v=ERYNyrfXjlg


//------------------------------------------------------------------------------------------//
// MARK: - Using Raw Pointers

/// 1- These constants hold frequently used values:
///     • Count holds the number of integers to store.
///     • Stride holds the stride of type Int.
///     • Alignment holds the alignment of type Int.
///     • ByteCount holds the total number of bytes needed.

let count = 2
let stride = MemoryLayout<Int>.stride
let alignment = MemoryLayout<Int>.alignment
let byteCount = stride * count

/// 2- A do block adds a scope level, so you can reuse the variable names in upcoming examples.

do {
  print("Raw pointers")
  
  /// 3- UnsafeMutableRawPointer.allocate allocates the required bytes. This method returns an UnsafeMutableRawPointer. 
  ///   The name of that type tells you the pointer can load and store, or mutate, raw bytes.
    
  let pointer = UnsafeMutableRawPointer.allocate(
    byteCount: byteCount,
    alignment: alignment)
    
  /// 4- A defer block makes sure you deallocate the pointer properly. ARC isn’t going to help you here — you need to handle 
  ///   memory management yourself! You can read more about defer statements in the official Swift documentation.
    
  defer {
    pointer.deallocate()
  }
  
  /// 5- storeBytes and load, unsurprisingly, store and load bytes. You calculate the memory address of the second integer by 
  ///   advancing the pointer stride bytes. Since pointers are Strideable, you can also use pointer arithmetic like: 
  ///   (pointer+stride).storeBytes(of: 6, as: Int.self)
    
  pointer.storeBytes(of: 42, as: Int.self)
  pointer.advanced(by: stride).storeBytes(of: 6, as: Int.self)
  pointer.load(as: Int.self)
  pointer.advanced(by: stride).load(as: Int.self)
  
  /// 6- An UnsafeRawBufferPointer lets you access memory as if it were a collection of bytes. This means you can iterate over 
  /// the bytes and access them using subscripting. You can also use cool methods like filter, map and reduce. You initialize 
  /// the buffer pointer using the raw pointer.
    
  let bufferPointer = UnsafeRawBufferPointer(start: pointer, count: byteCount)
  for (index, byte) in bufferPointer.enumerated() {
    print("byte \(index): \(byte)")
  }
}


//------------------------------------------------------------------------------------------//
// MARK: - Using Typed Pointers

/// Simplify the previous example by using typed pointers.

do {
  print("Typed pointers")
  
  let pointer = UnsafeMutablePointer<Int>.allocate(capacity: count)
  pointer.initialize(repeating: 0, count: count)
  defer {
    pointer.deinitialize(count: count)
    pointer.deallocate()
  }
  
  pointer.pointee = 42
  pointer.advanced(by: 1).pointee = 6
  pointer.pointee
  pointer.advanced(by: 1).pointee
  
  let bufferPointer = UnsafeBufferPointer(start: pointer, count: count)
  for (index, value) in bufferPointer.enumerated() {
    print("value \(index): \(value)")
  }
}

//------------------------------------------------------------------------------------------//
// MARK: - Converting Raw Pointers to Typed Pointers

/// Create the typed pointer by binding the memory to the required type Int. By binding memory, you can access it in a 
/// type-safe way. Memory binding goes on behind the scenes when you create a typed pointer.

do {
  print("Converting raw pointers to typed pointers")
  
  let rawPointer = UnsafeMutableRawPointer.allocate(
    byteCount: byteCount,
    alignment: alignment)
  defer {
    rawPointer.deallocate()
  }
  
  let typedPointer = rawPointer.bindMemory(to: Int.self, capacity: count)
  typedPointer.initialize(repeating: 0, count: count)
  defer {
    typedPointer.deinitialize(count: count)
  }

  typedPointer.pointee = 42
  typedPointer.advanced(by: 1).pointee = 6
  typedPointer.pointee
  typedPointer.advanced(by: 1).pointee
  
  let bufferPointer = UnsafeBufferPointer(start: typedPointer, count: count)
  for (index, value) in bufferPointer.enumerated() {
    print("value \(index): \(value)")
  }
}


//------------------------------------------------------------------------------------------//
// MARK: - Getting the Bytes of an Instance

/// Often, you have an existing instance of a type and you want to inspect the bytes that form it. You can achieve this using a 
/// method called withUnsafeBytes(of:).
///     • This prints out the raw bytes of the SampleStruct instance.
///     • withUnsafeBytes(of:) gives you access to an UnsafeRawBufferPointer that you can use inside the closure.
///     • withUnsafeBytes is also available as an instance method on Array and Data.

do {
  print("Getting the bytes of an instance")
  
  var sampleStruct = SampleStruct(number: 25, flag: true)

  withUnsafeBytes(of: &sampleStruct) { bytes in
    for byte in bytes {
      print(byte)
    }
  }
}


//------------------------------------------------------------------------------------------//
// MARK: - Computing a Checksum

/// Using withUnsafeBytes(of:), you can return a result
/// The reduce call adds the bytes, then "~" flips the bits. While not the most robust error detection, it shows the concept.

do {
  print("Checksum the bytes of a struct")
  
  var sampleStruct = SampleStruct(number: 25, flag: true)
  
  let checksum = withUnsafeBytes(of: &sampleStruct) { (bytes) -> UInt32 in
    return ~bytes.reduce(UInt32(0)) { $0 + numericCast($1) }
  }
  
  print("checksum", checksum) // prints checksum 4294967269
}

