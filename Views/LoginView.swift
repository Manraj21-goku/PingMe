//
//  ContentView.swift
//  Ping Me
//
//  Created by Manraj Singh on 11/09/23.
//

import SwiftUI
import Firebase
import FirebaseStorage



struct LoginView: View {
    let didCompleteLoginProcess: () -> ()
    @EnvironmentObject private var launchScreenState: LaunchScreenStateManager
    @State private var isLoginMode = false
    @State private var email = ""
    @State  private var pass = ""
    @State  private var name = ""
    @State private var conf = ""
    @State  private var shouldShowImagePicker = false
    var body: some View {
        NavigationView{
            ZStack{
                Color(red: 9.9, green: 0.7, blue: 0.9)
                VStack(spacing:20){
                    Group{
                        Text("Ping Me")
                            .foregroundColor(.white)
                            .font(.system(size: 40,weight: .bold,design: .rounded))
                            .offset(x:-100,y: isLoginMode ? -100 : -50)
                        Picker(selection: $isLoginMode, label: Text("Picker here")) {
                            Text("Log in")
                                .tag(true)
                            Text("Create Account")
                                .tag(false)
                        }.pickerStyle(SegmentedPickerStyle())
                            .padding()
                            .offset(y: isLoginMode ? -110 : -60)
                        if !isLoginMode{
                            Button{
                                shouldShowImagePicker.toggle()
                            } label: {
                                VStack{
                                    if let image = self.image {
                                        Image(uiImage: image)
                                            .resizable()
                                            .frame(width: 100,height: 100)
                                            .scaledToFit()
                                            .clipShape(Circle())
                                    } else{
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 70))
                                            .foregroundColor(.black)
                                    }
                                }
                                
                            }
                            .offset(y:-80)
                        }
                        if !isLoginMode{
                            TextField("",text: $name)
                                .placeholder(when: name.isEmpty) {
                                    Text("Name").foregroundColor(.black)
                                }
                                .cornerRadius(5)
                                .frame(width: 300)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .offset(x:-10,y: -90)
                                .foregroundColor(.black)
                                .textFieldStyle(.plain)
                            Rectangle()
                                .frame(width: 300,height: 1)
                                .foregroundColor(.black)
                                .offset(x:-10,y: -100)
                            
                        }
                        TextField("",text: $email)
                            .placeholder(when: email.isEmpty) {
                                Text("Email").foregroundColor(.black)
                            }
                            .cornerRadius(5)
                            .frame(width: 300)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .offset(x:-10,y: isLoginMode ? -100 : -100)
                            .foregroundColor(.black)
                            .textFieldStyle(.plain)
                        Rectangle()
                            .frame(width: 300,height: 1)
                            .foregroundColor(.black)
                            .offset(x:-10,y: -115)
                        SecureField("",text: $pass)
                            .placeholder(when: pass.isEmpty) {
                                Text("Password").foregroundColor(.black)
                            }
                            .cornerRadius(5)
                            .frame(width: 300)
                            .offset(x:-10,y: isLoginMode ? -100 : -110)
                            .foregroundColor(.black)
                            .textFieldStyle(.plain)
                        //.bold()
                        Rectangle()
                            .frame(width: 300,height: 1)
                            .foregroundColor(.black)
                            .offset(x:-10,y: -120)
                        if !isLoginMode{
                            SecureField("",text: $conf)
                                .placeholder(when: conf.isEmpty) {
                                    Text("Confirm Password").foregroundColor(.black)
                                }
                                .cornerRadius(5)
                                .frame(width: 300)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .offset(x:-10,y: -120)
                                .foregroundColor(.black)
                                .textFieldStyle(.plain)
                            Rectangle()
                                .frame(width: 300,height: 1)
                                .foregroundColor(.black)
                                .offset(x:-10,y: -130)
                        }
                    }
                    
                    Button {
                        handleAction()
                    } label: {
                        
                        Text(isLoginMode ?  "Log in": "Create Account!")
                            .bold()
                            .frame(width: 200,height: 40)
                            .background(RoundedRectangle(cornerRadius: 10,style: .continuous)
                                .fill(.linearGradient(colors: [.black], startPoint: .top, endPoint: .bottomTrailing))
                            )
                            .foregroundColor(.white)
                    }
                    .padding(.top)
                    
                    .offset(y: isLoginMode ? -90 : -110)
                    Text(self.loginStatusMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    
                    if isLoginMode{
                        Button {
                            forgot()
                            print("A mail should be coming!")
                            
                        } label: {
                            Text("Forgot Password?")
                                .bold()
                                .foregroundColor(.black)
                        }
                        .padding(.top)
                        .offset(y:-100)
                    }
                    
                    
                }
                HStack{
                    //   Image(systemName: "message.fill")
                    //     .foregroundColor(.white)
                    //   .font(.system(size: 100))
                    // .offset(x:40,y: 250)
                    Image(systemName: "bird.fill")
                        .foregroundColor(.black)
                        .font(.system(size: 40))
                        .offset(x: isLoginMode ? 100:100,y: isLoginMode ? -290 : -320)
                    
                    
                }
            }
            .ignoresSafeArea()
            .task {
                //try? await getDataFromApi()
                try? await Task.sleep(for: Duration.seconds(1))
                //self.launchScreenState.dismiss()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil) {
            ImagePicker(image: $image)
        }
    }
    @State var image: UIImage?
    private func handleAction(){
        if isLoginMode{
            loginAccount()
            print("Should login")
        }
        else{
            createNewAccount()
            print("Register a new account")
        }
    }
    private func loginAccount(){
        let error = validate1()
        if let error = error{
            loginStatusMessage = error
        }
        else{
            Auth.auth().signIn(withEmail: email, password: pass) { result,error in
                if let err = error{
                    print("Failed to log in User:",err)
                    self.loginStatusMessage = "Ummm looks like there is some mistake!"
                    return
                }
                print("Succesfully logged in!: \(result?.user.uid ?? "")")
                loginStatusMessage = "All done.\n Enjoy Pinging!"
                self.didCompleteLoginProcess()
                
            }
        }
    }
    @State var loginStatusMessage = ""
    
    
    private func createNewAccount(){
        let error = validate2()
        if error != nil{
            loginStatusMessage = error!
            print("Error")
        }
        else{
            if self.image == nil{
                self.loginStatusMessage = "You must select an avtar Image"
                return
            }
            Auth.auth().createUser(withEmail: email, password: pass){ result,error in
                if let err = error{
                    print("Failed to create User:",err)
                    self.loginStatusMessage = "Ummm looks like there is some mistake!"
                    return
                }
                print("Succesfully created new account: \(result?.user.uid ?? "")")
                loginStatusMessage = "All done.\n Enjoy Pinging!"
                
                self.persistImageToStorage()
                
            }
        }
    }
    private func persistImageToStorage(){
        let filename = UUID().uuidString
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid
        else{return}
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else{return}
        ref.putData(imageData,metadata: nil) { metadata, err in
            if let err = err{
                self.loginStatusMessage = "Failed to store image to Firebase: \(err)"
                return
            }
            ref.downloadURL { url, err in
                if let err = err{
                    self.loginStatusMessage = "Failed to retrieve image from Firebase: \(err)"
                    return
                }
                self.loginStatusMessage = "Yeah we got your Face!"
                guard let url = url else{return}
                self.storeUserInformation(imageProfileUrl: url)
            }
        }
    }
    private func storeUserInformation(imageProfileUrl: URL){
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else{return}
        let userData = ["email": self.email,"name": self.name,"uid": uid,"profileImageUrl": imageProfileUrl.absoluteString ]
        FirebaseManager.shared.firestore.collection("users").document(uid).setData(userData){ err in
            if let err = err {
                print(err)
                self.loginStatusMessage = "\(err)"
                return
            }
            self.didCompleteLoginProcess()
        }
    }
    private func forgot(){
        let error = validateForEmail()
        if error != nil{
            loginStatusMessage = "Enter an Email!"
        }
        else{
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if error != nil{
                    print(error!.localizedDescription)
                    loginStatusMessage = error!.localizedDescription
                }
                else{
                    loginStatusMessage = "A mail should be coming!"
                }
                
            }
        }
    }
    
    private func validateForEmail()-> String?{
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty{
            return "Please Enter the Email!"
        }
        return nil
    }
    private func validate1() -> String?  {
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pass.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Please fill all the fields!"
        }
        if !Utilities.isValidEmailAddress(emailAddressString: email) {
            return "Email format is incorrect!"
        }
        if !Utilities.isPasswordValid(pass) {
            return "Incorrect Password!"
        }
        
        return nil
    }
    
    
    private func validate2() -> String? {
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pass.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Please fill all the fields!"
        }
        if name.isEmpty{
            return "Please fill your name!"
        }
        if !Utilities.isValidEmailAddress(emailAddressString: email) {
            return "Email format is incorrect!"
        }
        if !Utilities.isPasswordValid(pass) {
            return "Password too weak!"
        }
        if pass != conf{
            return"Password Does not match"
        }
        
        
        return nil
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(didCompleteLoginProcess: {
            
        })
            .environmentObject(LaunchScreenStateManager())
    }
}
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
            
            ZStack(alignment: alignment) {
                placeholder().opacity(shouldShow ? 1 : 0)
                self
            }
        }
}
