//
//  AlamofireExtension.swift
//  freevpn
//
//  Created by ligulfzhou on 5/4/16.
//  Copyright © 2016 ligulfzhou. All rights reserved.
//
//  copy from Photomania, the author is Essan Parto
//

import UIKit
import Alamofire

enum BackendError: Error {
    case network(error: Error) // Capture any underlying Error from the URLSession API
    case dataSerialization(error: Error)
    case jsonSerialization(error: Error)
    case xmlSerialization(error: Error)
    case objectSerialization(reason: String)
}

protocol ResponseCollectionSerializable {
    static func collection(from response: HTTPURLResponse, withRepresentation representation: Any) -> [Self]
}
/*
extension ResponseCollectionSerializable where Self: ResponseObjectSerializable {
    static func collection(from response: HTTPURLResponse, withRepresentation representation: Any) -> [Self] {
        var collection: [Self] = []
        
        if let representation = representation as? [[String: Any]] {
            for itemRepresentation in representation {
                if let item = Self(response: response, representation: itemRepresentation as AnyObject) {
                    collection.append(item)
                }
            }
        }
        
        return collection
    }
}
*/

extension DataRequest {
    @discardableResult
    func responseCollection<T: ResponseCollectionSerializable>(
        queue: DispatchQueue? = nil,
        completionHandler: @escaping (DataResponse<[T]>) -> Void) -> Self
    {
        let responseSerializer = DataResponseSerializer<[T]> { request, response, data, error in
            guard error == nil else { return .failure(BackendError.network(error: error!)) }
            
            let jsonSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
            let result = jsonSerializer.serializeResponse(request, response, data, nil)
            
            guard case let .success(jsonObject) = result else {
                return .failure(BackendError.jsonSerialization(error: result.error!))
            }
            
            guard let response = response else {
                let reason = "Response collection could not be serialized due to nil response."
                return .failure(BackendError.objectSerialization(reason: reason))
            }
            
            return .success(T.collection(from: response, withRepresentation: jsonObject))
        }
        
        return response(responseSerializer: responseSerializer, completionHandler: completionHandler)
    }
}


public protocol ResponseObjectSerializable {
    init?(response: HTTPURLResponse, representation: AnyObject)
}

extension DataRequest {
    func responseObject<T: ResponseObjectSerializable>(
        queue: DispatchQueue? = nil,
        completionHandler: @escaping (DataResponse<T>) -> Void)
        -> Self
    {
        let responseSerializer = DataResponseSerializer<T> { request, response, data, error in
            guard error == nil else { return .failure(BackendError.network(error: error!)) }
            
            let jsonResponseSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
            let result = jsonResponseSerializer.serializeResponse(request, response, data, nil)
            
            guard case let .success(jsonObject) = result else {
                return .failure(BackendError.jsonSerialization(error: result.error!))
            }
            
            guard let response = response, let responseObject = T(response: response, representation: jsonObject as AnyObject) else {
                return .failure(BackendError.objectSerialization(reason: "JSON could not be serialized: \(jsonObject)"))
            }
            
            return .success(responseObject)
        }
        
        return response(queue: queue, responseSerializer: responseSerializer, completionHandler: completionHandler)
    }
}

/*
extension Alamofire.Request {
    class func imageResponseSerializer() -> DataResponseSerializer<UIImage?, NSError> {
        return ResponseSerializer { request, response, data, error in
            guard error == nil else { return .Failure(error!) }
            
            guard let validData = data else {
                let failureReason = "数据无法被序列化，因为接收到的数据为空"
                let error = Error.errorWithCode(.DataSerializationFailed, failureReason: failureReason)
                return .Failure(error)
            }
            
            let image = UIImage(data: validData, scale: UIScreen.mainScreen().scale)
            return .Success(image)
        }
    }
    
    public func responseImage(completionHandler: (DataResponseSerializer<UIImage?, NSError>) -> Void) -> Self {
        return response(responseSerializer: Request.imageResponseSerializer(), completionHandler: completionHandler)
    }
}
*/

