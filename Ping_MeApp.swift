//
//  Ping_MeApp.swift
//  Ping Me
//
//  Created by Manraj Singh on 11/09/23.
//

import SwiftUI
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}


@main
struct Ping_MeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var launchScreenState = LaunchScreenStateManager()
    var body: some Scene {
        WindowGroup {
            ZStack{
                //LoginView()
                MainMessagesView()
               // if launchScreenState.state != .finished{
                 //   LaunchScreenView()
                //}
            }//.environmentObject(launchScreenState)
        }
    }
}
