//
//  ListNibMapperAdapter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 1/29/18.
//  Copyright © 2018 Oinkist. All rights reserved.
//

import Foundation

import ViewMapper
import DataSource

open class ListNibMapperAdapter<V: ViewMappable>: ListCellMapperAdapter<NibCellMapperAdapter<V>> where V.T:BaseDataModel {
  static func cellAdapter(nib: UINib?) -> NibCellMapperAdapter<V> {
    return NibCellMapperAdapter<V>(nib: nib)
  }
  
  public init(nib: UINib? = nil, dataLoader: DataLoader<T> = DataLoader(dataLoaderEngine: DataLoaderEngine<T>()), initialize: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    super.init(cellAdapter: ListNibMapperController.cellAdapter(nib: nib), dataLoader: dataLoader, initialize: initialize)
  }
  
  public init(nib: UINib? = nil, dataLoaderEngine: DataLoaderEngine<T>, initialize: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    super.init(cellAdapter: ListNibMapperController.cellAdapter(nib: nib), dataLoader: DataLoader(dataLoaderEngine: dataLoaderEngine), initialize: initialize)
  }
  
}
