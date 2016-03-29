//
//  AppDelegate.swift
//  wf_app
//
//  Created by Rui Brito on 21/03/16.
//  Copyright © 2016 Rui Brito. All rights reserved.
//

import UIKit
import CoreData
import Reachability
import Alamofire

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let moc = DataController().managedObjectContext


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        let reach:Reachability
        do {
            reach = try Reachability.reachabilityForInternetConnection()
        }
        catch {
            fatalError("\(error)")
        }
        
        if reach.isReachableViaWiFi() {
            self.syncValidateServer()
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func syncValidateServer () {
        
        let fetch = NSFetchRequest(entityName: "Race")
        
        do {
            let req =  try moc.executeFetchRequest(fetch) as! [Race]
            
            for record in req {
                print (req.count)
                print (record.qrcode!)
                print (record.validated!)
                print (record.check1!)
                print (record.check2!)
                print (record.final!)
            
                //Alamofire.request(.GET, "http://Ruis-MBP.local:3000/syncOfflineData/\(record.qrcode!)/\(record.validated!)/\(record.check1!)/\(record.check2!)/\(record.final!)")
                 //   .responseJSON { response in
                  //      let JSON = response.result.value
                   //     print("JSON: \(JSON)")
                        
                //}
                moc.deleteObject(record)
                try moc.save()
            }
        }
        catch {
            fatalError("\(error)")
        }
        
        
    }
    

}
