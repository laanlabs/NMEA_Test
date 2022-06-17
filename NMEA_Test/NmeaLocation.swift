//
//  NmeaLocation.swift
//  NMEA_Test
//
//  Created by jclaan on 6/6/22.
//

import CoreLocation
import Foundation

protocol NmeaSentence {
    var rawSentence: [String] { get }
    
    init(rawSentence: [String])
    
    func type() -> String
    
    func parse() -> CLLocation?
}



public class NmeaParser {
    
    /// Expects an NMEA String as parameter and returns a CLLocation object.
    ///
    /// - Parameter data: An NMEA sentence as String
    /// - Returns: An CLLocation object
    public static func parseSentence(data: String) -> CLLocation? {
        //print("Input sentence: \(data)")
        
        
        let nmeaLines = data.components(separatedBy: "\n")
        
        for nnmeLine in nmeaLines {
            
            let nnmeLineData = nnmeLine.components(separatedBy: ",")

            if let type = nnmeLineData.first {
                //print("NMEA Type \(String(describing: type))")
                
                switch type {
                    //GET ALTITUDE FIRST
                case "$GPGGA":
                    let sentence = GgaSentence(rawSentence: nnmeLineData)
                    return sentence.parse()
                case "$GPRMC":
                    fallthrough
    //                let sentence = RmcSentence(rawSentence: nnmeLine)
    //                return sentence.parse()
                case "$GPGSV": fallthrough
                default:
                    break
                    //print("Type \(String(describing: type)) unknown.")
                }
            }
            
            
            
        }
        
        

        return nil
    }
}

public class RmcSentence: NmeaSentence {
    
    var rawSentence: [String]
    
    /// RMC is defined as following:
    /// ```
    /// $GPRMC,162614,A,5230.5900,N,01322.3900,E,10.0,90.0,131006,1.2,E,A*13`
    /// $GPRMC,HHMMSS,A,BBBB.BBBB,b,LLLLL.LLLL,l,GG.G,RR.R,DDMMYY,M.M,m,F*PP
    ///      0,     1,2,        3,4,         5,6,   7,   8,     9, 10,11,12
    /// ```
    ///
    /// - TYPE: The type of NMEA data, e.g. RMC, GGA, GSA, GSV
    /// - TIME: The timestamp of the NMEA data
    /// - STATUS: The status of the NMEA data, can be A or W
    /// - LATITUDEDIR: The latitude direction
    /// - LATITUDE: The latitude position
    /// - LONGITUDEDIR: The longitude direction
    /// - LONGITUDE: The longitude position
    /// - SPEED: The speed
    /// - COURSE: The course/direction
    /// - DATE: The date of the NMEA data
    /// - DEVIATION: The deviation of the data
    /// - SIGN: The sign of the deviation data
    /// - SIGNAL: The signal quality with a checksum
    enum Param: Int {
        case TYPE = 0
        case TIME = 1
        case STATUS = 2
        case LATITUDEDIR = 3
        case LATITUDE = 4
        case LONGITUDEDIR = 5
        case LONGITUDE = 6
        case SPEED = 7
        case COURSE = 8
        case DATE = 9
        case DEVIATION = 10
        case SIGN = 11
        case SIGNAL = 12
    }
    
    required public init(rawSentence: [String]) {
        self.rawSentence = rawSentence
    }
    
    func type() -> String {
        return "$GPRMC"
    }
    
    func parse() -> CLLocation? {
        let splittedString = self.rawSentence
        
        if splittedString.count < 12 {
            print("Invalid RMC string!")
            return nil
        }
        
        let rawTime = splittedString[RmcSentence.Param.TIME.rawValue]
        let rawLatitude = (splittedString[RmcSentence.Param.LATITUDE.rawValue], splittedString[RmcSentence.Param.LATITUDEDIR.rawValue])
        let rawLongitude = (splittedString[RmcSentence.Param.LONGITUDE.rawValue], splittedString[RmcSentence.Param.LONGITUDEDIR.rawValue])
        
        let rawSpeed = splittedString[RmcSentence.Param.SPEED.rawValue] // knots
        let rawCourse = splittedString[RmcSentence.Param.COURSE.rawValue] // degree
        let rawDate = splittedString[RmcSentence.Param.DATE.rawValue]
        
        let latitudeInDegree = convertLatitudeToDegree(with: rawLatitude.1)
        print("Latitude in degrees: \(latitudeInDegree)")
        
        let longitudeInDegree = convertLongitudeToDegree(with: rawLongitude.1)
        print("Longitude in degrees: \(longitudeInDegree)")
        
        let coordinate = CLLocationCoordinate2D(latitude: latitudeInDegree,
                                                longitude: longitudeInDegree)
        var course = CLLocationDirection(-1)
        if !rawCourse.isEmpty, let tempCourse = CLLocationDirection(rawCourse) {
            course = tempCourse
        }
        
        var speed = CLLocationSpeed(-1)
        if !rawSpeed.isEmpty {
            if #available(iOS 10.0, *) {
                let speedInMs = Measurement(value: Double(rawSpeed)!, unit: UnitSpeed.knots).converted(to: UnitSpeed.metersPerSecond)
                speed = CLLocationSpeed(speedInMs.value)
            } else {
                speed = CLLocationSpeed(Double(rawSpeed)! * 0.514)
            }
        }
        
