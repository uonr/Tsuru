import SwiftUI
import Cocoa
import InputMethodKit

let bundleIdentifier = Bundle.main.bundleIdentifier!
let connectionName =  "\(bundleIdentifier)_Connection"
var server = IMKServer()
var candidatesWindow = IMKCandidates()


@main
struct TsuruApp: App {
    init() {
        server = IMKServer(name: connectionName, bundleIdentifier: bundleIdentifier)
        candidatesWindow = IMKCandidates(server: server, panelType: kIMKSingleRowSteppingCandidatePanel, styleType: kIMKMain)
    }
    
    var body: some Scene {
        WindowGroup {
            EmptyView()
                .opacity(0.0)
                .hidden()
        }
    }
}
