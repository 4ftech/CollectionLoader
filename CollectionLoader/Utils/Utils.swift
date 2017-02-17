//
//  Utils.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//

import Foundation

class Utils {
  enum ContainerEdge {
    case top, bottom, fill
  }

  static let searchBarHeight: CGFloat = 44
  
  class func performOnMainThread(_ fn: @escaping () -> Void) {
    DispatchQueue.main.async(execute: {
      fn()
    })
  }
 
  static func fillContainer(_ container: UIView, withView view: UIView, edgeInsets: UIEdgeInsets? = nil) {
    addView(view, toContainer: container, onEdge: .fill, edgeInsets: edgeInsets)
  }
  
  static func addView(_ view: UIView, toContainer container: UIView, onEdge edge: ContainerEdge, edgeInsets: UIEdgeInsets? = nil) {
    view.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(view)
    
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
    
    container.addConstraints(hConstraints + vConstraints)
  }

}
