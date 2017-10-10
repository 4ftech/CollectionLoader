//
//  BaseListAdapter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/24/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation

import Changeset

public protocol BaseListAdapter {
  associatedtype EngineType: DataLoaderEngine

  var viewController: UIViewController! { get set }
  var dataLoader: DataLoader<EngineType>! { get set }
  var scrollView: UIScrollView { get }
  
  func registerCells()
  func reloadData()
  func update(withEdits edits: [Edit<EngineType.T>], completion: ((Bool) -> Void)?)
}
