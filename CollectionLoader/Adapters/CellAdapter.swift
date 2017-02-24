//
//  CellAdapter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/24/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation

public protocol CellAdapter {
  // C is either UITableViewCell or UICollectionViewCell
  associatedtype C
  associatedtype T: CollectionRow
  
  init()
  var cellTypes: [CellType] { get }
  func cellIdentifier(forRow row: T) -> String
  func apply(row: T, toCell cell: C)
  func didTapCell(forRow row: T)
}
