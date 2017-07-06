//
//  CollectionViewMapperAdapter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/24/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation
import ViewMapper

open class CollectionViewMapperAdapter<A: CellMapperAdapter, E: DataLoaderEngine>: CollectionListAdapter<E> {
  public typealias CellAdapterType = A
  
  public var cellAdapter: A!
  
  public required init(cellAdapter: A, dataLoader: DataLoader<E> = DataLoader<E>(dataLoaderEngine: E())) {
    super.init(dataLoader: dataLoader)
    
    self.cellAdapter = cellAdapter
  }
  
  public required init(dataLoader: DataLoader<E>) {
    fatalError("init(dataLoader:) has not been implemented")
  }
  
  
  open override func registerCells() {
    for cellType in cellAdapter.cellTypes {
      collectionView.register(cellType.nib, forCellWithReuseIdentifier: cellType.identifier)
    }
  }
  
  open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    
    let identifier = cellAdapter.cellIdentifier(forRow: row as! A.T.T)
    
    let mappableCell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! A.T    
    mappableCell.map(object: row as! A.T.T)
    cellAdapter.onDequeueCell?(mappableCell, indexPath)
    
    let cell = mappableCell as! UICollectionViewCell
    return cell
  }
  
  open override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    cellAdapter.onSelectCell?(row as! A.T.T, viewController)
  }
  
  open override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    cellAdapter.onDeselectCell?(row as! A.T.T, viewController)
  }
  
  open override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
    
    let row = dataLoader.rowsToDisplay[indexPath.row]
    return cellAdapter.size?(row as! A.T.T) ?? flowLayout.itemSize
  }
  
  open override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    cellAdapter.onScrollViewDidScroll?(scrollView)
  }

}

