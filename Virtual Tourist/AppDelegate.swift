//
//  AppDelegate.swift
//  Virtual Tourist
//
//  Created by Arnab Roy on 2/11/19.
//  Copyright © 2019 RoyInc. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let dataController = DataController(modelName: "VirtualTourist")

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        firstLaunch()
        return true
    }
    
    func firstLaunch() {
        if(UserDefaults.standard.bool(forKey: "isNotFirstLaunch")) {
        } else {
            UserDefaults.standard.set(true, forKey: "isNotFirstLaunch")
            UserDefaults.standard.set(37.0902, forKey: "InitLatitude")
            UserDefaults.standard.set(-95.7129, forKey: "InitLatitude")
            UserDefaults.standard.synchronize()
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        dataController.load()
        let navigationController = window?.rootViewController as! UINavigationController
        let mapDashboardController = navigationController.topViewController as! MapDashboardController
        mapDashboardController.dataController = dataController
        
        return true
    }
}

