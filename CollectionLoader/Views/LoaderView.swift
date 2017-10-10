//
//  LoaderView.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation

public class LoaderView: UIView {
  @IBOutlet weak public var emptyContainer: UIView!
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
  
  override public func awakeFromNib() {
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
  
  public func showSpinner() {
    isHidden = false
    hideEmptyView()
    activityIndicator.isHidden = false
    activityIndicator.startAnimating()
  }
  
  public func hideSpinner() {
    activityIndicator.isHidden = true
    activityIndicator.stopAnimating()
  }
  
  
  public func hideEmptyView() {
    emptyContainer.isHidden = true
  }
  
  public func showEmptyView() {
    isHidden = false
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
