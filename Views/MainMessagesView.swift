//  MainMessagesView.swift
//  Ping Me
//
//  Created by Manraj Singh on 13/09/23.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseFirestoreSwift

class MainMessagesViewModel: ObservableObject{
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    @Published var isUserCurrentlyLoggedOut = false
    init(){
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        fetchCurrentUser()
        fetchRecentMessages()
    }
    @Published var recentMessages = [RecentMessage]()
    private var firestoreListener : ListenerRegistration?
    
     func fetchRecentMessages(){
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
         firestoreListener?.remove()
         self.recentMessages.removeAll()
        firestoreListener = FirebaseManager.shared.firestore
            .collection("Recent_messages")
            .document(uid)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen for recent messages: \(error)"
                    print(error)
                    return
                }
                querySnapshot?.documentChanges.forEach({ change in
                        let docId = change.document.documentID
                    if let index = self.recentMessages.firstIndex(where: { rm in
                        return rm.id == docId
                    }){
                        self.recentMessages.remove(at: index)
                    }
                    do{
                         let rm = try change.document.data(as: RecentMessage.self)
                            self.recentMessages.insert(rm, at: 0)
                        
                        
                    } catch{
                        print(error)
                    }
                    
                   
                })
            }
    }
     func fetchCurrentUser() {
       
      guard let uid =   FirebaseManager.shared.auth.currentUser?.uid else {
          self.errorMessage = "Could not fetch userid"
          return }
       
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("failed to fetch : ",error)
                return
            }
            guard let data = snapshot?.data() else {
                self.errorMessage = "No data Found"
                return}
            //print(data)
           // self.errorMessage = "Data: \(data.description) "
            self.chatUser = .init(data: data)
          //  self.errorMessage = chatUser.profileImageUrl
        }
    }
    
    
    func handleSignOut(){
        isUserCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
}

struct MainMessagesView: View {
    @State var shouldNavigateToChatLogView = false
    @State var shouldShowLogOutOptions = false
    @ObservedObject private var vm  = MainMessagesViewModel()
    private var chatLogViewModel = ChatLogViewModel(chatUser: nil)
    
    var body: some View {
        NavigationView {
            
            VStack {
               // Text("User: \(vm.chatUser?.uid ?? "")")
                customNavBar
                messagesView
                NavigationLink("", isActive: $shouldNavigateToChatLogView) {
                    ChatLogView(vm: chatLogViewModel)
                }
            }
            .overlay(
                newMessageButton, alignment: .bottom)
            .navigationBarHidden(true)
        }
       

    }
    
    
    private var customNavBar: some View {
        HStack(spacing: 16) {
            
            WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
                .resizable()
                .scaledToFit()
                .frame(width: 50,height: 50)
                .clipShape(Circle())
                .overlay(RoundedRectangle(cornerRadius: 44)
                    .stroke(Color(.label),lineWidth: 1))
                .shadow(radius: 5)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(vm.chatUser?.name ?? "")")
                    .font(.system(size: 24, weight: .bold))
                
                HStack {
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 14, height: 14)
                    Text("online")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.lightGray))
                }
                
            }
            
            Spacer()
            Button {
                shouldShowLogOutOptions.toggle()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.label))
            }
        }
        .padding()
        .actionSheet(isPresented: $shouldShowLogOutOptions) {
            .init(title: Text("Settings"), message: Text("What do you want to do?"), buttons: [
                .destructive(Text("Sign Out"), action: {
                    vm.handleSignOut()
                    print("handle sign out")
                }),
                    .cancel()
            ])
        }
        .fullScreenCover(isPresented: $vm.isUserCurrentlyLoggedOut,onDismiss: nil) {
            LoginView(didCompleteLoginProcess: {
                self.vm.isUserCurrentlyLoggedOut = false
                self.vm.fetchCurrentUser()
                self.vm.fetchRecentMessages()
            })
        }
    }
 
    private var messagesView: some View {
        ScrollView {
            ForEach(vm.recentMessages) { recentMessage in
                VStack {
                    Button {
                        let uid = FirebaseManager.shared.auth.currentUser?.uid == recentMessage.fromId ? recentMessage.toId : recentMessage.fromId
                        self.chatUser = .init(data: [FirebaseConstants.name:recentMessage.name,FirebaseConstants.profileImageUrl:recentMessage.profileImageUrl,FirebaseConstants.uid: uid])
                        self.chatLogViewModel.chatUser = self.chatUser
                        self.chatLogViewModel.fetchMessages()
                        self.shouldNavigateToChatLogView.toggle()
                    } label: {
                        HStack(spacing: 16) {
                            WebImage(url: URL(string: recentMessage.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64,height: 64)
                                .clipped()
                                .cornerRadius(64)
                                .overlay(RoundedRectangle(cornerRadius: 64).stroke(Color.black,lineWidth:2))
                                .shadow(radius: 5)
                            
                            VStack(alignment: .leading,spacing: 8) {
                                Text(recentMessage.name)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(.label))
                                    .multilineTextAlignment(.leading)
                                Text(recentMessage.text)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(.darkGray))
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(1)
                            }
                            Spacer()
                            
                            Text(recentMessage.timeAgo)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }

                    
                    Divider()
                        .padding(.vertical, 8)
                }.padding(.horizontal)
                
            }.padding(.bottom, 50)
            
        }
    }
    @State var shouldShowNewMessageScreen = false
    private var newMessageButton: some View {
        Button {
            shouldShowNewMessageScreen.toggle()
        } label: {
            HStack {
                Spacer()
                Text("+ New Message")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
                .background(Color.blue)
                .cornerRadius(32)
                .padding(.horizontal)
                .shadow(radius: 15)
        }
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
            CreateNewMessageView(didSelectNewUser: { user
                in
                print(user.name)
                self.shouldNavigateToChatLogView.toggle()
                self.chatUser = user
                self.chatLogViewModel.chatUser = user
                self.chatLogViewModel.fetchMessages()
            })
        }
    }
    @State var chatUser : ChatUser?
}

struct MainMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
    }
}
