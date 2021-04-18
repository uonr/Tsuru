import SwiftUI
import Cocoa
import InputMethodKit


let ConnectionName = "TsuruIMEConnection"
var server = IMKServer()
var candidatesWindow = IMKCandidates()


@main
struct TsuruApp: App {
    init() {
        server = IMKServer(name: ConnectionName, bundleIdentifier: Bundle.main.bundleIdentifier)
        candidatesWindow = IMKCandidates(server: server, panelType: kIMKSingleRowSteppingCandidatePanel, styleType:kIMKMain)
    }
    
    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
    }
}