        let concatenatedDate = rawDate + rawTime
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "GMT")
        if rawDate.isEmpty {
            dateFormatter.dateFormat = "hhmmss.SSS" // 025816.16
        } else {
            dateFormatter.dateFormat = "ddMMyyHHmmss.SSS"
        }
        
        var timestamp = Date()
        if let date = dateFormatter.date(from: concatenatedDate) {
            timestamp = date
        }
        
        let altitude = CLLocationDistance(0)
        let horizontalAccuracy = CLLocationAccuracy(0)
        let verticalAccuracy = CLLocationAccuracy(0)
        
        return CLLocation(coordinate: coordinate,
                          altitude: altitude,
                          horizontalAccuracy: horizontalAccuracy,
                          verticalAccuracy: verticalAccuracy,
                          course: course,
                          speed: speed,
                          timestamp: timestamp)
    }
    
    /// Format XXYY.ZZZZ -> XX° + (YY.ZZZZ / 60)°
    ///
    /// - stringValue
    ///
    /// @return
    func convertLatitudeToDegree(with stringValue: String) -> Double {
        return Double(stringValue.prefix(2))! +
            Double(stringValue.suffix(from: String.Index.init(encodedOffset: 2)))! / 60
    }
    
    /// Format XXYY.ZZZZ -> XX° + (YY.ZZZZ / 60)°
    ///
    /// - stringValue
    ///
    /// @return
    func convertLongitudeToDegree(with stringValue: String) -> Double {
        return Double(stringValue.prefix(3))! +
            Double(stringValue.suffix(from: String.Index.init(encodedOffset: 3)))! / 60
    }
}




class GgaSentence: NmeaSentence{
    var rawSentence: [String]
    
    enum GpggaParam: Int {
        case TYPE = 0
        case TIME = 1
        case LATITUDEDIR = 2
        case LATITUDE = 3
        case LONGITUDEDIR = 4
        case LONGITUDE = 5
        case ACCURACY = 6
        case SATELATENUMBER = 7
        case LOSSRATE = 8
        case ANTENNAHEIGHT = 9
        case ANTENNAHEIGHTUINT = 10
        case GEOIDHEGHT = 11
        case GEOIDHEGHTUNIT = 12
        case EFFECTIVETIME = 13
        case BASEID_CHECKSUM = 14
    }
    
    required init(rawSentence: [String]) {
        self.rawSentence = rawSentence
    }
    
    func type() -> String {
        return "$GPGGA"
    }
    
    func parse() -> CLLocation? {
        let splittedString = self.rawSentence
        
        if splittedString.count < 15 {
            print("Invalid GPGGA")
            return nil
        }
        
        let rawTime = splittedString[GgaSentence.GpggaParam.TIME.rawValue]
        //print(rawTime)
        let rawLatitude = (splittedString[GgaSentence.GpggaParam.LATITUDE.rawValue],splittedString[GgaSentence.GpggaParam.LATITUDEDIR.rawValue])
        //print(rawLatitude)
        let rawLongitude = (splittedString[GgaSentence.GpggaParam.LONGITUDE.rawValue],splittedString[GgaSentence.GpggaParam.LONGITUDEDIR.rawValue])
        //print(rawLongitude)
        let rawAccuracy = splittedString[GgaSentence.GpggaParam.ACCURACY.rawValue]
        //print(rawAccuracy)
        //let rawLossrate = splittedString[GpggaSentence.GpggaParam.LOSSRATE.rawValue]
        let latitudeInDegree = convertLatitudeToDegree(with: rawLatitude.1)

        //print("Latitude in degrees: \(latitudeInDegree)")
        let longitudeInDegree = convertLongitudeToDegree(with: rawLongitude.1)
        //print("Longitude in degrees: \(longitudeInDegree)")
        
    
        let coordinate = CLLocationCoordinate2D(latitude: latitudeInDegree, longitude: longitudeInDegree)
        
        //コースとスピードは分からないので-1
        let course = CLLocationDirection(-1)
        let speed = CLLocationSpeed(-1)
        let now = Date()
        //print("今日\(now)")
        
        let rawAltitude = (splittedString[GgaSentence.GpggaParam.ANTENNAHEIGHT.rawValue],splittedString[GgaSentence.GpggaParam.ANTENNAHEIGHTUINT.rawValue])
        
        let altitudeInMeters = rawAltitude.0
        
//        let dateFormatter = DateFormatter()
//        dateFormatter.timeZone = TimeZone(identifier: "GMT")
//        let rawDate = dateFormatter.string(from: Date())
//        let nowtime = rawDate + rawTime
//        let timestamp = dateFormatter.date(from: nowtime)
//        print(nowtime)
//        print(timestamp)
        //標高の計算がわかるまで０
        let altitude = CLLocationDistance(altitudeInMeters) ?? CLLocationDistance(0)
        let horizontalAccuracy = CLLocationAccuracy(0)
        let verticalAccuracy = CLLocationAccuracy(0)
        
//        return (CLLocation(coordinate: coordinate,altitude: altitude, horizontalAccuracy: horizontalAccuracy,verticalAccuracy: verticalAccuracy, course: course,speed: speed,timestamp: timestamp!),rawAccuracy)
        return CLLocation(coordinate: coordinate,altitude: altitude, horizontalAccuracy: horizontalAccuracy,verticalAccuracy: verticalAccuracy, course: course,speed: speed, timestamp: now)
    }
    
    //緯度の形式変換
    func convertLatitudeToDegree(with stringValue: String) -> Double {
        return Double(stringValue.prefix(2))! +
            Double(stringValue.suffix(from: String.Index.init(encodedOffset: 2)))! / 60
    }
    
    //経度の形式変換
    func convertLongitudeToDegree(with stringValue: String) -> Double {
        return Double(stringValue.prefix(3))! +
            Double(stringValue.suffix(from: String.Index.init(encodedOffset: 3)))! / 60
    }
}
