//
//  ChatLogView.swift
//  Ping Me
//
//  Created by Manraj Singh on 14/09/23.
//

import SwiftUI
import Firebase

struct FirebaseConstants{
    static let fromId = "fromId"
    static let toId = "toId"
    static let text = "text"
    static let timestamp = "timestamp"
    static let profileImageUrl = "profileImageUrl"
    static let name = "name"
    static let uid = "uid"
    static let isSent = "false"
}

struct ChatMessage: Identifiable {
    var id: String { documentId }
    let documentId: String
    let fromId,toId,text: String
    init(documentId:String,data: [String:Any]){
        self.documentId = documentId
        self.fromId = data[FirebaseConstants.fromId] as? String ?? ""
        self.toId = data[FirebaseConstants.toId] as? String ?? ""
        self.text = data[FirebaseConstants.text] as? String ?? ""
    }
}

class ChatLogViewModel: ObservableObject{
    @Published var chatText = ""
    @Published var errorMessage = ""
    @Published var chatMessages = [ChatMessage]()
    var chatUser: ChatUser?
    init(chatUser: ChatUser?){
        self.chatUser = chatUser
        fetchMessages()
    }
     var firestoreListener : ListenerRegistration?
     func fetchMessages(){
        
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
         firestoreListener?.remove()
         chatMessages.removeAll()
        firestoreListener = FirebaseManager.shared.firestore.collection("Messages")
            .document(fromId)
            .collection(toId)
            .order(by: FirebaseConstants.timestamp)
            .addSnapshotListener { querySnapshot, error in
                if let error = error{
                    self.errorMessage = "failed to listen for messages: \(error)"
                    print(error)
                    return
                }
                querySnapshot?.documentChanges.forEach({ change in
                    if change.type == .added{
                        let data = change.document.data()
                        self.chatMessages.append(.init(documentId: change.document.documentID, data: data))
                        
                    }
                })
                DispatchQueue.main.async {
                    self.count += 1
                }
            }
    }
    
    func handleSend(){
        print(chatText)
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid
        else {return}
        guard let toId = chatUser?.uid else {return}
        let document = FirebaseManager.shared.firestore
            .collection("Messages")
            .document(fromId)
            .collection(toId)
            .document()
        let messageData = [FirebaseConstants.fromId: fromId,FirebaseConstants.toId:toId,FirebaseConstants.text:self.chatText,"timestamp":Timestamp()] as [String : Any]
        if chatText != ""{
            document.setData(messageData){ error in
                if let error = error {
                    self.errorMessage = "Failed to save messages:\(error)"
                    return
                }
                print("Successfully saved")
                self.persistRecentMessage()
                self.chatText = ""
                self.count += 1
            }
        }
       
        let recipientMessagedocument = FirebaseManager.shared.firestore.collection("Messages")
            .document(toId)
            .collection(fromId)
            .document()
        if chatText != "" {
            recipientMessagedocument.setData(messageData){ error in
                if let error = error {
                    self.errorMessage = "Failed to retrieve messages:\(error)"
                    return
                }
                print("Successfully retrieved")
            }
        }
        
        
    }
    private func persistRecentMessage(){
        
        guard let chatUser = chatUser else { return }
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid
        else { return }
        guard let toId = self.chatUser?.uid else { return }
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid
        else {return}
        
        
        
        let document = FirebaseManager.shared.firestore
            .collection("Recent_messages")
            .document(uid)
            .collection("messages")
            .document(toId)
        let document_r = FirebaseManager.shared.firestore
            .collection("Recent_messages")
            .document(uid)
            .collection("messages_rec")
            .document(fromId)
        let data = [
            FirebaseConstants.timestamp :Timestamp(),
            FirebaseConstants.text: self.chatText,
            FirebaseConstants.fromId: uid,
            FirebaseConstants.toId: toId,
            FirebaseConstants.profileImageUrl: chatUser.profileImageUrl,
            FirebaseConstants.name: chatUser.name,
            FirebaseConstants.isSent : true
        ] as [String: Any]
        // kuch toh aur data bnana hai
        let data_r: [String:Any] = [
            FirebaseConstants.timestamp: Timestamp(),
            FirebaseConstants.text: self.chatText,
            FirebaseConstants.fromId: fromId,
            FirebaseConstants.toId: uid,
            FirebaseConstants.profileImageUrl: chatUser.profileImageUrl,
            FirebaseConstants.name: chatUser.name,
            FirebaseConstants.isSent : false
        ] as [String: Any]
     
        
        document.setData(data) { error in
            if let error = error {
                self.errorMessage = "Failed to save recent message: \(error)"
                print("Failed to save recent messages:\(error)")
                return
            }
        }
        document_r.setData(data_r){ error in
            if let error = error{
                self.errorMessage = "Failed to save recent message: \(error)"
                print("Failed to save recent messages:\(error)")
                return
            }
            
        }
       

    }
    @Published var count = 0
}
struct ChatLogView: View {
    
//    let chatUser: ChatUser?
//    init(chatUser: ChatUser?){
//        self.chatUser = chatUser
//        self.vm = .init(chatUser: chatUser)
//    }
    
