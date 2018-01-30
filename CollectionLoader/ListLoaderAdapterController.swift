//
//  ListLoaderAdapterController.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 1/30/18.
//  Copyright © 2018 Oinkist. All rights reserved.
//

import Foundation

open class ListLoaderAdapterController<L: UIScrollView, T, E, A>: ListLoaderController<L, T, E> where A:ListAdapter<T, E> {
  public var listAdapter: A!

  public init(listAdapter: A,
              viewHandler: ListViewHandler<L> = ListViewHandler<L>()) {
    super.init(dataLoader: listAdapter.dataLoader, viewHander: viewHandler)
    
    self.listAdapter = listAdapter
  }
  
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  open override func registerCells() {
    listAdapter.registerCells(scrollView: self.scrollView)
  }

  // MARK: - UIScrollViewDelegate
  open override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    listAdapter.scrollViewDidScroll(scrollView)
  }
  
  open override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    listAdapter.scrollViewDidEndDecelerating(scrollView)
  }
  
  open override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    listAdapter.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
  }
  
  // MARK: - UITableViewDelegates
  open override func numberOfSections(in tableView: UITableView) -> Int {
    return listAdapter.numberOfSections(in: tableView)
  }
  
  open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return listAdapter.tableView(tableView, numberOfRowsInSection: section)
  }
  
  open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    return listAdapter.tableView(tableView, cellForRowAt: indexPath)
  }
  
  open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    listAdapter.tableView(tableView, didSelectRowAt: indexPath)
  }
  
  open override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    listAdapter.tableView(tableView, didDeselectRowAt: indexPath)
  }
  
  open override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    listAdapter.tableView(tableView, accessoryButtonTappedForRowWith: indexPath)
  }
  
  open override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return listAdapter.tableView(tableView, canEditRowAt: indexPath)
  }
  
  open override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    super.tableView(tableView, commit: editingStyle, forRowAt: indexPath)
    
    listAdapter.tableView(tableView, commit: editingStyle, forRowAt: indexPath)
  }
  
  open override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return listAdapter.tableView(tableView, heightForRowAt: indexPath)
  }
  
  open override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    return listAdapter.tableView(tableView, estimatedHeightForRowAt: indexPath)
  }
  
  open override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    return listAdapter.tableView(tableView, viewForHeaderInSection: section)
  }
  
  open override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return listAdapter.tableView(tableView, heightForHeaderInSection: section)
  }
  
  open override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return listAdapter.tableView(tableView, viewForFooterInSection: section)
  }
  
  open override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return listAdapter.tableView(tableView, heightForFooterInSection: section)
  }
  
  // MARK: - UICollectionViewDelegates
  open override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return listAdapter.numberOfSections(in: collectionView)
  }
  
  open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return listAdapter.collectionView(collectionView, numberOfItemsInSection: section)
  }
  
  open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    return listAdapter.collectionView(collectionView, cellForItemAt: indexPath)
  }
  
  open override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
    return listAdapter.collectionView(collectionView, shouldSelectItemAt: indexPath)
  }
  
  open override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    listAdapter.collectionView(collectionView, didSelectItemAt: indexPath)
  }
  
  open override func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
    return listAdapter.collectionView(collectionView, shouldDeselectItemAt: indexPath)
  }
  
  open override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    listAdapter.collectionView(collectionView, didDeselectItemAt: indexPath)
  }
  
  open override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    if let listAdapter = listAdapter {
      return listAdapter.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath)
    } else {
      let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
      return flowLayout.itemSize
    }
  }
  
  open override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    return listAdapter.collectionView(collectionView, layout: collectionViewLayout, referenceSizeForHeaderInSection: section)
  }
  
  open override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
    return listAdapter.collectionView(collectionView, layout: collectionViewLayout, referenceSizeForFooterInSection: section)
  }
  
  open override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    return listAdapter.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
  }
}
