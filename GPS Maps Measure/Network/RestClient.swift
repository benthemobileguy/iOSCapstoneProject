//
//  RestClient.swift
//  Created by Ben on July 06, 2023.
//

import Foundation
import CocoaLumberjackSwift

class RestAPiClient {

    struct Auth {
        static let MAPS_API_KEY = "<YOUR_CUSTOMER_KEY>"
    }

    enum Endpoints {
        static let BASE_URL = "https://maps.googleapis.com/maps/api"

        case downloadPhoto(Bool, String, String)

        var stringValue: String {
            switch self {
            case .downloadPhoto(let needsFill, let fillColor, let points):
                return "\(Endpoints.BASE_URL)/staticmap?" +
                        "key=\(Auth.MAPS_API_KEY)&" +
                        "size=144x144&" +
                        "maptype=satellite&" +
                        "sensor=false&" +
                        "path=color:\(fillColor)|weight:\(needsFill ? "1" : "7")|fillcolor:\(needsFill ? "0x\(fillColor)" : "0x01000000")|\(points)"
            }
        }

        var url: URL {
            URL(string: stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        }
    }

    class func downloadMapData(_ points: String, needsFill: Bool, color: String, completion: @escaping (Data?, Error?) -> Void) {
        let url = Endpoints.downloadPhoto(needsFill, color, points).url
        DDLogVerbose("downloadPhoto() url=\(url)")

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }
        task.resume()
    }

}
