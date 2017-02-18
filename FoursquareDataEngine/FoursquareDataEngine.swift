//
//  FoursquareDataEngine.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation
import CollectionLoader
import BoltsSwift

public class FoursquareVenueObject: NSObject, CollectionRow {
  public var objectId: String? {
    return nil
  }
  
  public var updatedAt: Date? {
    return nil
  }
  
  public var name: String? {
    return "Venue"
  }
}

public class FoursquareDataEngine: NSObject, DataLoaderEngine {
  public func task(forLoadType loadType: DataLoadType) -> Task<NSArray> {
    return Task<NSArray>([FoursquareVenueObject()] as NSArray)
  }
}
