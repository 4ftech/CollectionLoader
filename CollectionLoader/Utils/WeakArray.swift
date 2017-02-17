//
//  WeakArray.swift
//  WeakArray
//
//  Created by David Mauro on 7/27/14.
//  Copyright (c) 2014 David Mauro. All rights reserved.
//

import Foundation

// MARK: Operator Overloads

public func ==<T: Equatable>(lhs: WeakArray<T>, rhs: WeakArray<T>) -> Bool {
  var areEqual = false
  if lhs.count == rhs.count {
    areEqual = true
    for i in 0..<lhs.count {
      if lhs[i] != rhs[i] {
        areEqual = false
        break
      }
    }
  }
  return areEqual
}

public func !=<T: Equatable>(lhs: WeakArray<T>, rhs: WeakArray<T>) -> Bool {
  return !(lhs == rhs)
}

public func ==<T: Equatable>(lhs: ArraySlice<T?>, rhs: ArraySlice<T?>) -> Bool {
  var areEqual = false
  if lhs.count == rhs.count {
    areEqual = true
    for i in 0..<lhs.count {
      if lhs[i] != rhs[i] {
        areEqual = false
        break
      }
    }
  }
  return areEqual
}

public func !=<T: Equatable>(lhs: ArraySlice<T?>, rhs: ArraySlice<T?>) -> Bool {
  return !(lhs == rhs)
}

public func +=<T> (lhs: inout WeakArray<T>, rhs: WeakArray<T>) -> WeakArray<T> {
  lhs.items += rhs.items
  return lhs
}

public func +=<T> (lhs: inout WeakArray<T>, rhs: Array<T>) -> WeakArray<T> {
  for item in rhs {
    lhs.append(item)
  }
  return lhs
}

private class Weak<T: AnyObject> {
  weak var value : T?
  var description: String {
    if let val = value {
      return "\(val)"
    } else {
      return "nil"
    }
  }
  
  init (value: T?) {
    self.value = value
  }
}

// MARK:-

public struct WeakArray<T: AnyObject>: Sequence, CustomDebugStringConvertible, ExpressibleByArrayLiteral {
  // MARK: Private
  fileprivate typealias WeakObject = Weak<T>
  fileprivate var items = [WeakObject]()
  
  // MARK: Public
  public var description: String {
    return items.description
  }
  public var debugDescription: String {
    return items.debugDescription
  }
  public var count: Int {
    return items.count
  }
  public var isEmpty: Bool {
    return items.isEmpty
  }
  public var first: T? {
    return self[0]
  }
  public var last: T? {
    return self[count - 1]
  }
  
  // MARK: Methods
  
  public init() {}
  
  public init(arrayLiteral elements: T...) {
    for element in elements {
      append(element)
    }
  }
  
  public func makeIterator() -> WeakGenerator<T> {
    let weakSlice: ArraySlice<WeakObject> = items[0..<items.count]
    let slice: ArraySlice<T?> = ArraySlice(weakSlice.map { $0.value })
    return WeakGenerator<T>(items: slice)
  }
  
  // MARK: - Slice-like Implementation
  
  public subscript(index: Int) -> T? {
    get {
      let weak = items[index]
      return weak.value
    }
    set(value) {
      let weak = Weak(value: value)
      items[index] = weak
    }
  }
  
  public subscript(range: Range<Int>) -> ArraySlice<T?> {
    get {
      let weakSlice: ArraySlice<WeakObject> = items[range]
      let slice : ArraySlice<T?> = ArraySlice(weakSlice.map { $0.value })
      return slice
    }
    set(value) {
      items[range] = ArraySlice(value.map {
        (value: T?) -> WeakObject in
        return Weak(value: value)
      })
    }
  }
  
  mutating public func append(_ value: T?) {
    let weak = Weak(value: value)
    items.append(weak)
  }
  
  mutating public func insert(_ newElement: T?, atIndex i: Int) {
    let weak = Weak(value: newElement)
    items.insert(weak, at: i)
  }
  
  public func indexOf(_ value: T?) -> Int? {
    for idx in 0..<count {
      let obj = items[idx]
      if value === obj.value {
        return idx
      }
    }
    return nil
  }
  
  mutating public func remove(at index: Int) -> T? {
    let weak = items.remove(at: index)
    return weak.value
  }
  
  mutating public func removeLast() -> T? {
    let weak = items.removeLast()
    return weak.value
  }
  
  mutating public func removeAll(_ keepCapacity: Bool) {
    items.removeAll(keepingCapacity: keepCapacity)
  }
  
  mutating public func removeRange(_ subRange: Range<Int>) {
    items.removeSubrange(subRange)
  }
  
  mutating public func replaceRange(_ subRange: Range<Int>, with newElements: ArraySlice<T?>) {
    let weakElements = newElements.map { Weak(value: $0) }
    items.replaceSubrange(subRange, with: weakElements)
  }
  
  mutating public func insertContentsOf(_ newElements: ArraySlice<T?>, at i: Int) {
    let weakElements = newElements.map { Weak(value: $0) }
    items.insert(contentsOf: weakElements, at: i)
  }
  
  mutating public func appendContentsOf(_ newElements: ArraySlice<T?>) {
    let weakElements = newElements.map { Weak(value: $0) }
    items.append(contentsOf: weakElements)
  }
  
  public func filter(_ includeElement: (T?) -> Bool) -> WeakArray<T> {
    var filtered: WeakArray<T> = []
    for item in items {
      if includeElement(item.value) {
        filtered.append(item.value)
      }
    }
    return filtered
  }
  
  public func reversed() -> WeakArray<T> {
    var reversed: WeakArray<T> = []
    let reversedItems = items.reversed()
    for item in reversedItems {
      reversed.append(item.value)
    }
    return reversed
  }
}

// MARK:-

public struct WeakGenerator<T>: IteratorProtocol {
  fileprivate var items: ArraySlice<T?>
  
  mutating public func next() -> T? {
    while !items.isEmpty {
      if let next = items.popFirst() {
        if next != nil {
          return next
        }
      }
    }
    return nil
  }
}
