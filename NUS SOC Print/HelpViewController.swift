//
//  HelpViewController.swift
//  NUS SOC Print
//
//  Created by Yeo Kheng Meng on 12/8/14.
//  Copyright (c) 2014 Yeo Kheng Meng. All rights reserved.
//

import Foundation
import UIKit

class HelpViewController: UIViewController {
    
    @IBAction func videoButtonPress(sender: UIButton) {
        UIApplication.sharedApplication().openURL(NSURL(string: "http://www.youtube.com/watch?v=PRGcK7gzbnM"))
    }

    @IBAction func emailMe(sender: UIButton) {
        
        var device = getDeviceSpec()
        var subject : String = "NUS%20SOC%20Print%20iOS"
        var myEmail : String = "yeokm1@gmail.com"
        
        var urlString : String = String(format: "mailto:?to=%@&subject=%@(%@)(%@)", myEmail, subject, device.model, device.osVersion)
        
        var url : NSURL = NSURL(string: urlString)
        
        UIApplication.sharedApplication().openURL(url)
       

        
    }
    
    @IBAction func goToSourceCodePage(sender: UIButton) {
        UIApplication.sharedApplication().openURL(NSURL(string: "https://github.com/yeokm1/nus-soc-print-ios"))
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getDeviceSpec() -> (model : String, osVersion : String) {
        var platform = UIDevice.currentDevice().platform()
        var version = getSystemVersion()
        return (platform, version)
    }
    
    
}