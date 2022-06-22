//
//  GPSAdvancedViewController.swift
//
//

import Foundation
import UIKit
import Eureka
import PKHUD



class GPSAdvancedViewController: FormViewController {
    
    
    weak var delegate: AnyObject?
  
    var sharedLLLocationService : LLLocationService = LLLocationService.shared()


    
    init() {
        super.init(nibName: nil, bundle: nil)
            
     }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print(" Deinit Settings VC ")
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "GPS Advanced"

        self.view.backgroundColor = .white

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeTapped))
        
        form = createForm(editable: true)
        
    }
    
    
    func createForm(editable: Bool) -> Form {
           
        let form = Form()
        
        
        
        form +++ Section(header: "NEMA TCP / IP", footer: "")
            <<< TextRow(){
                $0.tag = "FORM_IP_ADDRESS"
                $0.title = "IP Adress"
                $0.placeholder = "e.g. 192.168.1.60"
                $0.add(rule: RuleRequired())
                $0.value = AppSettings.GPS_IP_ADDRESS
                $0.validationOptions = .validatesOnChange //2
                $0.cellUpdate { (cell, row) in //3
                  if !row.isValid {
                    cell.titleLabel?.textColor = .red
                  }
                }

            }
   
        
        
            <<< TextRow(){
                $0.tag = "FORM_IP_SOCKET"
                $0.title = "SOCKET"
                $0.placeholder = "e.g. 5000"
                $0.add(rule: RuleRequired())
                $0.value = AppSettings.GPS_IP_SOCKET
                $0.validationOptions = .validatesOnChange //2
                $0.cellUpdate { (cell, row) in //3
                  if !row.isValid {
                    cell.titleLabel?.textColor = .red
                  }
                }

            }

        
   
        
        
        
        form +++ Section("")
            
        
            <<< ButtonRow().cellSetup({ (cell, row) in
                row.tag = "CONNECT_BUTTON"
                row.title = (self.sharedLLLocationService.locationSource != .NmeaTcpIp) ? "CONNECT" : "DISCONNECT"
                
            }).onCellSelection({ (ceil, row)  in
                
                self.connectNemaTapped()
            })
        
        
        
        return form

    }
    
    
    //MARK: - BUTTONS
    

    
    
    
    @objc private func connectNemaTapped() {

        let formvalues = self.form.values()

        if !form.validate().isEmpty {
            self.showAlert(title: "Error!", message: "You must enter a ip address & socet")
            return
        }
        


        guard let ipAddress : String = formvalues["FORM_IP_ADDRESS"] as? String else {
            return
        }
        
        guard let iPSocet : String = formvalues["FORM_IP_SOCKET"] as? String else {
            return
        }


        AppSettings.GPS_IP_ADDRESS = ipAddress
        AppSettings.GPS_IP_SOCKET = iPSocet
        
        
 
        
        
        if (self.sharedLLLocationService.locationSource == .NmeaTcpIp) {
            self.sharedLLLocationService.disconnectScoketServer()
            if let connectButtonRow : ButtonRow = self.form.rows[2] as? ButtonRow {
                connectButtonRow.title = "CONNECT"
                connectButtonRow.reload()
            }
            return
        }
        
        
        HUD.show(.labeledProgress(title: "Connecting...", subtitle: nil))

   
        sharedLLLocationService.startLocationManager(source: .NmeaTcpIp ) { success, result in
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {

                HUD.hide()
                
                print("RESULT: \(result)")
                
                if success {
                    
                    if let connectButtonRow : ButtonRow = self.form.rows[2] as? ButtonRow {
                        connectButtonRow.title = "DISCONNECT"
                        connectButtonRow.reload()
                    }
                    
                    
                } else {
                    
                }
            }
            
        }
        
 
    }
    
    private func userLoggedInSuccessfully() {
        
 
        
    }
    
    private func userFailedToLogin(message: String) {
 
        self.showAlert(title: "Login Fail!", message: "Please check your username & password. \(message)")

        
    }
    
    
    
    
    
    
    @objc private func closeTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    //MARK: - alert
    
   func showAlert( title : String, message: String ) {
       
          
          let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

          alertController.addAction(UIAlertAction(title: "OK", style: .default) { (action) in
          })
          

          
          if UIDevice.current.userInterfaceIdiom == .pad {
              alertController.popoverPresentationController?.sourceView = self.view
              alertController.popoverPresentationController?.sourceRect = self.view.bounds
              alertController.popoverPresentationController?.permittedArrowDirections = [.down, .up]
          }
       
          self.present(alertController, animated: true, completion: {
          })
       
       
       
   }
    
    
}
