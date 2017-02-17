//
//  SearchResultTableViewCell.swift
//  buk
//
//  Created by Nick Kuyakanon on 6/17/15.
//  Copyright (c) 2015 4f Tech, LLC. All rights reserved.
//

import Foundation

class SingleLineIconCell: UITableViewCell {
  static let cellHeight: CGFloat = 58
  static let mainImageSize: CGSize = CGSize(width: 42, height: 42)
  
  @IBOutlet weak var mainImageView: UIImageView!
  @IBOutlet weak var iconImageView: UIImageView!

  @IBOutlet weak var mainLabel: UILabel!
  
//  var imageCancellationToken: Operation?
//  
//  func loadMainImageFromUrl(_ urlString: String?) {
//    if let urlString = urlString, let url = URL(string: urlString) {
//      imageCancellationToken?.cancel()
//      
//      let thisCancellationToken = Operation()
//      imageCancellationToken = thisCancellationToken
//      
//      mainImageView.hnk_setImageFromURL(url, format: UIUtils.iconCellImageFormat) { image in
//        self.mainImageView.hnk_setImage(image, animated: true, success: nil)
//        self.iconImageView.isHidden = true
//      }
//    }
//  }
}
