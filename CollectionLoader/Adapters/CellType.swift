//
//  CellType.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/24/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation

public class CellType: NSObject {
  var identifier: String!
  var nib: UINib!
  
  public required init(identifier: String, nib: UINib) {
    super.init()
    
    self.identifier = identifier
    self.nib = nib
  }
}
