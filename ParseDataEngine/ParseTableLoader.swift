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
import ViewMapper

open class ParseTableLoader<T: ParseDataModel, U: ViewMappable>: ListLoaderController<TableViewMapperAdapter<NibCellMapperAdapter<U>, ParseDataEngine<T>>> {
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  public init(nib: UINib, initializer: ((NibCellMapperAdapter<U>) -> Void)? = nil) {
    let cellAdapter = NibCellMapperAdapter<U>(nib: nib)
    let dataEngine = ParseDataEngine<T>()
    dataEngine.paginate = true
    dataEngine.queryLimit = 100
    super.init(listAdapter: TableViewMapperAdapter(cellAdapter: cellAdapter, dataLoader: DataLoader(dataLoaderEngine: dataEngine)))
    
    initializer?(cellAdapter)
  }
}
