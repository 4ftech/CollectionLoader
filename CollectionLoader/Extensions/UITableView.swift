//
//  UITableView.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation

extension UITableView {
  func performBatchUpdates(_ updates: () -> Void, completion: ((Bool) -> Void)?) {
    CATransaction.begin()
    CATransaction.setCompletionBlock() {
      completion?(true)
    }
    beginUpdates()
    updates()
    endUpdates()
    CATransaction.commit()
  }
}
