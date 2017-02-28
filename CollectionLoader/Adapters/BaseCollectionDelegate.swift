//
//  BaseCollectionDelegate.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/28/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation

public protocol BaseCollectionDelegate: class {
  func didTapCell<T>(forRow: T)
}
