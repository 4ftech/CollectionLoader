//
//  TableNibAdapter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 5/18/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation
import ViewMapper

open class TableNibAdapter<V: ViewMappable, E: DataLoaderEngine>: TableViewMapperAdapter<NibCellMapperAdapter<V>, E> {
  public init(nib: UINib, dataLoader: DataLoader<E>, initializer: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    super.init(cellAdapter: NibCellMapperAdapter<V>(nib: nib, initializer: initializer), dataLoader: dataLoader)
  }
  
  public convenience init (nib: UINib, dataLoaderEngine: E, initializer: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    self.init(nib: nib, dataLoader: DataLoader<E>(dataLoaderEngine: dataLoaderEngine), initializer: initializer)
  }

  public convenience init (nib: UINib, initializer: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    self.init(nib: nib, dataLoaderEngine: E(), initializer: initializer)
  }
  
  public convenience init (nibName: String, dataLoader: DataLoader<E>, initializer: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    self.init(nib: UINib(nibName: nibName, bundle: nil), dataLoader: dataLoader, initializer: initializer)
  }
  
  public convenience init (nibName: String, dataLoaderEngine: E, initializer: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    self.init(nibName: nibName, dataLoader: DataLoader<E>(dataLoaderEngine: dataLoaderEngine), initializer: initializer)
  }
  
  public convenience init (nibName: String, initializer: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    self.init(nibName: nibName, dataLoaderEngine: E(), initializer: initializer)
  }
}
