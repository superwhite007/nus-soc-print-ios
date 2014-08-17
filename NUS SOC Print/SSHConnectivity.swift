//
//  SSHConnectivity.swift
//  NUS SOC Print
//
//  Created by Yeo Kheng Meng on 17/8/14.
//  Copyright (c) 2014 Yeo Kheng Meng. All rights reserved.
//

import Foundation

class SSHConnectivity{
    
    let TAG = "SSHConnectivity"
    
    var session : NMSSHSession?
    var username : String?
    var password : String?
    var hostname : String?
    
    init(hostname : String, username : String, password : String){
        self.username = username
        self.password = password
        self.hostname = hostname
    }
    
    
    func connect() -> (serverFound : Bool, authorised : Bool){
        if(session != nil){
            session?.disconnect()
        }
        
        session = NMSSHSession(host: hostname, andUsername: username)
        session?.connect()
        
        if (session!.connected) {
            NSLog("%@ session connected", TAG)
            
            session?.authenticateByPassword(password)
            
        
            if (session!.authorized) {
                NSLog("%@ session authorised", TAG)
                
                return (true, true)
            } else {
                NSLog("%@ session not authorised", TAG)
                session?.disconnect()
                
                return (true, false)
            }
        } else {
            NSLog("%@ session failed to connect", TAG)
            session?.disconnect()
            
            return (false, false)
        }
    }
    
    func runCommand(command : String) -> String?{
        return session?.channel.execute(command, error: nil)
    }
    
    
    func disconnect(){
        session?.disconnect()
        session = nil
    }
    
 
    
}
