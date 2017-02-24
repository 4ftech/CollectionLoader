//
//  FoursquareDataEngine.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation
import CollectionLoader
import PromiseKit

public class FoursquareVenueObject: NSObject, CollectionRow {
  public var objectId: String? = nil
  public var updatedAt: Date? = nil
  public var name: String? = "Venue"
}

public class FoursquareDataEngine: NSObject, DataLoaderEngine {
  public var queryLimit: Int { return 20 }

  public func promise(forLoadType loadType: DataLoadType, queryString: String?) -> Promise<[FoursquareVenueObject]> {
    return Promise(value: [FoursquareVenueObject()])
  }
}
