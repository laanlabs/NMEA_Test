//
//  ViewController.swift
//  NMEA_Test
//
//  Created by jclaan on 6/6/22.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {

    
    var socketConnector:SocketDataManager!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        startNMEA()
        
    }

    
    
    func startNMEA() {
        
        socketConnector = SocketDataManager(with: self)

        
        let ipAddr = "127.0.0.1"
        let portVal = "3000"
        let soc = SocketDataManager.DataSocket(ip: ipAddr, port: portVal)
        socketConnector.connectWith(socket: soc)
        
        
    }
    

}


extension ViewController: PresenterProtocol{
    
    func resetUIWithConnection(status: Bool){
                
        if (status){
            updateStatusViewWith(status: "Connected")
        }else{
            updateStatusViewWith(status: "Disconnected")
        }
    }
    func updateStatusViewWith(status: String){
        
    }
    
    
    func update(message: String){
        
        //print(message)
        //print(NmeaParser.parseSentence(data: "$GPRMC,031849.49,A,5209.028,N,00955.836,E,,,310517,,E*7D")!)

        
        
    }
    
    func updateData(data: String){
        
        print(data)
        
        
        
        if let location : CLLocation = NmeaParser.parseSentence(data: data) {
            
            //print(location)
            
            print("LAT: ", location.coordinate.latitude)
            print("LON: ", location.coordinate.longitude)
            print("ALT: ", location.altitude)
            
        }

        
        
    }

    
}