    //@State var chatText = ""
    @ObservedObject var vm : ChatLogViewModel
    
    var body: some View {
        ZStack {
            messagesView
            Text(vm.errorMessage)
            VStack(spacing: 0) {
                Spacer()
                chatBottomBar
                    .background(Color.white.ignoresSafeArea())
            }
        }
        .navigationTitle(vm.chatUser?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear{
            vm.firestoreListener?.remove()
        }
//        .navigationBarItems(trailing: Button(action: {
//            vm.count += 1
//        }, label: {
//            Text("Count: \(vm.count)")
//        }))
    }
    static let emptyScrollToString = "Empty"
    private var messagesView: some View {
        ScrollView {
            ScrollViewReader { scrollViewProxy in
                VStack{
                    ForEach(vm.chatMessages){ message in
                        MessageView(message: message)
                    }
                    
                    HStack{ Spacer() }
                        .id(Self.emptyScrollToString)
                        .frame(height: 50)
                }
                .onReceive(vm.$count){ _ in
                    withAnimation(.easeOut(duration: 0.5)){
                        scrollViewProxy.scrollTo("Empty",anchor: .bottom)
                    }
                    
                    
                }
                
            }
           
        }
        .background(Color(.init(white: 0.95, alpha: 1)))
        
    }
    
    private var chatBottomBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 24))
                .foregroundColor(Color(.darkGray))
            ZStack {
                DescriptionPlaceholder()
                TextEditor(text: $vm.chatText)
                    .opacity(vm.chatText.isEmpty ? 0.5 : 1)
            }
            .frame(height: 40)
            
            Button {
                vm.handleSend()
            } label: {
                Text("Send")
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(20)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
struct MessageView: View{
    let message: ChatMessage
    var body: some View{
        VStack{
            if message.fromId == FirebaseManager.shared.auth.currentUser?.uid {
                HStack {
                    Spacer()
                    HStack {
                        Text(message.text)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(20)
                }
                
                
            } else {
                HStack {
                    HStack {
                        Text(message.text)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.green)
                    .cornerRadius(20)
                    Spacer()
                }
                
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}
private struct DescriptionPlaceholder: View {
    var body: some View {
        HStack {
            Text("Description")
                .foregroundColor(Color(.gray))
                .font(.system(size: 17))
                .padding(.leading, 5)
                .padding(.top, -4)
            Spacer()
        }
    }
}

struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        //        NavigationView {
        //            ChatLogView(chatUser: .init(data: ["uid":"SH5vRCD8Y8d37WV89xO7bBj0IRO2","name":"Thorfinn"]))
        //        }
        MainMessagesView()
        
    }
}

