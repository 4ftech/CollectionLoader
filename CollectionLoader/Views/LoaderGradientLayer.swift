//
//  LoaderGradientLayer.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 11/2/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation
import CoreGraphics

public class LoaderGradientLayer: CAGradientLayer {
  public override init() {
    super.init()
    
    self.startPoint = CGPoint(x: -1, y: 0)
    self.endPoint = CGPoint(x: 2, y: 0)
    
    let backgroundColor: UIColor = UIColor(red: (235.0/255.0), green: (235.0/255.0), blue: (235.0/255.0), alpha: 1.0)
    let firstStopColor: UIColor = UIColor(red: (238.0/255.0), green: (238.0/255.0), blue: (238.0/255.0), alpha: 1.0)
    let secondStopColor: UIColor = UIColor(red: (221.0/255.0), green: (221.0/255.0), blue:(221.0/255.0) , alpha: 1.0)
    
    self.colors = [
      backgroundColor.cgColor,
      firstStopColor.cgColor,
      secondStopColor.cgColor,
      firstStopColor.cgColor,
      backgroundColor.cgColor
    ]
    
    let startLocations = [
      NSNumber(value: -1.0),
      NSNumber(value: -0.75),
      NSNumber(value: -0.5),
      NSNumber(value: -0.25),
      NSNumber(value: 0)
    ]
    self.locations = startLocations
    
    let gradientAnimation = CABasicAnimation(keyPath: "locations")
    gradientAnimation.fromValue = startLocations
    
    gradientAnimation.toValue = [
      NSNumber(value: 1),
      NSNumber(value: 1.25),
      NSNumber(value: 1.5),
      NSNumber(value: 1.75),
      NSNumber(value: 2)
    ]
    
    gradientAnimation.repeatCount = Float.infinity
    gradientAnimation.fillMode = kCAFillModeForwards
    gradientAnimation.isRemovedOnCompletion = false
    gradientAnimation.duration = 2
    
    self.add(gradientAnimation, forKey: "locations")
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}
