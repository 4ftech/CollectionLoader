//
//  ParseTableLoader.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 3/1/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation
import CollectionLoader
import ParseDataSource
import ViewMapper

open class ParseTableLoader<T: ParseDataModel, U: ViewMappable>: CollectionLoaderController<TableViewMapperAdapter<NibCellMapperAdapter<U>, ParseDataEngine<T>>> where U.T == T {
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  public init(nib: UINib, initializer: ((NibCellMapperAdapter<U>) -> Void)? = nil) {
    let cellAdapter = NibCellMapperAdapter<U>(nib: nib)
    let dataEngine = ParseDataEngine<T>()
    super.init(collectionAdapter: TableViewMapperAdapter(cellAdapter: cellAdapter, dataLoaderEngine: dataEngine))
    
    initializer?(cellAdapter)
  }
}