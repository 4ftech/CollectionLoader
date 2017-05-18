//
//  UIView.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/18/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation

public enum ContainerViewEdge {
  case top, bottom, fill
}

// MARK: - UIView
public extension UIView {
  
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
  
  func fill(withView view: UIView, edgeInsets: UIEdgeInsets? = nil) {
    self.addView(view, onEdge: .fill, edgeInsets: edgeInsets)
  }
  
  func addView(_ view: UIView, onEdge edge: ContainerViewEdge, edgeInsets: UIEdgeInsets? = nil) {
    view.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(view)
    
    let hVisual = "|-(==leftInset)-[view]-(==rightInset)-|"
    
    var vVisual: String!
    switch edge {
    case .top:
      vVisual = "V:|-(==topInset)-[view]"
    case .bottom:
      vVisual = "V:[view]-(==bottomInset)-|"
    default:
      vVisual = "V:|-(==topInset)-[view]-(==bottomInset)-|"
    }
    
    let hConstraints = NSLayoutConstraint.constraints(
      withVisualFormat: hVisual,
      options: [],
      metrics: [
        "leftInset": edgeInsets?.left ?? 0,
        "rightInset": edgeInsets?.right ?? 0,
        ],
      views: ["view": view])
    let vConstraints = NSLayoutConstraint.constraints(
      withVisualFormat: vVisual,
      options: [],
      metrics: [
        "topInset": edgeInsets?.top ?? 0,
        "bottomInset": edgeInsets?.bottom ?? 0,
        ],
      views: ["view": view])
    
    self.addConstraints(hConstraints + vConstraints)
  }
  
}

class BorderView: UIView { }
