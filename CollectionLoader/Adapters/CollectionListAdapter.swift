//
//  CollectionListAdapter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 6/12/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation
import ViewMapper

open class CollectionListAdapter<E: DataLoaderEngine>: NSObject, BaseListAdapter, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  public typealias EngineType = E
  
  public var collectionView: UICollectionView!
  public var scrollView: UIScrollView {
    return collectionView
  }
  
  public var dataLoader: DataLoader<E>!
  public weak var viewController: UIViewController!
  
  public required init(dataLoader: DataLoader<E> = DataLoader<E>(dataLoaderEngine: E())) {
    super.init()
    
    self.dataLoader = dataLoader
    self.initializeCollectionView()
  }
  
  open func initializeCollectionView() {
    self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    self.collectionView.delegate = self
    self.collectionView.dataSource = self
    self.collectionView.backgroundColor = UIColor.white
    
    let flowLayout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    flowLayout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: flowLayout.itemSize.height)
    flowLayout.minimumInteritemSpacing = 0
    flowLayout.minimumLineSpacing = 0
  }
  
  open func reloadData() {
    collectionView.reloadData()
  }
  
  open func registerCells() {

  }
  
  open func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return dataLoader.rowsToDisplay.count
  }
  
  open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    fatalError("collectionView.cellForItemAt must be overriden in your CollectionListAdapter subclass")
  }
  
  open func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

  }
  
  open func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {

  }
  
  open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
    return flowLayout.itemSize
  }
  
  open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    return .zero
  }
  
  open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
    return .zero
  }
  
  open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    return UICollectionReusableView(frame: .zero)
  }
  
  open func scrollViewDidScroll(_ scrollView: UIScrollView) {
    
  }  
}

