//
//  ParseTableLoader.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 3/1/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation
import CollectionLoader
import ParseDataSource
import DataSource
import ViewMapper

open class ParseTableLoader<V: ViewMappable>: ListNibMapperController<V> where V.T: ParseDataModel {
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  public init(nib: UINib? = nil, initialize: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    let dataEngine = ParseDataEngine<V.T>()
    dataEngine.paginate = true
    dataEngine.queryLimit = 100
    
    super.init(listType: .table, nib: nib, dataLoaderEngine: dataEngine)
    initialize?(self.cellAdapter)
  }
}
