//
//  SingleLineIconCellAdapter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/24/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation

open class SingleLineIconCellAdapter<T: CollectionRow>: CellAdapter {
  required public init() {
    
  }
  
  open var cellTypes: [CellType] {
    return [CellType(identifier: "singleLineIconCell", nib: UINib(nibName: "SingleLineIconCell", bundle: Bundle(identifier: "com.oinkist.CollectionLoader")))]
  }
  
  open func cellIdentifier(forRow row: T) -> String {
    return "singleLineIconCell"
  }
  
  open func apply(row: T, toCell cell: UITableViewCell) {
    let singleLineIconCell = cell as! SingleLineIconCell
    singleLineIconCell.mainLabel.text = row.name
  }
  
  open func didTapCell(forRow row: T) {
    
  }
}
