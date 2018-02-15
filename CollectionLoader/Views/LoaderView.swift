//
//  LoaderView.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation

open class LoaderView: UIView {
  @IBOutlet weak public var emptyContainer: UIView!
  @IBOutlet weak public var loaderContainer: UIView!
  @IBOutlet weak public var imageView: UIImageView!
  @IBOutlet weak public var label: UILabel!
  @IBOutlet weak public var subtitleLabel: UILabel!
  @IBOutlet weak public var activityIndicator: UIActivityIndicatorView!
  @IBOutlet weak public var button: UIButton!
  @IBOutlet weak public var imageHeightConstraint: NSLayoutConstraint!
  
  let imageHeight: CGFloat = 128
  var buttonAction: (() -> Void)?
  
  public class func newInstance(owner: AnyObject? = nil, content: EmptyViewContent? = nil) -> LoaderView {
    var nibContents: [Any]!
    
    if let _ = Bundle.main.path(forResource: "LoaderView", ofType: "nib") {
      nibContents = Bundle.main.loadNibNamed("LoaderView", owner: nil, options: nil)!
    } else {
      nibContents = Bundle(for: self).loadNibNamed("LoaderView", owner: owner, options: nil)!
    }
    
    let loaderView = nibContents.first as! LoaderView
    loaderView.loadContent(content)
    
    return loaderView
  }
  
  open override func awakeFromNib() {
    super.awakeFromNib()
    
    isHidden = true
  }
  
  public func loadContent(_ emptyViewContent: EmptyViewContent?) {
    label.text = emptyViewContent?.message
    subtitleLabel.text = emptyViewContent?.subtitle
    
    if let image = emptyViewContent?.image {
      imageView.image = image
      imageHeightConstraint.constant = imageHeight
    } else {
      imageView.image = nil
      imageHeightConstraint.constant = 0
    }
    
    if let text = emptyViewContent?.buttonText, let action = emptyViewContent?.buttonAction {
      buttonAction = action
      
      button.setTitle(text, for: .normal)
      button.addTarget(self, action: #selector(executeButtonAction(_ :)), for: .touchUpInside)
      button.isHidden = false
    } else {
      button.isHidden = true
    }
  }
  
  func executeButtonAction(_ sender: AnyObject) {
    buttonAction?()
  }
  
  open func showSpinner() {
    isHidden = false
    alpha = 1.0
    
    hideEmptyView()
    
    if loaderContainer.subviews.count > 0 {
      activityIndicator.isHidden = true
      
      loaderContainer.isHidden = false
      loaderContainer.alpha = 1.0
    } else {
      loaderContainer.isHidden = true
      activityIndicator.isHidden = false
      activityIndicator.startAnimating()
    }
  }
  
  open func hideSpinner() {
    UIView.animate(
      withDuration: Const.fadeDuration,
      delay: 0,
      options: [.allowUserInteraction, .beginFromCurrentState],
      animations: {
        self.loaderContainer.alpha = 0.0
      },
      completion: { complete in
        if complete {
          self.loaderContainer.isHidden = true
        }
      }
    )
 
    activityIndicator.isHidden = true
    activityIndicator.stopAnimating()
  }
  
  
  open func hideEmptyView() {
    emptyContainer.isHidden = true
  }
  
  open func showEmptyView() {
    isUserInteractionEnabled = true
    isHidden = false
    alpha = 1.0
    
    hideSpinner()
    emptyContainer.isHidden = false
  }
  
  public func showContent(_ emptyViewContent: EmptyViewContent?) {
    self.loadContent(emptyViewContent)
    self.showEmptyView()
  }
}

public class EmptyViewContent: NSObject {
  public var image: UIImage?
  public var message: String?
  public var subtitle: String?
  public var buttonText: String?
  public var buttonAction: (() -> Void)?
  
  public init(image: UIImage? = nil, message: String? = nil, subtitle: String? = nil, buttonText: String? = nil, buttonAction: (() -> Void)? = nil) {
    self.image = image
    self.message = message
    self.subtitle = subtitle
    self.buttonText = buttonText
    self.buttonAction = buttonAction
  }
}
