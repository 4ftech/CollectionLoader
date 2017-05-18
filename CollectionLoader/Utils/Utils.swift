//
//  Utils.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation

class Utils {
  class func performOnMainThread(_ fn: @escaping () -> Void) {
    DispatchQueue.main.async(execute: {
      fn()
    })
  }

}
