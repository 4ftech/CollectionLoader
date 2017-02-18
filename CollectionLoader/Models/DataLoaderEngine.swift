//
//  DataLoaderEngine.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation
import BoltsSwift

public protocol DataLoaderEngine {
  func task(forLoadType loadType: DataLoadType) -> Task<NSArray>
}

