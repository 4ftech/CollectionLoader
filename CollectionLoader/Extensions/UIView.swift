//
//  UIView.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/18/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation

// MARK: - UIView
extension UIView {
  
  @IBInspectable var cornerRadius: CGFloat {
    get {
      return layer.cornerRadius
    }
    set {
      layer.cornerRadius = newValue
      layer.masksToBounds = newValue > 0
    }
  }
  
  @IBInspectable var borderWidth: CGFloat {
    get {
      return layer.borderWidth
    }
    set {
      layer.borderWidth = newValue
    }
  }
  
  @IBInspectable var borderColor: UIColor? {
    get {
      if let color = layer.borderColor {
        return UIColor(cgColor: color)
      }
      
      return nil
    }
    set {
      layer.borderColor = newValue?.cgColor
    }
  }
  
  @IBInspectable var leftBorderWidth: CGFloat {
    get {
      return 0.0   // Just to satisfy property
    }
    set {
      let line = BorderView(frame: CGRect(x: 0.0, y: 0.0, width: newValue, height: bounds.height))
      line.translatesAutoresizingMaskIntoConstraints = false
      if let color = layer.borderColor {
        line.backgroundColor = UIColor(cgColor: color)
      }
      self.addSubview(line)
      
      let views: [String: AnyObject] = ["line": line]
      let metrics: [String: AnyObject] = ["lineWidth": newValue as AnyObject]
      addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[line(==lineWidth)]", options: [], metrics: metrics, views: views))
      addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[line]|", options: [], metrics: nil, views: views))
    }
  }
  
  @IBInspectable var topBorderWidth: CGFloat {
    get {
      return 0.0   // Just to satisfy property
    }
    set {
      let line = BorderView(frame: CGRect(x: 0.0, y: 0.0, width: bounds.width, height: newValue))
      line.translatesAutoresizingMaskIntoConstraints = false
      line.backgroundColor = borderColor
      self.addSubview(line)
      
      let views: [String: AnyObject] = ["line": line]
      let metrics: [String: AnyObject] = ["lineWidth": newValue as AnyObject]
      addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[line]|", options: [], metrics: nil, views: views))
      addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[line(==lineWidth)]", options: [], metrics: metrics, views: views))
    }
  }
  
  @IBInspectable var rightBorderWidth: CGFloat {
    get {
      return 0.0   // Just to satisfy property
    }
    set {
      let line = BorderView(frame: CGRect(x: bounds.width, y: 0.0, width: newValue, height: bounds.height))
      line.translatesAutoresizingMaskIntoConstraints = false
      line.backgroundColor = borderColor
      self.addSubview(line)
      
      let views: [String: AnyObject] = ["line": line]
      let metrics: [String: AnyObject] = ["lineWidth": newValue as AnyObject]
      addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[line(==lineWidth)]|", options: [], metrics: metrics, views: views))
      addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[line]|", options: [], metrics: nil, views: views))
    }
  }
  @IBInspectable var bottomBorderWidth: CGFloat {
    get {
      return 0.0   // Just to satisfy property
    }
    set {
      let line = BorderView(frame: CGRect(x: 0.0, y: bounds.height, width: bounds.width, height: newValue))
      line.translatesAutoresizingMaskIntoConstraints = false
      line.backgroundColor = borderColor
      self.addSubview(line)
      
      let views: [String: AnyObject] = ["line": line]
      let metrics: [String: AnyObject] = ["lineWidth": newValue as AnyObject]
      addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[line]|", options: [], metrics: nil, views: views))
      addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[line(==lineWidth)]|", options: [], metrics: metrics, views: views))
    }
  }
  
  func removeAllSubviews() {
    for subview in self.subviews {
      subview.removeFromSuperview()
    }
  }
  
  func removeAllBorders() {
    for subview in self.subviews {
      if subview is BorderView {
        subview.removeFromSuperview()
      }
    }
  }
}

class BorderView: UIView { }
