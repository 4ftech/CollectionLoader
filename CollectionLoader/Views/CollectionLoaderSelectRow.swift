//
//  CollectionLoaderRow.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 3/1/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation
import DataSource
import ViewMapper
import Eureka

public final class CollectionLoaderSelectRow<U: DataLoaderEngine, V: ViewMappable>: SelectorRow<PushSelectorCell<U.T>, CollectionLoaderSelectController<U, V>>, RowType where U.T == V.T {
  
  public required init(tag: String?) {
    super.init(tag: tag)
  }
  
  public init(dataLoaderEngine: U, cellAdapter: NibCellMapperAdapter<V>, tag: String? = nil, initializer: ((CollectionLoaderSelectRow) -> Void)? = nil) {
    super.init(tag: tag)
    
    presentationMode = .show(
      controllerProvider: ControllerProvider.callback {
        return CollectionLoaderSelectController(dataLoaderEngine: dataLoaderEngine, cellAdapter: cellAdapter) { _ in
          
        }
      },
      onDismiss: { vc in
        _ = vc.navigationController?.popViewController(animated: true)
      }
    )
    
    displayValueFor = {
      guard let object = $0 else { return "" }
      return  object.objectId
    }
    
    initializer?(self)
  }
}

public class CollectionLoaderSelectController<U: DataLoaderEngine, V: ViewMappable>: CollectionLoaderController<TableViewMapperAdapter<NibCellMapperAdapter<V>, U>>, TypedRowControllerType where U.T == V.T {
  public var row: RowOf<U.T>!
  public var onDismissCallback: ((UIViewController) -> ())?
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  required public init(dataLoaderEngine: U, cellAdapter: NibCellMapperAdapter<V>, callback: ((UIViewController) -> ())? = nil) {
    let collectionAdapter = TableViewMapperAdapter(cellAdapter: cellAdapter, dataLoaderEngine: dataLoaderEngine)
    
//    if let selectedId = row.value?.objectId {
//      collectionAdapter.selectedIds = [selectedId]
//    }
    
    super.init(collectionAdapter: collectionAdapter)
    
    cellAdapter.onTapCell = { value, _ in
      self.row.value = value
    }
    
    onDismissCallback = callback
  }
}



public final class CollectionLoaderSelectMultipleRow<U: DataLoaderEngine, V: ViewMappable>: SelectorRow<PushSelectorCell<Set<U.T>>, CollectionLoaderSelectMultipleController<U, V>>, RowType where U.T == V.T {
  
  public required init(tag: String?) {
    super.init(tag: tag)
  }
  
  public init(dataLoaderEngine: U, cellAdapter: NibCellMapperAdapter<V>, tag: String? = nil, initializer: ((CollectionLoaderSelectMultipleRow) -> Void)? = nil) {
    super.init(tag: tag)
    
    presentationMode = .show(
      controllerProvider: ControllerProvider.callback {
        return CollectionLoaderSelectMultipleController(dataLoaderEngine: dataLoaderEngine, cellAdapter: cellAdapter) { _ in
          
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

public class CollectionLoaderSelectMultipleController<U: DataLoaderEngine, V: ViewMappable>: CollectionLoaderController<TableViewMapperAdapter<NibCellMapperAdapter<V>, U>>, TypedRowControllerType where U.T == V.T {
  public var row: RowOf<Set<U.T>>!
  public var onDismissCallback: ((UIViewController) -> ())?
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  required public init(dataLoaderEngine: U, cellAdapter: NibCellMapperAdapter<V>, callback: ((UIViewController) -> ())? = nil) {
    let collectionAdapter = TableViewMapperAdapter(cellAdapter: cellAdapter, dataLoaderEngine: dataLoaderEngine)

//    if let rows = row.value?.filter({ $0.objectId != nil }), rows.count > 0 {
//      collectionAdapter.selectedIds = rows.map { $0.objectId! }
//    }
    
    super.init(collectionAdapter: collectionAdapter)
    
    cellAdapter.onTapCell = { value, _ in
      var values = self.row.value ?? []
      if values.contains(value) {
        values.remove(value)
      } else {
        values.insert(value)
      }
      
      self.row.value = values
    }
    
    onDismissCallback = callback
  }
}
