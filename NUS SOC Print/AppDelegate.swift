//
//  AppDelegate.swift
//  NUS SOC Print
//
//  Created by Yeo Kheng Meng on 28/7/14.
//  Copyright (c) 2014 Yeo Kheng Meng. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    
    let TAG = "Appdelegate"
    var window: UIWindow?
    
    var printViewController : PrintViewController?

    
    func application(application: UIApplication!, openURL url: NSURL!, sourceApplication: String!, annotation: AnyObject!) -> Bool {
        NSLog("%@ incoming file %@", TAG, url);
        
        
        var filemgr : NSFileManager = NSFileManager.defaultManager()
        
        
        
        //Remove existing files in temporary directory
        var directoryContents : Array = filemgr.contentsOfDirectoryAtPath(NSTemporaryDirectory(), error: nil)!
        
        for path in directoryContents {
            var fullPath = NSTemporaryDirectory().stringByAppendingPathComponent(path as String)
            filemgr.removeItemAtPath(fullPath, error: nil)
        }

        
        
    
        //Move file to tmp directory
        var newURLPath = NSURL(fileURLWithPath: NSTemporaryDirectory().stringByAppendingPathComponent(url.lastPathComponent))
        
        filemgr.moveItemAtURL(url, toURL: newURLPath, error: nil)
        
        
        if(printViewController == nil){
            NSLog("%@ printController is nil",TAG)
            incomingURL = newURLPath
        } else {
            NSLog("%@ printController is set",TAG)
            printViewController!.receiveDocumentURL(newURLPath)
            printViewController!.updateDocumentToWebview()
        }
        

        
        
        return true
    }
    

    func application(application: UIApplication!, didFinishLaunchingWithOptions launchOptions: NSDictionary!) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(application: UIApplication!) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication!) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication!) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication!) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        NSLog("%@ applicationDidBecomeActive", TAG)
    }

    func applicationWillTerminate(application: UIApplication!) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
//    func getPrintController() -> PrintViewController {
//        var storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//        var vc : PrintViewController = storyboard.instantiateViewControllerWithIdentifier("printID") as PrintViewController;
//        return vc
//    }


}

