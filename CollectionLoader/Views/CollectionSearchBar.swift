//
//  CollectionSearchBar.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//


import Foundation
import RxSwift
import RxCocoa

@objc protocol CollectionSearchBarDelegate {
  func searchBarTextDidChange(_ searchBar: CollectionSearchBar)
  @objc optional func searchBarTextDidChangeAfterThrottle(_ searchBar: CollectionSearchBar)
  @objc optional func searchBarTextDidBeginEditing(_ searchBar: CollectionSearchBar)
  @objc optional func searchBarDidTapClearButton(_ searchBar: CollectionSearchBar)
}

class CollectionSearchBar: UIView {
  @IBOutlet weak var container: UIView!
  @IBOutlet weak var textField: UITextField!
  @IBOutlet weak var clearButton: UIButton!
  @IBOutlet weak var searchIcon: UIImageView!
  
  var clearAlwaysVisible = false
  let disposeBag = DisposeBag()
  
  weak var delegate: CollectionSearchBarDelegate?
  var throttle: Double? {
    didSet {
      if let time = throttle {
        textField.rx.textInput.text
          .distinctUntilChanged({ $0 }, comparer: { $0 == $1 })
          .takeUntil(self.rx.deallocated)
          .throttle(time, scheduler: MainScheduler.instance).subscribe(onNext: { [weak self] text in
            if let realSelf = self {
              self?.delegate?.searchBarTextDidChangeAfterThrottle?(realSelf)
            }
          }).addDisposableTo(disposeBag)
      }
    }
  }
  
  var text: String? {
    return textField.text
  }
  
  func setText(_ text: String?) {
    textField.text = text
  }
  
  static func newInstance() -> CollectionSearchBar {
    return Bundle.main.loadNibNamed("CollectionSearchBar", owner: nil, options: nil)!.first as! CollectionSearchBar
  }
  
  @IBAction func didTapClearButton(_ sender: AnyObject) {
    delegate?.searchBarDidTapClearButton?(self)
    
    if !clearAlwaysVisible {
      if let text = text , !text.isEmpty {
        textField.text = nil
        textFieldDidChange(self)
      }
      
      clearButton.isHidden = true
    }
  }
  
  @IBAction func textFieldDidChange(_ sender: AnyObject) {
    if !clearAlwaysVisible {
      if let text = text , !text.isEmpty {
        clearButton.isHidden = false
      } else {
        clearButton.isHidden = true
      }
    }
    
    delegate?.searchBarTextDidChange(self)
  }
}

extension CollectionSearchBar: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    delegate?.searchBarTextDidBeginEditing?(self)
  }
}
