//
//  BaseCollectionAdapter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/24/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation

public protocol BaseCollectionAdapter {
  associatedtype CellAdapterType: CellAdapter
  associatedtype EngineType: DataLoaderEngine
  
  init()
  var cellAdapter: CellAdapterType! { get set }
  var dataLoader: DataLoader<EngineType>! { get set }
  var collectionViewType: CollectionViewType { get }
}
