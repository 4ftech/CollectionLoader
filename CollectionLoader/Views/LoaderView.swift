//
//  LoaderView.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation
import Spring

class LoaderView: SpringView {
  @IBOutlet weak var emptyContainer: SpringView!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var label: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var button: UIButton!
  @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
  
  let imageHeight: CGFloat = 128
  var buttonAction: (() -> Void)?
  
  class func newInstance(_ owner: AnyObject? = nil, content: EmptyViewContent? = nil) -> LoaderView {
    let loaderView = Bundle(for: self).loadNibNamed("LoaderView", owner: owner, options: nil)!.first as! LoaderView
    loaderView.loadContent(content)
    
    return loaderView
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    isHidden = true
  }
  
  func loadContent(_ emptyViewContent: EmptyViewContent?) {
    label.text = emptyViewContent?.message
    subtitleLabel.text = emptyViewContent?.subtitle
    
    if let imageName = emptyViewContent?.imageName {
      imageView.image = UIImage(named: imageName)
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
  
  func showSpinner() {
    isHidden = false
    hideEmptyView()
    activityIndicator.isHidden = false
    activityIndicator.startAnimating()
  }
  
  func hideSpinner() {
    activityIndicator.isHidden = true
    activityIndicator.stopAnimating()
  }
  
  
  func hideEmptyView() {
    emptyContainer.isHidden = true
  }
  
  func showEmptyView() {
    isHidden = false
    hideSpinner()
    emptyContainer.isHidden = false
  }
}

public class EmptyViewContent: NSObject {
  var imageName: String?
  var message: String?
  var subtitle: String?
  var buttonText: String?
  var buttonAction: (() -> Void)?
  
  public init(imageName: String? = nil, message: String? = nil, subtitle: String? = nil, buttonText: String? = nil, buttonAction: (() -> Void)? = nil) {
    self.imageName = imageName
    self.message = message
    self.subtitle = subtitle?.uppercased()
    self.buttonText = buttonText
    self.buttonAction = buttonAction
  }
}
