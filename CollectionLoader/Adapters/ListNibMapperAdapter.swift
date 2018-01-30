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

open class ListNibMapperAdapter<V: ViewMappable, E>: ListCellMapperAdapter<NibCellMapperAdapter<V>, E> where E: DataLoaderEngine<V.T> {
  
  // MARK: CellMapper
  public init(cellMapper: CellMapper<V> = CellMapper<V>(),
              dataLoader: DataLoader<T> = DataLoader(dataLoaderEngine: E()),
              initialize: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    
    super.init(cellAdapter: NibCellMapperAdapter(cellMapper: cellMapper),
               dataLoader: dataLoader,
               initialize: initialize)
  }
  
  public init(cellMapper: CellMapper<V> = CellMapper<V>(),
              dataLoaderEngine: E,
              initialize: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    
    super.init(cellAdapter: NibCellMapperAdapter(cellMapper: cellMapper),
               dataLoader: DataLoader(dataLoaderEngine: dataLoaderEngine),
               initialize: initialize)
  }

  // MARK: UINib
  public init(nib: UINib,
              dataLoader: DataLoader<T> = DataLoader(dataLoaderEngine: E()),
              initialize: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    
    super.init(cellAdapter: NibCellMapperAdapter(nib: nib),
               dataLoader: dataLoader,
               initialize: initialize)
  }
  
  public init(nib: UINib,
              dataLoaderEngine: E,
              initialize: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    
    super.init(cellAdapter: NibCellMapperAdapter(nib: nib),
               dataLoader: DataLoader(dataLoaderEngine: dataLoaderEngine),
               initialize: initialize)
  }
  
  // MARK: nibName
  public init(nibName: String,
              dataLoader: DataLoader<T> = DataLoader(dataLoaderEngine: E()),
              initialize: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    
    super.init(cellAdapter: NibCellMapperAdapter(nibName: nibName),
               dataLoader: dataLoader,
               initialize: initialize)
  }
  
  public init(nibName: String,
              dataLoaderEngine: E,
              initialize: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    
    super.init(cellAdapter: NibCellMapperAdapter(nibName: nibName),
               dataLoader: DataLoader(dataLoaderEngine: dataLoaderEngine),
               initialize: initialize)
  }
}
