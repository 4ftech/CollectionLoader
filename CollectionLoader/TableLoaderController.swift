//
//  TableLoaderController.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 6/12/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation
import ViewMapper

open class TableLoaderController<A, E>: ListLoaderController<A> where A:TableListAdapter<E>, E:DataLoaderEngine {
  public var tableView: UITableView {
    return listAdapter.tableView
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  public init(dataLoader: DataLoader<E> = DataLoader<E>(dataLoaderEngine: E())) {
    super.init(listAdapter: A(dataLoader: dataLoader))
  }
  
  public override init(listAdapter: A) {
    super.init(listAdapter: listAdapter)
  }
}