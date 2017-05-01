//
//  DataSourceViewController.swift
//  CollectionLoader
//
//  Created by Nick Kuyakanon on 3/1/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation

//
//  DataSourceFormController.swift
//  DataSourceFormController
//
//  Created by Nick Kuyakanon on 2/28/17.
//  Copyright © 2017 4f Tech. All rights reserved.
//

import Foundation

import DataSource
import PromiseKit

import ViewMapper
import Eureka

open class DataSourceFormController<T: BaseDataModel>: FormViewController, ViewMappable {
  open var object: T!
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }
  
  public init(object: T) {
    super.init(style: .grouped)
    
    self.object = object
  }
  
  
  override open func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    if object == nil {
      object = T()
    }
    
    map(object: object)
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
  }
  
  open func map(object: T) {
    
  }
  
  open func save() {
    let isNew: Bool = object.objectId == nil
    
    let promise: Promise<T> = object.save()
    promise.then { result in
      self.handleSuccess(crudType: isNew ? .Create : .Update, crudObject: result)
      }.catch { error in
        self.handleError(error: error)
    }
  }
  
  open func handleSuccess(crudType: CRUDType, crudObject: T) {
    NSLog("DataSourceFormController: Success")
    NotificationCenter.default.postCRUDNotification(crudType, crudObject: crudObject)
    _ = self.navigationController?.popViewController(animated: true)
  }
  
  open func handleError(error: Error) {
    
  }
}
