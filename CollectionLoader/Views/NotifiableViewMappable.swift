//
//  DataSourceViewMappable.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 3/1/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation
import ViewMapper
import RxSwift
import DataSource

open class NotifiableViewMappable<ModelType: BaseDataModel>: UIView, ViewMappable {
  var disposable: Disposable?
  
  public func map(object: ModelType) {
    disposable?.dispose()
    disposable = NotificationCenter.default.registerForCRUDNotification(String(describing: type(of: object)))
      .takeUntil(self.rx.deallocated)
      .subscribe(onNext: { [weak self] notification in
        switch notification.crudNotificationType {
        case .update:
          let updatedObject = notification.crudObject as! ModelType
          if updatedObject == object {
            self?.map(object: updatedObject)
          }
        default: break
        }
      })
  }
}
