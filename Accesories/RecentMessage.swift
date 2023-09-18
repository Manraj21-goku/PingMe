//
//  RecentMessage.swift
//  Ping Me
//
//  Created by Manraj Singh on 17/09/23.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct RecentMessage: Codable, Identifiable{
    @DocumentID var id: String?
    let text,name: String
    let fromId,toId: String
    let profileImageUrl : String
    let timestamp: Date
    
    var timeAgo: String{
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
}
