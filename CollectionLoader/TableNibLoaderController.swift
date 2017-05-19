//
//  TableNibLoaderController.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 5/18/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation
import ViewMapper

open class TableNibLoaderController<V: ViewMappable, E: DataLoaderEngine>: TableLoaderController<NibCellMapperAdapter<V>, E> {
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  public init(nib: UINib, dataLoader: DataLoader<E>, initializer: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    super.init(cellAdapter: NibCellMapperAdapter(nib: nib, initializer: initializer), dataLoader: dataLoader)
  }
  
  public init (nib: UINib, dataLoaderEngine: E, initializer: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    super.init(cellAdapter: NibCellMapperAdapter(nib: nib, initializer: initializer), dataLoaderEngine: dataLoaderEngine)
  }
  
  public init (nib: UINib, initializer: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    super.init(cellAdapter: NibCellMapperAdapter(nib: nib, initializer: initializer))
  }
  
  public init (nibName: String, dataLoader: DataLoader<E>, initializer: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    super.init(cellAdapter: NibCellMapperAdapter(nibName: nibName, initializer: initializer), dataLoader: dataLoader)
  }
  
  public init (nibName: String, dataLoaderEngine: E, initializer: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
super.init(cellAdapter: NibCellMapperAdapter(nibName: nibName, initializer: initializer), dataLoaderEngine: dataLoaderEngine)  }
  
  public init (nibName: String, initializer: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    super.init(cellAdapter: NibCellMapperAdapter(nibName: nibName, initializer: initializer))
  }
}
