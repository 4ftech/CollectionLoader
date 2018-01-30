//
//  ListAdapter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 1/29/18.
//  Copyright © 2018 Oinkist. All rights reserved.
//

import Foundation
import UIKit

import DataSource

open class ListAdapter<T: BaseDataModel>: NSObject, UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
  
  public var dataLoader: DataLoader<T>!  
  public init(dataLoader: DataLoader<T>) {
    super.init()
    
    self.dataLoader = dataLoader
  }
  
  open func registerCells(scrollView: UIScrollView) {

  }
  
  // MARK: - UIScrollViewDelegate
  open func scrollViewDidScroll(_ scrollView: UIScrollView) {
    
  }
  
  open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    
  }
  
  open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    
  }
  
  // MARK: - UITableViewDelegates
  open func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return dataLoader.rowsToDisplay.count
  }
  
  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    return UITableViewCell()
  }
  
  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
  }
  
  open func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    
  }
  
  open func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    
  }
  
  open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return false
  }
  
  open func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {

  }
  
  open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return tableView.rowHeight
  }
  
  open func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    return UITableViewAutomaticDimension
  }
  
  open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    return nil
  }
  
  open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 0
  }
  
  open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return nil
  }
  
  open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return 0
  }
  
  // MARK: - UICollectionViewDelegates
  open func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return dataLoader.rowsToDisplay.count
  }
  
  open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    return UICollectionViewCell()
  }
  
  open func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
  }
  
  open func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
    return true
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
}
