//
//  CutoutView.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 11/3/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation

public class CutoutView: UIView {
  @IBOutlet var placeholders: [UIView] = []
  var cutoutColor: UIColor = UIColor.white
  
  public override func awakeFromNib() {
    super.awakeFromNib()
    
    for view in self.subviews {
      view.alpha = 0.0
    }
    
    self.cutoutColor = self.backgroundColor ?? UIColor.white
    self.backgroundColor = UIColor.clear
  }
  
  public override func draw(_ rect: CGRect) {
    super.draw(rect)
    
    guard let context = UIGraphicsGetCurrentContext() else { return }
    
    context.setFillColor(self.cutoutColor.cgColor)
    context.fill(self.bounds)
    
    for view in placeholders {
      context.setBlendMode(.clear)
      context.setFillColor(UIColor.clear.cgColor)
      
      if view.superview == self {
        context.fill(view.frame)
      } else {
        var superview = view.superview!
        var frame = view.frame
        while superview != self {
          frame.origin.x += superview.frame.origin.x
          frame.origin.y += superview.frame.origin.y
          superview = superview.superview!
        }
        
        context.fill(frame)
      }
    }
  }
}
