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

public final class CollectionLoaderSelectRow<C: CellMapperAdapter, E>: SelectorRow<PushSelectorCell<C.T.T>>, RowType where E: DataLoaderEngine<C.T.T>, C.T.T: Equatable {
  
  public typealias T = C.T.T
  public var listAdapter: ListCellMapperAdapter<C, E>!
  public var dataLoader: DataLoader<T, E> {
    return listAdapter.dataLoader
  }
  
  public required init(tag: String?) {
    super.init(tag: tag)
  }
  
  public init(listAdapter: ListCellMapperAdapter<C, E>,
              tag: String? = nil,
              initializer: ((CollectionLoaderSelectRow) -> Void)? = nil) {
    
    super.init(tag: tag)
    
    self.listAdapter = listAdapter
    self.setup(initializer: initializer)
  }
  
  public override func customDidSelect() {
    cell.formViewController()?.show(CollectionLoaderSelectController(listAdapter: listAdapter), sender: self)
  }
  
  public func setup(initializer: ((CollectionLoaderSelectRow) -> Void)? = nil) {
    displayValueFor = {
      guard let value = $0 else { return "" }
      return  value.objectId
    }

    initializer?(self)
  }
}

public class CollectionLoaderSelectController<C: CellMapperAdapter, E>: ListCellMapperController<UITableView, C, E>, TypedRowControllerType where E: DataLoaderEngine<C.T.T>, C.T.T: Equatable {
  
  public typealias T = C.T.T
  public var row: RowOf<T>!
  public var onDismissCallback: ((UIViewController) -> ())?
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  required public init(listAdapter: ListCellMapperAdapter<C, E>,
                       callback: ((UIViewController) -> ())? = nil) {
    
    super.init(listAdapter: listAdapter, viewHandler: ListViewHandler<UITableView>())
    
    self.cellAdapter.onSelectCell = { [weak self] (value, _) in
      if self?.row.value == value {
        self?.row.value = nil
        
        if let index = self?.dataLoader.rowsToDisplay.index(of: value) {
          self?.tableView.deselectRow(at: IndexPath(row: index, section: 0), animated: true)
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

    if let selectedObject = row.value, let index = dataLoader.rowsToDisplay.index(of: selectedObject) {
      self.tableView.selectRow(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: .none)
    }
  }
}


public final class CollectionLoaderSelectMultipleRow<C: CellMapperAdapter, E>: SelectorRow<PushSelectorCell<Set<C.T.T>>>, RowType where E: DataLoaderEngine<C.T.T>, C.T.T: Equatable {
  
  public typealias T = C.T.T
  public var listAdapter: ListCellMapperAdapter<C, E>!
  public var dataLoader: DataLoader<T, E> {
    return listAdapter.dataLoader
  }

  public required init(tag: String?) {
    super.init(tag: tag)
  }

  public init(listAdapter: ListCellMapperAdapter<C, E>,
              tag: String? = nil,
              initializer: ((CollectionLoaderSelectMultipleRow) -> Void)? = nil) {
    
    super.init(tag: tag)
    
    self.listAdapter = listAdapter
    
    self.setup(initializer: initializer)
  }

  public override func customDidSelect() {
    cell.formViewController()?.show(CollectionLoaderSelectMultipleController(listAdapter: listAdapter), sender: self)
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

public class CollectionLoaderSelectMultipleController<C: CellMapperAdapter, E>: ListCellMapperController<UITableView, C, E>, TypedRowControllerType where E: DataLoaderEngine<C.T.T> {
  
  public typealias T = C.T.T

  public var row: RowOf<Set<T>>!
  public var onDismissCallback: ((UIViewController) -> ())?

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)

  }

  public init(listAdapter: ListCellMapperAdapter<C, E>, callback: ((UIViewController) -> ())? = nil) {
    super.init(listAdapter: listAdapter, viewHandler: ListViewHandler<UITableView>())
    
    self.allowSearch = true

    self.tableView.allowsMultipleSelection = true
    self.cellAdapter.onSelectCell = { [weak self] (value, _) in
      var values: Set<T> = self?.row.value ?? Set<T>()
      if !values.contains(value) {
        values.insert(value)
      }

      self?.row.value = values
    }

    self.cellAdapter.onDeselectCell = { [weak self] (value, _) in
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

    if let rows = row.value, rows.count > 0 {
      for row in rows {
        if let index = dataLoader.rowsToDisplay.index(of: row) {
          self.tableView.selectRow(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: .none)
        }
      }
    }
  }
}