struct FreeVPN {
    
    enum Router: URLRequestConvertible {

        static let baseURLString = "https://freevpn.ligulfzhou.com"
        static let consumerKey = "HVhSQ8stAClpTASwePsvjFurYn1P3wo7XMPLyWPt"

        case getVpnAcnt()   //获取vpn账号（已废弃）
        case getFeedback(Int, Int)    //获取反馈列表（未使用）
        case postFeedback(String, String, String)   //提交反馈
        case getServer()    //获取vpn的服务器列表
        case getXsrfToken()    //获取xsrf token
        case postUser(String)   //注册用户
        case postCheckIn(String)  //签到
        case postRate(String)   // 评价后赠送时间
        case postPay(String, String) //购买套餐
        case postBeforePay(String, String)  //下单前确保10分钟内无其它订单
        case getOrders(String)   //获取用户的订单列表
        case postLogin(String, String)  //登录
        case putChangePassword(String, String)   //修改密码
        case postBindEmail(String, String)   //绑定密码
        
        func asURLRequest() throws -> URLRequest {
            let result: (method: String, path: String, parameters: [String: AnyObject]) = {
                switch self {
                case .getVpnAcnt():
                    let params = Dictionary<String, AnyObject>()
                    return ("GET", "/api/vpnacnt", params)
                case .getFeedback(let page, let page_size):
                    let params = ["page": "\(page)", "page_size": "\(page_size)"]
                    return ("GET", "/api/feedback", params as [String : AnyObject])
                case .postFeedback(let name, let qq, let feedback):
                    let params = ["name": name, "qq": qq, "feedback": feedback]
                    return ("POST", "/api/feedback", params as [String : AnyObject])
                case .getServer():
                    let params = Dictionary<String, AnyObject>()
                    return ("GET", "/api/server", params)
                case .getXsrfToken():
                    let params = Dictionary<String, AnyObject>()
                    return ("GET", "/api/auth/init", params)
                case .postUser(let username):
                    let params = ["username": username]
                    return ("POST", "/api/auth/user", params as [String : AnyObject])
                case .postCheckIn(let username):
                    let params = ["username": username]
                    return ("POST", "/api/checkin", params as [String : AnyObject])
                case .postRate(let username):
                    let params = ["username": username]
                    return ("POST", "/api/rate", params as [String: AnyObject])
                case .postPay(let username, let plan_identifier):
                    let params = ["username": username, "plan_identifier": plan_identifier]
                    return ("POST", "/api/afterpay", params as [String : AnyObject])
                case .postBeforePay(let username, let plan_identifier):
                    let params = ["username": username, "plan_identifier": plan_identifier]
                    return ("POST", "/api/beforepay", params as [String : AnyObject])
                case .getOrders(let username):
                    let params = ["username": username]
                    return ("GET", "/api/user/order", params as [String : AnyObject])
                case .postLogin(let username, let password):
                    let params = ["username": username, "password": password]
                    return ("POST", "/api/auth/login", params as [String : AnyObject])
                case .putChangePassword(let username, let password):
                    let params = ["username": username, "password": password]
                    return ("PUT", "/api/auth/login", params as [String : AnyObject])
                case .postBindEmail(let username, let email):
                    let params = ["username": username, "email": email]
                    return ("POST", "/api/bind/email", params as [String : AnyObject])
                }
            }()
            
            let url = try Router.baseURLString.asURL()
            var urlRequest = URLRequest(url: url.appendingPathComponent(result.path))
            urlRequest.httpMethod = result.method
            let xsrfToken = ""
            urlRequest.allHTTPHeaderFields = ["X-CSRFToken": xsrfToken]
            return try URLEncoding.default.encode(urlRequest, with: result.parameters)
        }
    }
    
}




