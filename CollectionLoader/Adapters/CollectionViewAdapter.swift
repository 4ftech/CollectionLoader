//
//  CollectionViewAdapter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/24/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation

public class CollectionViewAdapter<A: CellAdapter, E: DataLoaderEngine>: NSObject, BaseCollectionAdapter, UICollectionViewDelegate, UICollectionViewDataSource {
  public typealias CellAdapterType = A
  public typealias EngineType = E
  
  public var collectionViewType: CollectionViewType = .collection
  
  public var cellAdapter: A!
  public weak var dataLoader: DataLoader<E>!
  
  public required override init() {
    super.init()
    
    self.cellAdapter = A()
  }
  
  public init(cellAdapter: A) {
    super.init()
    
    self.cellAdapter = cellAdapter
  }
  
  public func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return dataLoader.rowsToDisplay.count
  }
  
  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    
    let identifier = cellAdapter.cellIdentifier(forRow: row as! A.T)
    
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
    cellAdapter.apply(row: row as! A.T, toCell: cell as! CellAdapterType.C)
    
    return cell
  }
  
  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    cellAdapter.didTapCell(forRow: row as! A.T)
  }
}

