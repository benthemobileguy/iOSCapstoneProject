//
//  UserPref.swift
//  Created by Ben on July 06, 2023.
//

import Foundation

class UserPref{
    private static let PREF_LAST_LONG_PREF = "PREF_LAST_LONG"
    private static let PREF_LAST_SPAN_LAT_PREF = "PREF_LAST_SPAN_LAT"
    private static let PREF_IS_DEFAULT_GROUP_CREATED_PREF = "PREF_IS_DEFAULT_GROUP_CREATED"
    private static let PREF_LAST_SPAN_LONG_PREF = "PREF_LAST_SPAN_LONG_PREF"
    private static let PREF_LAST_LAT_PREF = "PREF_LAST_LAT"
    
    static func getUserDef() -> UserDefaults {
        UserDefaults.standard
    }
    
    static func setLastLocation(_ lat: Double, _ long: Double){
        getUserDef().set(lat, forKey: PREF_LAST_LAT_PREF)
        getUserDef().set(long, forKey: PREF_LAST_LONG_PREF)
    }
    
    static func setLastSpan(_ lat: Double, _ long: Double){
        getUserDef().set(lat, forKey: PREF_LAST_SPAN_LAT_PREF)
        getUserDef().set(long, forKey: PREF_LAST_SPAN_LONG_PREF)
    }
    static func getLastLocation() -> PointLocation? {
        let lat = getUserDef().double(forKey: PREF_LAST_LAT_PREF)
        let long = getUserDef().double(forKey: PREF_LAST_LONG_PREF)
        
        if lat != 0 && long != 0 {
            return PointLocation(lat, long)
        } else {
            return nil
        }
    }
    
    static func getLastSpanLocation() -> PointLocation? {
        let lat = getUserDef().double(forKey: PREF_LAST_SPAN_LAT_PREF)
        let long = getUserDef().double(forKey: PREF_LAST_SPAN_LONG_PREF)
        
        if lat != 0 && long != 0 {
            return PointLocation(lat, long)
        } else {
            return nil
        }
    }
    

    static func createDefaultGroupIsNeeded() -> Bool {
        let flag = getUserDef().bool(forKey: PREF_IS_DEFAULT_GROUP_CREATED_PREF)
        getUserDef().set(true, forKey: PREF_IS_DEFAULT_GROUP_CREATED_PREF)
        return !flag
    }
}
