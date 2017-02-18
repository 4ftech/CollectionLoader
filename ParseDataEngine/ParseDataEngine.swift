//
//  ParseDataEngine.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation
import CollectionLoader
import BoltsSwift
import Parse

open class ParseCollectionObject: NSObject, CollectionRow {
  var parseObject: PFObject?
  
  public init(parseObject: PFObject) {
    super.init()
    
    self.parseObject = parseObject
  }
  
  open var objectId: String? {
    return parseObject?.objectId
  }
  
  public var updatedAt: Date? {
    return parseObject?.updatedAt
  }
  
  open var name: String? {
    return parseObject?["name"] as? String
  }
}

public class ParseDataEngine: NSObject, DataLoaderEngine {
  var parseClassName: String?
  var subclassedType: PFObject.Type?
  
  public init(parseClassName: String? = nil, subclassedType: PFObject.Type? = nil) {
    super.init()
    
    self.parseClassName = parseClassName
    self.subclassedType = subclassedType
  }
  
  func query(forLoadType loadType: DataLoadType) -> PFQuery<PFObject> {
    if let parseClassName = parseClassName {
      return PFQuery<PFObject>(className: parseClassName)
    } else if let subclassedType = subclassedType {
      return subclassedType.query()!
    } else {
      return PFQuery()
    }
  }
  
  public func task(forLoadType loadType: DataLoadType) -> Task<NSArray> {
    let task = TaskCompletionSource<NSArray>()
    
    query(forLoadType: loadType).findObjectsInBackground().continue({ parseTask in
      
      if let error = parseTask.error {
        NSLog("Error: \(error)")
        task.set(error: error)
      } else if let results = parseTask.result as? [PFObject] {
        if let _ = self.subclassedType {
          // Assume the subclassedType also conforms to CollectionRow
          task.set(result: NSArray(array: results))
        } else {
          task.set(result: NSArray(array: results.map { ParseCollectionObject(parseObject: $0) }))
        }
      } else {
        task.set(result: [])
      }
      
      return nil
    })
    
    return task.task
  }
}

