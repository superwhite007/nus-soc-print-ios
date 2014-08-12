//
//  Storage.swift
//  NUS SOC Print
//
//  Created by Yeo Kheng Meng on 12/8/14.
//  Copyright (c) 2014 Yeo Kheng Meng. All rights reserved.
//

import Foundation

private let KEY_USERNAME = "KEY_USERNAME"
private let KEY_PASSWORD = "KEY_PASSWORD"
private let KEY_PRINTER = "KEY_PRINTER"
private let KEY_SERVER = "KEY_SERVER"
private let DEFAULT_SERVER = "sunfire.comp.nus.edu.sg"


private let _SingletonSharedInstance = Storage()

private var preferences : NSUserDefaults!

class Storage  {
    class var sharedInstance : Storage {
        preferences = NSUserDefaults.standardUserDefaults()
        return _SingletonSharedInstance
    }
}


//Returns nil if nothing
func getUsername() -> NSString {
    return preferences.stringForKey(KEY_USERNAME)
}

func storeUsername(newUsername : NSString) {
    if(newUsername != nil){
        preferences.setObject(newUsername, forKey: KEY_USERNAME)
    }
}


//Returns nil if nothing
func getPassword() -> NSString {
    return preferences.stringForKey(KEY_PASSWORD)
}

func storePassword(newPassword : NSString) {
    if(newPassword != nil){
        preferences.setObject(newPassword, forKey: KEY_PASSWORD)
    }
}


//Returns nil if nothing
func getPrinter() -> NSString {
    return preferences.stringForKey(KEY_PRINTER)
}

func storePrinter(newPrinter : NSString) {
    if(newPrinter != nil){
        preferences.setObject(newPrinter, forKey: KEY_PRINTER)
    }
}


//Returns nil if nothing
func getServer() -> NSString {
    var storedServer :NSString =  preferences.stringForKey(KEY_SERVER)
    
    if(storedServer == nil || storedServer.length == 0){
        return DEFAULT_SERVER;
    } else {
        return storedServer;
    }
}

func storeServer(newServer : NSString) {
    if(newServer != nil){
        preferences.setObject(newServer, forKey: KEY_SERVER)
    }
}