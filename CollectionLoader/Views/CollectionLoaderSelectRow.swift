//
//  CollectionLoaderRow.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 3/1/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation
import DataSource
import ViewMapper
import Eureka

public final class CollectionLoaderSelectRow<T: CellMapperAdapter, U: DataLoaderEngine>: SelectorRow<PushSelectorCell<U.T>, CollectionLoaderSelectController<T, U>>, RowType {
  
  public required init(tag: String?) {
    super.init(tag: tag)
  }
  
  public init(listAdapter: TableViewMapperAdapter<T, U>, tag: String? = nil, initializer: ((CollectionLoaderSelectRow) -> Void)? = nil) {
    super.init(tag: tag)
    
    presentationMode = .show(
      controllerProvider: ControllerProvider.callback {
        return CollectionLoaderSelectController(listAdapter: listAdapter) { _ in
          
        }
      },
      onDismiss: { vc in
        _ = vc.navigationController?.popViewController(animated: true)
      }
    )
    
    displayValueFor = {
      guard let value = $0 else { return "" }
      return  value.objectId
    }
    
    initializer?(self)
  }
}

public class CollectionLoaderSelectController<T: CellMapperAdapter, U: DataLoaderEngine>: ListLoaderController<TableViewMapperAdapter<T, U>>, TypedRowControllerType {
  public var row: RowOf<U.T>!
  public var onDismissCallback: ((UIViewController) -> ())?
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  required public init(listAdapter: TableViewMapperAdapter<T, U>, callback: ((UIViewController) -> ())? = nil) {
    super.init(listAdapter: listAdapter)
    
    listAdapter.cellAdapter.onSelectCell = { value, _ in
      if let value = value as? U.T {
        if self.row.value == value {
          self.row.value = nil
          
          if let index = self.dataLoader.rowsToDisplay.index(of: value) {
            self.listAdapter.tableView.deselectRow(at: IndexPath(row: index, section: 0), animated: true)
          }
        } else {
          self.row.value = value
        }
      }
    }
    
    onDismissCallback = callback
  }
  
  public required override init(listAdapter: TableViewMapperAdapter<T, U>) {
    super.init(listAdapter: listAdapter)
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
  }
  
  override open func refreshScrollView() {
    super.refreshScrollView()

    if let selectedObject = row.value, let index = dataLoader.rowsToDisplay.index(of: selectedObject), let tableView = scrollView as? UITableView {
      tableView.selectRow(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: .none)
    }
  }
}



public final class CollectionLoaderSelectMultipleRow<T: CellMapperAdapter, U: DataLoaderEngine>: SelectorRow<PushSelectorCell<Set<U.T>>, CollectionLoaderSelectMultipleController<T, U>>, RowType {
  
  public required init(tag: String?) {
    super.init(tag: tag)
  }
  
  public init(listAdapter: TableViewMapperAdapter<T, U>, tag: String? = nil, initializer: ((CollectionLoaderSelectMultipleRow) -> Void)? = nil) {
    super.init(tag: tag)
    
    presentationMode = .show(
      controllerProvider: ControllerProvider.callback {
        return CollectionLoaderSelectMultipleController(listAdapter: listAdapter) { _ in
          
        }
      },
      onDismiss: { vc in
        _ = vc.navigationController?.popViewController(animated: true)
      }
    )
    
    displayValueFor = {
      guard let object = $0 else { return "" }
      if object.count == 0 {
        return "None"
      } else if object.count == 1 {
        return object.first?.objectId
      } else {
        return "Multiple"
      }
    }
    
    initializer?(self)
  }
}

public class CollectionLoaderSelectMultipleController<T: CellMapperAdapter, U: DataLoaderEngine>: ListLoaderController<TableViewMapperAdapter<T, U>>, TypedRowControllerType {
  public var row: RowOf<Set<U.T>>!
  public var onDismissCallback: ((UIViewController) -> ())?
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  public init(listAdapter: TableViewMapperAdapter<T, U>, callback: ((UIViewController) -> ())? = nil) {
    super.init(listAdapter: listAdapter)
    
    listAdapter.tableView.allowsMultipleSelection = true
    
    listAdapter.cellAdapter.onSelectCell = { value, _ in
      var values: Set<U.T> = self.row.value ?? Set<U.T>()
      if let value = value as? U.T, !values.contains(value) {
        values.insert(value)
      }
      
      self.row.value = values
    }
    
    listAdapter.cellAdapter.onDeselectCell = { value, _ in
      var values: Set<U.T> = self.row.value ?? Set<U.T>()
      if let value = value as? U.T, values.contains(value) {
        values.remove(value)
      }
      
      self.row.value = values
    }
    
    onDismissCallback = callback
  }
  
  public required override init(listAdapter: TableViewMapperAdapter<T, U>) {
    super.init(listAdapter: listAdapter)
  }
  
  override open func refreshScrollView() {
    super.refreshScrollView()
    
    if let rows = row.value, let tableView = scrollView as? UITableView, rows.count > 0 {
      for row in rows {
        if let index = dataLoader.rowsToDisplay.index(of: row) {
          tableView.selectRow(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: .none)
        }
      }
    }
  }
}
