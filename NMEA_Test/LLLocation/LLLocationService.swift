//
//  LLLocationService.swift
//
//

/*
 
 THIS FILE MANAGERS LOCATION SERICES
 
 
 
 */


import Foundation
import CoreLocation



@objc protocol LLLocationServiceDelegate {
    @objc optional func LLLocationUpdated(_ location : CLLocation)
    @objc optional func LLLocationAuthorized()
    @objc optional func LLLocationNotAuthorized()
    @objc optional func LLLocationError(_ error : Error)


}


class LLLocationService: NSObject, CLLocationManagerDelegate, StreamDelegate {
    
    
    enum LocationSource : String {
        case none = "Not active"
        case AvailableBestSource = "Chooses open TCP connection, defaults to corelocation"
        case CoreLocation = "iOS GPS"
        case NmeaTcpIp = "Nema Via TCPIP"
        case NmeaBluetooth = "Nema Via Bluetooth" //not implemented
        
    }
    
    weak var delegate: AnyObject?
    public var locationSource : LocationSource = .none

    var altitudeRequired : Bool = true


    private static var sharedLLLocationService: LLLocationService = {
       let serverService = LLLocationService()
       return serverService
    }()


//    private init() {
//       
//       
//    }

    // MARK: - Accessors
    class func shared() -> LLLocationService {
       return sharedLLLocationService
    }
    
    

 
    
    
    
    var lastLocationResult : CLLocation? = nil
    

    
    typealias startCompletionBlock = (_ success: Bool, _ resultMessage : String ) -> Void

    
    func startLocationManager ( source : LocationSource, completionHandler: @escaping startCompletionBlock) {

        var pefferedSource = source
        
        //if NmeaTcpIp
        if (pefferedSource == .AvailableBestSource) {
            
            if (self.locationSource == .NmeaTcpIp ) {
                completionHandler(true, "Using Existing NEMA TCP CONNECTION")
                return
            }
            
            //else default to Corelocation
            pefferedSource = .CoreLocation

        }
        
        if pefferedSource == .CoreLocation {
            self.startCoreLocationManager(completionHandler: completionHandler)
            return
        }
        
        if pefferedSource == .NmeaTcpIp {
            self.startNmeaSocketService(completionHandler: completionHandler)
            return
        }
        
        
    }
    
    
    //
    
    func returnLocation( _ location : CLLocation, source : LocationSource) {
        
        //ONLY RETURN LOCATION FOR THE DESIRED SOURCE
        if self.locationSource == source {
            delegate?.LLLocationUpdated?(location)
        }
    }
    
    func returnError( _ error : Error) {
        print("ERROR: \(error.localizedDescription)")
        delegate?.LLLocationError?(error)
        
    }
    
    
    func stopLocationService() {
        if (self.locationManager != nil ) {
            self.locationManager.stopUpdatingLocation()
            
        }

    }
    
    
    // MARK: - Core Location

    
    var locationManager : CLLocationManager!
    

    func reqestCoreLocationAuthorization () {

        
        if !CLLocationManager.locationServicesEnabled() {
            print("Services NOT enabled...")

            //ADD DELEGATE
        }
        
        if (self.locationManager == nil ) { self.locationManager = CLLocationManager() }

        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        

        self.locationManager.requestWhenInUseAuthorization()
    }
    
    
    func coreLocationAuthorized()->Bool {
        
        if (self.locationManager == nil ) { self.locationManager = CLLocationManager() }
            
        let authorizationStatus: CLAuthorizationStatus  = self.locationManager.authorizationStatus

        let authorized = (authorizationStatus == .authorizedAlways ||
                              authorizationStatus == .authorizedWhenInUse )
            
        return authorized
        
    }
    
    
    func startCoreLocationManager ( completionHandler: @escaping startCompletionBlock) {

        if (self.locationManager == nil ) { self.locationManager = CLLocationManager() }
        
        if AppSettings.tagGpsDuringScan && self.coreLocationAuthorized() {
            
            self.locationSource = .CoreLocation
            
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.startUpdatingLocation()
            
            completionHandler( true, "Started")
            
        } else {
            completionHandler( false, "not authorized")

        }
    }
    
    

    
    
    //IOS DELEGATES
    // MARK: - CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {

            switch manager.authorizationStatus {
                case .authorizedAlways , .authorizedWhenInUse:
                    break
                case .notDetermined , .denied , .restricted:
                    delegate?.LLLocationNotAuthorized?()
                    return
                default:
                    break
            }
            
            switch manager.accuracyAuthorization {
                case .fullAccuracy:
                    delegate?.LLLocationAuthorized?()
                    break
                case .reducedAccuracy:
                    break
                default:
                    break
            }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.lastLocationResult = location
            self.returnLocation(location, source: .CoreLocation)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
      
