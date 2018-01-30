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
import Parse

public final class CollectionLoaderSelectRow<C: CellMapperAdapter>: SelectorRow<PushSelectorCell<C.T.T>, CollectionLoaderSelectController<C>>, RowType where C.T.T: BaseDataModel {
  public typealias T = C.T.T
  public var dataLoader: DataLoader<T>!
  
  public required init(tag: String?) {
    super.init(tag: tag)
  }
  
  public init(listAdapter: ListCellMapperAdapter<C>, tag: String? = nil, initializer: ((CollectionLoaderSelectRow) -> Void)? = nil) {
    super.init(tag: tag)
    
    self.dataLoader = listAdapter.dataLoader
    
    presentationMode = .show(
      controllerProvider: ControllerProvider.callback {
        return CollectionLoaderSelectController(listAdapter: listAdapter) { _ in
          
        }
      },
      onDismiss: { vc in
        _ = vc.navigationController?.popViewController(animated: true)
      }
    )
    
    self.setup(initializer: initializer)
  }
  
  public func setup(initializer: ((CollectionLoaderSelectRow) -> Void)? = nil) {
    displayValueFor = {
      guard let value = $0 else { return "" }
      return  value.objectId
    }
    
    initializer?(self)
  }
}

public class CollectionLoaderSelectController<C: CellMapperAdapter>: ListCellMapperController<C>, TypedRowControllerType where C.T.T: BaseDataModel {
  public typealias T = C.T.T
  public var row: RowOf<T>!
  public var onDismissCallback: ((UIViewController) -> ())?
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  required public init(listAdapter: ListCellMapperAdapter<C>, callback: ((UIViewController) -> ())? = nil) {
    super.init(listType: .table, listAdapter: listAdapter)

    self.cellAdapter.onSelectCell = { [weak self] (_, value, _) in
      if self?.row.value == value {
        self?.row.value = nil
        
        if let index = self?.dataLoader.rowsToDisplay.index(of: value) {
          self?.tableView?.deselectRow(at: IndexPath(row: index, section: 0), animated: true)
        }
      } else {
        self?.row.value = value
      }
    }

    self.allowSearch = true
    self.onDismissCallback = callback
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


public final class CollectionLoaderSelectMultipleRow<C: CellMapperAdapter>: SelectorRow<PushSelectorCell<Set<C.T.T>>, CollectionLoaderSelectMultipleController<C>>, RowType where C.T.T: BaseDataModel {
  public typealias T = C.T.T
  public var dataLoader: DataLoader<T>!

  public required init(tag: String?) {
    super.init(tag: tag)
  }

  public init(listAdapter: ListCellMapperAdapter<C>, tag: String? = nil, initializer: ((CollectionLoaderSelectMultipleRow) -> Void)? = nil) {
    super.init(tag: tag)
    
    self.dataLoader = listAdapter.dataLoader
    
    presentationMode = .show(
      controllerProvider: ControllerProvider.callback {
        return CollectionLoaderSelectMultipleController(listAdapter: listAdapter) { _ in
          
        }
      },
      onDismiss: { vc in
        _ = vc.navigationController?.popViewController(animated: true)
      }
    )
    
    self.setup(initializer: initializer)
  }

  public func setup(initializer: ((CollectionLoaderSelectMultipleRow) -> Void)? = nil) {
    displayValueFor = {
      guard let object = $0 else { return "" }
      if object.count == 0 {
        return ""
      } else if object.count == 1 {
        return object.first?.objectId
      } else {
        return "Multiple"
      }
    }
    
    initializer?(self)
  }
}

public class CollectionLoaderSelectMultipleController<C: CellMapperAdapter>: ListCellMapperController<C>, TypedRowControllerType where C.T.T: BaseDataModel {
  public typealias T = C.T.T

  public var row: RowOf<Set<T>>!
  public var onDismissCallback: ((UIViewController) -> ())?

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)

  }

  public init(listAdapter: ListCellMapperAdapter<C>, callback: ((UIViewController) -> ())? = nil) {
    super.init(listType: .table, listAdapter: listAdapter)
    
    self.allowSearch = true

    self.tableView?.allowsMultipleSelection = true
    self.cellAdapter.onSelectCell = { [weak self] (_, value, _) in
      var values: Set<T> = self?.row.value ?? Set<T>()
      if !values.contains(value) {
        values.insert(value)
      }

      self?.row.value = values
    }

    self.cellAdapter.onDeselectCell = { [weak self] (_, value, _) in
      var values: Set<T> = self?.row.value ?? Set<T>()
      if values.contains(value) {
        values.remove(value)
      }

      self?.row.value = values
    }

    onDismissCallback = callback
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

