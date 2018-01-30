//
//  ListNibMapperController.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 1/29/18.
//  Copyright © 2018 Oinkist. All rights reserved.
//

import Foundation

import ViewMapper
import DataSource

open class ListNibMapperController<V: ViewMappable>: ListCellMapperController<NibCellMapperAdapter<V>> where V.T: BaseDataModel {
  static func cellAdapter(nib: UINib?) -> NibCellMapperAdapter<V> {
    return NibCellMapperAdapter<V>(nib: nib)
  }
  
  public init(listType: ListType, nib: UINib? = nil, dataLoader: DataLoader<T> = DataLoader(dataLoaderEngine: DataLoaderEngine<T>()), initialize: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    super.init(listType: listType, cellAdapter: ListNibMapperController.cellAdapter(nib: nib), dataLoader: dataLoader, initialize: initialize)
  }
  
  public init(listType: ListType, nib: UINib? = nil, dataLoaderEngine: DataLoaderEngine<T>, initialize: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    super.init(listType: listType, cellAdapter: ListNibMapperController.cellAdapter(nib: nib), dataLoader: DataLoader(dataLoaderEngine: dataLoaderEngine), initialize: initialize)
  }
  
  public override init(listType: ListType, listAdapter: ListCellMapperAdapter<NibCellMapperAdapter<V>>) {
    super.init(listType: listType, listAdapter: listAdapter)
  }
  
  public init(listType: ListType, listAdapter: ListNibMapperAdapter<V>) {
    super.init(listType: listType, listAdapter: listAdapter)
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}
