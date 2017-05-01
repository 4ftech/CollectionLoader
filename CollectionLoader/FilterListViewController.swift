//
//  FilterListViewController.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 4/19/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation
import Eureka
import DataSource
import ViewMapper

class FilterListViewController: FormViewController {
  var filters: [Filter] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    for filter in filters {
      if let dateFilter = filter as? DateFilter {
        form +++ DateRow() { row in
          row.title = dateFilter.title
          row.value = dateFilter.selectedDate
        }.onChange() { row in
          dateFilter.selectedDate = row.value
        }
      } else if let selectFilter = filter as? SelectFilter<String> {
        switch selectFilter.selectType {
        case .one:
          form +++ selectOneRow(forFilter: selectFilter)
        case .multiple:
          form +++ selectMultipleRow(forFilter: selectFilter)
        }
      }
    }
  }
  
  func selectOneRow<T>(forFilter filter: SelectFilter<T>) -> PushRow<SelectFilterOption<T>> where T:Equatable {
    return PushRow<SelectFilterOption<T>>() { row in
      row.title = filter.title
      
      if filter.optionsLoaded {
        row.options = filter.filterOptions
      } else {
        row.presentationMode = .show(
          controllerProvider: ControllerProvider.callback {
            let controller = SelectorViewController<SelectFilterOption<T>> { controller in
              
            }
            
            filter.loadOptions().then { (options) -> Void in
              row.options = options
              controller.setupForm()
            }.catch { error in
              
            }
          
            return controller
          }, onDismiss: { vc in
            let _ = vc.navigationController?.popViewController(animated: true)
          }
        )
      }
      
    }.onChange { row in
      if let value = row.value {
        filter.select(value: value)
      } else {
        filter.clearFilter()
      }
    }
  }

  func selectMultipleRow<T>(forFilter filter:SelectFilter<T>) -> MultipleSelectorRow<SelectFilterOption<T>> where T:Equatable {
    return MultipleSelectorRow<SelectFilterOption<T>>() { row in
      row.title = filter.title
      
      if filter.optionsLoaded {
        row.options = filter.filterOptions
      } else {
        row.presentationMode = .show(
          controllerProvider: ControllerProvider.callback {
            let controller = MultipleSelectorViewController<SelectFilterOption<T>> { controller in
              
            }
            
            filter.loadOptions().then { (options) -> Void in
              row.options = options
              controller.setupForm()
            }.catch { error in
                
            }
            
            return controller
          }, onDismiss: { vc in
            let _ = vc.navigationController?.popViewController(animated: true)
          }
        )
      }
    }.onChange { row in
      if let value = row.value {
        filter.selectedValues = Array(value)
      } else {
        filter.clearFilter()
      }
    }
  }
}

