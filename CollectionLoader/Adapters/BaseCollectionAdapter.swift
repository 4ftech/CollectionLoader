//
//  BaseCollectionAdapter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/24/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation

public protocol BaseCollectionAdapter {
  associatedtype EngineType: DataLoaderEngine

  var viewController: UIViewController! { get set }
  var dataLoader: DataLoader<EngineType>! { get set }
  var scrollView: UIScrollView { get }
  
  func registerCells()
  func reloadData()
}
