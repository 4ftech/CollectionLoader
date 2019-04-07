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
  @IBOutlet public var clearButton: UIButton?
  @IBOutlet public var searchIcon: UIImageView!
  
  public var clearAlwaysVisible = false {
    didSet {
      if clearAlwaysVisible {
        if let clearButton = clearButton {
          clearButton.isHidden = false
        } else {
          textField.clearButtonMode = .always
        }
      } else if clearButton == nil {
        textField.clearButtonMode = .whileEditing
      }
      
    }
  }
  
  let disposeBag = DisposeBag()
  var throttledText: String = ""
  
  weak public var delegate: CollectionSearchBarDelegate?
  
  public var throttle: Double? {
    didSet {
      if let time = throttle {
        textField.rx.text
          .throttle(time, scheduler: MainScheduler.instance)
          .distinctUntilChanged({ ($0 ?? "") == ($1 ?? "") })
          .takeUntil(self.rx.deallocated)
          .subscribe(onNext: { [weak self] text in
            let string: String = text ?? ""
            if self?.throttledText != string {
              self?.throttledText = string
              self?.delegate?.searchBarTextDidChangeAfterThrottle(self!)
            }
          })
          .disposed(by: disposeBag)
      }
    }
  }
  
  public var text: String? {
    return textField.text
  }
  
  public func setText(_ text: String?) {
    textField.text = text
  }
  
  static func newInstance() -> CollectionSearchBar {
    return Bundle(for: self).loadNibNamed("CollectionSearchBar", owner: nil, options: nil)!.first as! CollectionSearchBar
  }
  
  open override func awakeFromNib() {
    super.awakeFromNib()
    
    searchIcon.tintColor = UIColor.black
    textField.delegate = self
    
    clearButton?.addTarget(self, action: #selector(didTapClearButton(_:)), for: .touchUpInside)
    textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    
    if !clearAlwaysVisible {
      if let clearButton = clearButton {
        clearButton.isHidden = true
      } else {
        textField.clearButtonMode = .whileEditing
      }
    } else if clearButton == nil {
      textField.clearButtonMode = .always
    }
  }
  
  open func clear() {
    self.didTapClearButton(self)
  }
  
  @objc func didTapClearButton(_ sender: AnyObject) {
    delegate?.searchBarDidTapClearButton(self)
    
    if !clearAlwaysVisible {
      if let text = text , !text.isEmpty {
        textField.text = nil
        textFieldDidChange(self)
      }
      
      clearButton?.isHidden = true
    }
  }
  
  @objc func textFieldDidChange(_ sender: AnyObject) {
    if !clearAlwaysVisible {
      if let text = text , !text.isEmpty {
        clearButton?.isHidden = false
      } else {
        clearButton?.isHidden = true
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
  
  public func textFieldShouldClear(_ textField: UITextField) -> Bool {
    delegate?.searchBarDidTapClearButton(self)
    textField.text = nil
    textFieldDidChange(self)
    
    return false
  }
}
