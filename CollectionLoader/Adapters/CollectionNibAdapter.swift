//
//  CollectionNibAdapter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 6/12/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation
import ViewMapper

open class CollectionNibAdapter<V: ViewMappable, E: DataLoaderEngine>: CollectionViewMapperAdapter<NibCellMapperAdapter<V>, E> {
  public init(nib: UINib, dataLoader: DataLoader<E> = DataLoader<E>(dataLoaderEngine: E()), initializer: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    super.init(cellAdapter: NibCellMapperAdapter<V>(nib: nib, initializer: initializer), dataLoader: dataLoader)
  }
  
  public init (nibName: String, dataLoader: DataLoader<E> = DataLoader<E>(dataLoaderEngine: E()), initializer: ((NibCellMapperAdapter<V>) -> Void)? = nil) {
    super.init(cellAdapter: NibCellMapperAdapter<V>(nib: UINib(nibName: nibName, bundle: nil), initializer: initializer), dataLoader: dataLoader)
  }
  
  public required init(cellAdapter: NibCellMapperAdapter<V>, dataLoader: DataLoader<E>) {
    fatalError("init(cellAdapter:dataLoader:) has not been implemented")
  }
  
  public required init(dataLoader: DataLoader<E>) {
    fatalError("init(dataLoader:) has not been implemented")
  }
}
