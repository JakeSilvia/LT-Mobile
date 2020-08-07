//
//  StartSession.swift
//  SwiftSH Example
//
//  Created by Jake Silvia on 8/7/20.
//  Copyright © 2020 Tommaso Madonia. All rights reserved.
//

import Foundation

func startSession (agentid: String) {
    _ = [ "token":"9cfe36ff-ee1b-43fc-892f-56f6cec85973", "email":"jake+test1@addigy.com", "orgid":"e67e2d3f-4b4a-11e5-90dd-0db5c31101ad", "policies":"None", "realm":"dev", "role":"power", "org_license":"" ]
    let url = URL(string: "https://dev.addigy.com/create_ssh_tunnel/")!
    var request = URLRequest(url: url)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpMethod = "POST"
//    request.httpBody = try? JSONEncoder().encode(order); else do {
//        print("Failed to encode order")
//        return
//    }
    URLSession.shared.dataTask(with: request) { data, response, error in
        // step 4
    }.resume()

}
