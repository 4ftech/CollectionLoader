//
//  NotificationCenter.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 2/17/17.
//  Copyright © 2017 Oinkist. All rights reserved.
//


import Foundation
import RxSwift
import RxCocoa

enum CRUDType: String {
  case Create = "create", Update = "update", Delete = "delete"
}

enum CRUDUserInfoKeys: String {
  case NotificationType = "notificationType", Object = "object", ObjectIndex = "index"
}

extension NotificationCenter {
  func crudNotificationName(_ objectClassName: String) -> String {
    return "com.oinkist.CollectionLoader.CRUDNotification.\(objectClassName)"
  }
  
  func postCRUDNotification<T: CollectionRow>(_ notificationType: CRUDType, crudObject: T, objectIndex: Int? = nil, senderObject: AnyObject? = nil) {
    let name = crudNotificationName(String(describing: type(of: crudObject)))
    
    var userInfo: [String:Any] = [
      CRUDUserInfoKeys.NotificationType.rawValue: notificationType.rawValue,
      CRUDUserInfoKeys.Object.rawValue: crudObject
    ]
    
    if let index = objectIndex {
      userInfo[CRUDUserInfoKeys.ObjectIndex.rawValue] = index
    }
    
    post(name: Notification.Name(rawValue: name), object: senderObject, userInfo: userInfo)
  }
  
  func registerForCRUDNotification(_ objectClassName: String, senderObject: AnyObject? = nil) -> Observable<Notification> {
    let name = crudNotificationName(objectClassName)
    
    return rx.notification(Notification.Name(rawValue: name), object: senderObject)
  }

}

extension Notification {
  var crudObject: Any {
    return userInfo![CRUDUserInfoKeys.Object.rawValue]!
  }
  
  var crudObjectIndex: Int? {
    return userInfo![CRUDUserInfoKeys.ObjectIndex.rawValue] as? Int
  }
  
  
  var crudNotificationType: CRUDType {
    return CRUDType(rawValue: userInfo![CRUDUserInfoKeys.NotificationType.rawValue] as! String)!
  }
}
