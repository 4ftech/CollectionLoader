//
//  LoaderCell.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 11/2/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

open class LoaderCell: UIView {
  @IBOutlet weak public var cutoutView: CutoutView!
  
  open override func awakeFromNib() {
    super.awakeFromNib()
    
    let gradientLayer = LoaderGradientLayer()
    gradientLayer.frame = self.bounds
    self.layer.insertSublayer(gradientLayer, at: 0)
  }
  
  
}


