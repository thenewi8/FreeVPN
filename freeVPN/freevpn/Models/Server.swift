//
//  Server.swift
//  freevpn
//
//  Created by ligulfzhou on 7/13/16.
//  Copyright © 2016 ligulfzhou. All rights reserved.
//

import Foundation

final class Server: ResponseObjectSerializable, ResponseCollectionSerializable{
    
    var ip: String
    var country: String
    var country_cn: String
    var city: String
    var city_cn: String
    var remote_id: String
    var code: String
    
    /*var description: String{
        return "Server: { ip: \(ip), country: \(country), city: \(city) }"
    }*/

    public init?(response: HTTPURLResponse, representation: AnyObject) {
        guard
            let representation = representation as? [String: Any],
            let ip = representation["ip"] as? String,
            let country = representation["country"] as? String,
            let country_cn = representation["country_cn"] as? String,
            let city = representation["city"] as? String,
            let city_cn = representation["city_cn"] as? String,
            let remote_id = representation["remote_id"] as? String,
            let code = representation["code"] as? String
            else{ return nil }
        self.ip = ip
        self.country = country
        self.country_cn = country_cn
        self.city = city
        self.city_cn = city_cn
        self.remote_id = remote_id
        self.code = code
    }

    static func collection(from response: HTTPURLResponse, withRepresentation representation: Any) -> [Server] {
        var collection: [Server] = []
        
        if let representation = (representation as AnyObject).value(forKey: "servers") as? [[String: Any]] {
            for itemRepresentation in representation {
                if let item = Server(response: response, representation: itemRepresentation as AnyObject) {
                    collection.append(item)
                }
            }
        }
        
        return collection
    }
}

