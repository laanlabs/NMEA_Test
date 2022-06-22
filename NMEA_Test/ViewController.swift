//
//  ViewController.swift
//  NMEA_Test
//
//  Created by jclaan on 6/6/22.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {

    

    var sharedLLLocationService : LLLocationService = LLLocationService.shared()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        let btn_1 = UIButton()
        btn_1.setTitle("CONNECT RTK", for: .normal)
        btn_1.setTitleColor(.blue, for: .normal)
        btn_1.frame = CGRect(x: 100, y: 150, width: 300, height: 100)
        btn_1.addTarget(self, action: #selector(startNMEATapped), for: .touchUpInside)
        self.view.addSubview(btn_1)
        
        
        let btn_2 = UIButton()
        btn_2.setTitle("CONNECT CORE LOCATION", for: .normal)
        btn_2.setTitleColor(.blue, for: .normal)
        btn_2.frame = CGRect(x: 100, y: 350, width: 300, height: 100)
        btn_2.addTarget(self, action: #selector(statCoreLocationTapped), for: .touchUpInside)
        self.view.addSubview(btn_2)
        
        
        
        sharedLLLocationService.delegate = self

        
        //startNMEA()
        
    }

    
    
    @objc func startNMEATapped() {
        

        
        let vc = GPSAdvancedViewController()

        vc.delegate = self
        //self.navigationController?.pushViewController(vc, animated: true)

        //@jason: delete this
        let nc = UINavigationController(rootViewController: vc)
        nc.modalPresentationStyle = .popover

        self.present(nc, animated: true, completion: nil)
        
        
    }
    
    
    func startCoreLocation() {
        
        if !sharedLLLocationService.coreLocationAuthorized() {
            sharedLLLocationService.reqestCoreLocationAuthorization()
            return
        }
        
        
        sharedLLLocationService.delegate = self
        sharedLLLocationService.startLocationManager( source : .AvailableBestSource ) { success, result in

            print("RESULT: \(result)")

            if success {

            } else {
                
                //let user know that dont have authorization or faire

            }

        }
        
        
    }
    
    
    
    @objc func statCoreLocationTapped() {
        
        self.startCoreLocation()

        
    }
    
    

}

extension ViewController: LLLocationServiceDelegate {
    
    func LLLocationUpdated(_ location : CLLocation) {
        
        print("LAT: ", location.coordinate.latitude)
        print("LON: ", location.coordinate.longitude)
        print("ALT: ", location.altitude)
        
    }
    
    func LLLocationAuthorized() {
        
        //if user approved start
        //self.startCoreLocation()
        
    }
    
    func LLLocationNotAuthorized(){
        print("ERROR: Location not authorized")

    }
    
    
    func LLLocationError( _ error : Error) {
        print("ERROR IN VC: \(error.localizedDescription)")
    }
    
}



