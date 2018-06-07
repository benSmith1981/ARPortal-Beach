//
//  DataLayer.swift
//  Evening 7 - ARPortal
//
//  Created by Ben Smith on 24/05/2018.
//  Copyright © 2018 Ben Smith. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

let herokuAPI = "https://23232ededDE:sdsd3432d8n8@diveapi.herokuapp.com/api/"

class DataLayer {
    
    static let shared = DataLayer()
    private init() { }
    typealias getPromoCodeCompletion = (String) -> Void

    public func getPromoCode(onCompletion: @escaping getPromoCodeCompletion) {
        Alamofire.request("\(herokuAPI)getPromoCode/",
            method: .get,
            encoding: JSONEncoding.default).responseJSON { (response) in
                switch response.result {
                case .success(let jsonData):
                    if let result = response.result.value {
                        let json = JSON(result)
                        onCompletion(json["dataResponse"].stringValue)
                        
                    }
                case .failure(let error):
                    print("error \(error)")
                }
        }
    }

}
