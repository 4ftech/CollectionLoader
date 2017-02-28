//
//  CollectionViewAdapter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/24/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation

public class CollectionViewAdapter<A: CollectionRowCellAdapter, E: DataLoaderEngine>: NSObject, BaseCollectionAdapter, UICollectionViewDelegate, UICollectionViewDataSource {
  public typealias CellAdapterType = A
  public typealias EngineType = E
  
  public var collectionViewType: CollectionViewType = .collection
  
  public var cellAdapter: A!
  public var dataLoader: DataLoader<E>!
  public weak var delegate: BaseCollectionDelegate?
  
  public required init(cellAdapter: A, dataLoaderEngine: E) {
    super.init()
    
    self.cellAdapter = cellAdapter
    self.dataLoader = DataLoader<E>(dataLoaderEngine: dataLoaderEngine)
  }
  
  public func registerCells<T: UIScrollView>(scrollView: T) {
    if let collectionView = scrollView as? UICollectionView {
      for cellType in cellAdapter.cellTypes {
        collectionView.register(cellType.nib, forCellWithReuseIdentifier: cellType.identifier)
      }
    }    
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
    cellAdapter.apply(row: row as! A.T, toCell: cell as! CellAdapterType.U)
    
    return cell
  }
  
  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    delegate?.didTapCell(forRow: row)
  }
}

