//
//  TableListAdapter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 6/12/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation
import UIKit

import Changeset

open class TableListAdapter<E: DataLoaderEngine>: NSObject, BaseListAdapter, UITableViewDelegate, UITableViewDataSource {
  public typealias EngineType = E
  
  public var tableView: UITableView!
  public var scrollView: UIScrollView {
    return tableView
  }
  
  public var dataLoader: DataLoader<E>!
  
  public weak var viewController: UIViewController!
  
  public required init(dataLoader: DataLoader<E> = DataLoader<E>(dataLoaderEngine: E())) {
    super.init()
    
    self.dataLoader = dataLoader
    self.initializeTableView()
  }
  
  open func initializeTableView() {
    self.tableView = UITableView()
    self.tableView.delegate = self
    self.tableView.dataSource = self
  }
  
  open func reloadData() {
    tableView.reloadData()
  }
  
  open func update(withEdits edits: [Edit<E.T>], completion: ((Bool) -> Void)? = nil) {
    tableView.update(with: edits)
    completion?(true)
  }
  
  open func registerCells() {

  }
  
  open func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return dataLoader.rowsToDisplay.count
  }
  
  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    fatalError("tableView.cellForItemAt must be overriden in your TableListAdapter subclass")
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
    if editingStyle == .delete {
      let row = dataLoader.rowsToDisplay[indexPath.row]
      if row.isNew {
        self.dataLoader.removeRowForObject(row)
        NotificationCenter.default.postCRUDNotification(.delete, crudObject: row)
      } else {
        row.delete().then { (success: Bool) -> Void in
          self.dataLoader.removeRowForObject(row)
          NotificationCenter.default.postCRUDNotification(.delete, crudObject: row)
        }.catch { error in
            
        }
      }
    }
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
  
  open func scrollViewDidScroll(_ scrollView: UIScrollView) {
    
  }
  
  open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    
  }
  
  open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    
  }
  
}

