//
//  CollectionRowCellAdapter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/24/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation

public protocol CollectionRowCellAdapter {
  associatedtype T: CollectionRow

  // U is either UITableViewCell or UICollectionViewCell
  associatedtype U
  
  var cellTypes: [CellType] { get }
  func cellIdentifier(forRow row: T) -> String
  func apply(row: T, toCell cell: U)
}
