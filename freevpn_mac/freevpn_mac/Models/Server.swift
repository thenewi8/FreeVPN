//
//  Server.swift
//  freevpn
//
//  Created by ligulfzhou on 7/13/16.
//  Copyright © 2016 ligulfzhou. All rights reserved.
//

import Foundation


final class Server: ResponseObjectSerializable, ResponseCollectionSerializable, CustomStringConvertible{
    
    let ip: String
    let country: String
    let country_cn: String
    let city: String
    let city_cn: String
    let remote_id: String
    
    var description: String{
        return "Server: { ip: \(ip), country: \(country), city: \(city) }"
    }

    public init?(response: HTTPURLResponse, representation: AnyObject) {
        guard
            let representation = representation as? [String: Any],
            let ip = representation["ip"] as? String,
            let country = representation["country"] as? String,
            let country_cn = representation["country_cn"] as? String,
            let city = representation["city"] as? String,
            let city_cn = representation["city_cn"] as? String,
            let remote_id = representation["remote_id"] as? String
            else{ return nil }
        self.ip = ip
        self.country = country
        self.country_cn = country_cn
        self.city = city
        self.city_cn = city_cn
        self.remote_id = remote_id
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
