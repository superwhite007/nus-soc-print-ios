//
//  SettingsViewController.swift
//  NUS SOC Print
//
//  Created by Yeo Kheng Meng on 12/8/14.
//  Copyright (c) 2014 Yeo Kheng Meng. All rights reserved.
//

import Foundation
import UIKit


class SettingsViewController: GAITrackedViewController, UITextFieldDelegate{
    
    let TAG = "SettingsViewController"
    
    let RESET_PASSWORD_LINK = "https://mysoc.nus.edu.sg/~myacct/"
    
    let DIALOG_SAVE_TITLE = "Saved!"
    let DIALOG_SAVE_TEXT = "All fields saved!"
    
    let DIALOG_EMPTY_FIELDS_TITLE = "Empty Fields"
    let DIALOG_EMPTY_FIELDS_TEXT = "Username/Password/Server fields are empty. This app will not work without your Unix credentials or a server setting."

    
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var printerField: UITextField!
    @IBOutlet weak var serverField: UITextField!
    
    @IBAction func saveButtonPress(sender: UIButton) {
        saveStuff()
    }
    
    
    @IBAction func forgetButtonPress(sender: UIButton) {
        
        var url  = NSURL.URLWithString(RESET_PASSWORD_LINK)
        UIApplication.sharedApplication().openURL(url)
    }
    
    
    override func viewDidAppear(animated: Bool) {
        usernameField.delegate = self
        passwordField.delegate = self
        printerField.delegate = self
        serverField.delegate = self
        
        loadAllValuesToUI()
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = TAG;
    }
    
    func saveStuff(){
        var preferences : Storage = Storage.sharedInstance;
        
        var username = usernameField.text
        var password = passwordField.text
        var printer = printerField.text
        var server = serverField.text
        
        if username.isEmpty || password.isEmpty || server.isEmpty {
            showAlert(DIALOG_EMPTY_FIELDS_TITLE, DIALOG_EMPTY_FIELDS_TEXT, self)
        } else {
            preferences.storeUsername(username)
            preferences.storePassword(password)
            preferences.storePrinter(printer)
            preferences.storeServer(server)
            showAlert(DIALOG_SAVE_TITLE, DIALOG_SAVE_TEXT, self)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        usernameField.text = nil
        passwordField.text = nil
        printerField.text = nil
        serverField.text = nil
    }

    
    func loadAllValuesToUI(){
        var preferences : Storage = Storage.sharedInstance;

        
        var username : String?  = preferences.getUsername()
        usernameField.text = username
        
        var password : String? = preferences.getPassword()
        passwordField.text = password
  
        var printer : String? = preferences.getPrinter()
        printerField.text = printer
        
        var server : String = preferences.getServer()
        serverField.text = server
    }
    

    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        textField.resignFirstResponder();
        return true;
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    
}