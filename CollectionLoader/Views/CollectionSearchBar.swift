//
//  CollectionSearchBar.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//


import Foundation
import RxSwift
import RxCocoa

public protocol CollectionSearchBarDelegate: class {
  func searchBarTextDidChange(_ searchBar: CollectionSearchBar)
  func searchBarTextDidChangeAfterThrottle(_ searchBar: CollectionSearchBar)
  func searchBarTextDidBeginEditing(_ searchBar: CollectionSearchBar)
  func searchBarDidTapClearButton(_ searchBar: CollectionSearchBar)
}

open class CollectionSearchBar: UIView {
  @IBOutlet public var textField: UITextField!
  @IBOutlet public var container: UIView!
  @IBOutlet public var clearButton: UIButton!
  @IBOutlet public var searchIcon: UIImageView!
  
  public var clearAlwaysVisible = false {
    didSet {
      if clearAlwaysVisible {
        clearButton.isHidden = false
      }
    }
  }
  
  let disposeBag = DisposeBag()
  
  weak var delegate: CollectionSearchBarDelegate?
  
  public var throttle: Double? {
    didSet {
      if let time = throttle {
        textField.rx.text
          .throttle(time, scheduler: MainScheduler.instance)
          .distinctUntilChanged({ $0 }, comparer: { $0 == $1 })
          .takeUntil(self.rx.deallocated)
          .subscribe(onNext: { [weak self] text in
            self?.delegate?.searchBarTextDidChangeAfterThrottle(self!)
          })
          .addDisposableTo(disposeBag)
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
    return Bundle(for: self).loadNibNamed("CollectionSearchBar", owner: nil, options: nil)!.first as! CollectionSearchBar
  }
  
  open override func awakeFromNib() {
    super.awakeFromNib()
    
    clearButton.addTarget(self, action: #selector(didTapClearButton(_:)), for: .touchUpInside)
    textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    
    if !clearAlwaysVisible {
      clearButton.isHidden = true
    }
  }
  
  func didTapClearButton(_ sender: AnyObject) {
    delegate?.searchBarDidTapClearButton(self)
    
    if !clearAlwaysVisible {
      if let text = text , !text.isEmpty {
        textField.text = nil
        textFieldDidChange(self)
      }
      
      clearButton.isHidden = true
    }
  }
  
  func textFieldDidChange(_ sender: AnyObject) {
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
  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
  
  public func textFieldDidBeginEditing(_ textField: UITextField) {
    delegate?.searchBarTextDidBeginEditing(self)
  }
}
