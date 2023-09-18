//
//  ChatUser.swift
//  Ping Me
//
//  Created by Manraj Singh on 14/09/23.
//

import Foundation

struct ChatUser : Identifiable{
    var id: String {uid}
    
    let uid,email,name,profileImageUrl: String
    init(data: [String:Any]){
        self.uid = data["uid"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.name = data["name"] as? String ?? ""
        self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
        
    }
}