        print("ERROR: \(error.localizedDescription)")
        
        if let error = error as? CLError, error.code == .denied {
          // Location updates are not authorized.
          manager.stopUpdatingLocation()
          delegate?.LLLocationNotAuthorized()
          return
       }
       // Notify the user of any errors.
       delegate?.LLLocationError?(error)
    }
    
    
    
    //MARK: -
    
    struct DataSocket {
        
        let ipAddress: String!
        let port: Int!
        
        init(ip: String, port: String){
            self.ipAddress = ip
            self.port      = Int(port)
        }
    }
    
    var readStream: Unmanaged<CFReadStream>?
    var writeStream: Unmanaged<CFWriteStream>?
    var inputStream: InputStream?
    var outputStream: OutputStream?
    var messages = [AnyHashable]()
    
    
    

    func startNmeaSocketService(completionHandler: @escaping startCompletionBlock) {
        
        
        if (AppSettings.GPS_IP_ADDRESS.isEmpty || AppSettings.GPS_IP_SOCKET.isEmpty) {
            
            completionHandler(false, "No Valid Server Info")
            return
        }
        
        let soc = DataSocket(ip: AppSettings.GPS_IP_ADDRESS, port: AppSettings.GPS_IP_SOCKET)
        self.connectWith(socket: soc)
        
        self.locationSource = .NmeaTcpIp
        
        completionHandler(true, "")
        
    }

    
    
    func connectWith(socket: DataSocket) {

        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (socket.ipAddress! as CFString), UInt32(socket.port), &readStream, &writeStream)
        messages = [AnyHashable]()
        openSocketServer()
    }
    
    func disconnectScoketServer(){
        
        closeScoketServer()
        self.locationSource = .none
    }
    
    func openSocketServer() {
        print("Opening streams.")
        outputStream = writeStream?.takeRetainedValue()
        inputStream = readStream?.takeRetainedValue()
        outputStream?.delegate = self
        inputStream?.delegate = self
        outputStream?.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
        inputStream?.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
        outputStream?.open()
        inputStream?.open()
    }
    
    func closeScoketServer() {
        print("Closing streams.")
        inputStream?.close()
        outputStream?.close()
        inputStream?.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
        outputStream?.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
        inputStream?.delegate = nil
        outputStream?.delegate = nil
        inputStream = nil
        outputStream = nil
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        //print("stream event \(eventCode)")
        switch eventCode {
        case .openCompleted:
            //uiPresenter?.resetUIWithConnection(status: true)
            print("Stream opened")
        case .hasBytesAvailable:
            if aStream == inputStream {
                var dataBuffer = Array<UInt8>(repeating: 0, count: 1024)
                var len: Int
                while (inputStream?.hasBytesAvailable)! {
                    len = (inputStream?.read(&dataBuffer, maxLength: 1024))!
                    if len > 0 {
                        let output = String(bytes: dataBuffer, encoding: .ascii)
                        if nil != output {
                            //print("server said: \(output ?? "")")
                            messageReceived(message: output!)
                        }
                    }
                }
            }
        case .hasSpaceAvailable:
            print("Stream has space available now")
        case .errorOccurred:
            print("\(aStream.streamError?.localizedDescription ?? "")")
            
            if let error = aStream.streamError {
                self.returnError(error)
            }
            
            
        case .endEncountered:
            aStream.close()
            aStream.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
            print("close stream")
            //uiPresenter?.resetUIWithConnection(status: false)
        default:
            print("Unknown event")
        }
    }
    
    func messageReceived(message: String){
        
        
        //print(message)
        
        if let location : CLLocation = NmeaParser.parseSentence(data: (message), altitudeRequired: self.altitudeRequired) {
            
            //print(location)
            self.returnLocation(location, source: .NmeaTcpIp)
            
        }
        
        
    }
    
    func send(message: String){
        
        let response = "msg:\(message)"
        let buff = [UInt8](message.utf8)
        if let _ = response.data(using: .ascii) {
            outputStream?.write(buff, maxLength: buff.count)
        }

    }
    
    
    
    
    
    
    
    
    
}


enum LocationError: Error {
    case noAuthorization
}

extension LocationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noAuthorization:
            return NSLocalizedString("No Location Authorization", comment: "No Location Authorizatio")
        }
    }
}


//TODELETE

extension Date {
    var secondsAgo : TimeInterval {
        return -self.timeIntervalSinceNow
    }
    var millisecondsAgo : TimeInterval {
        return -self.timeIntervalSinceNow * 1000.0
    }
}


class AppSettings {
 
    static let tagGpsDuringScan = true
    static var GPS_IP_ADDRESS = "172.31.40.199" //127.0.0.1"
    static var GPS_IP_SOCKET = "3000"

}
