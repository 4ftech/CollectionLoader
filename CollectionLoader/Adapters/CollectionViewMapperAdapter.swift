//
//  CollectionViewMapperAdapter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/24/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation
import ViewMapper

public class CollectionViewMapperAdapter<A: CellMapperAdapter, E: DataLoaderEngine>: NSObject, BaseCollectionAdapter, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  public typealias EngineType = E
  
  public var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
  public var scrollView: UIScrollView {
    return collectionView
  }
  
  public var cellAdapter: A!
  public var dataLoader: DataLoader<E>!
  public weak var viewController: UIViewController!
  
  public required init(cellAdapter: A, dataLoaderEngine: E) {
    super.init()
    
    self.cellAdapter = cellAdapter
    self.dataLoader = DataLoader<E>(dataLoaderEngine: dataLoaderEngine)

    self.collectionView.delegate = self
    self.collectionView.dataSource = self
    self.collectionView.backgroundColor = UIColor.white
    
    let flowLayout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    flowLayout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: flowLayout.itemSize.height)
    flowLayout.minimumInteritemSpacing = 0
    flowLayout.minimumLineSpacing = 0
  }
  
  public func reloadData() {
    collectionView.reloadData()
  }
  
  public func registerCells() {
    for cellType in cellAdapter.cellTypes {
      collectionView.register(cellType.nib, forCellWithReuseIdentifier: cellType.identifier)
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
    
    let identifier = cellAdapter.cellIdentifier(forRow: row as! A.T.T)
    
    let mappableCell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! A.T    
    mappableCell.map(object: row as! A.T.T)
    cellAdapter.onDequeueCell?(mappableCell)
    
    let cell = mappableCell as! UICollectionViewCell
    return cell
  }
  
  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    cellAdapter.onSelectCell?(row as! A.T.T, viewController)
  }
  
  public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    let row = dataLoader.rowsToDisplay[indexPath.row]
    cellAdapter.onDeselectCell?(row as! A.T.T, viewController)
  }
  
  public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
    
    let row = dataLoader.rowsToDisplay[indexPath.row]
    return cellAdapter.size?(row as! A.T.T) ?? flowLayout.itemSize
  }
}

