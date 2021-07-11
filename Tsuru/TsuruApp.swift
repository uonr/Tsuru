import SwiftUI
import Cocoa
import InputMethodKit

let bundleIdentifier = Bundle.main.bundleIdentifier!
let connectionName =  "\(bundleIdentifier)_Connection"
var server = IMKServer()
var candidatesWindow = IMKCandidates()


var codeTable: [String: [String]] = [:]

@main
struct TsuruApp: App {
    init() {
        
        let codeTableAsset: NSDataAsset? = NSDataAsset(name: "flypy", bundle: Bundle.main)
        let codeTableRaw: String = String(decoding: codeTableAsset!.data, as: UTF8.self)
        server = IMKServer(name: connectionName, bundleIdentifier: bundleIdentifier)
        candidatesWindow = IMKCandidates(server: server, panelType: kIMKSingleRowSteppingCandidatePanel, styleType: kIMKMain)
        codeTableRaw.enumerateLines { line, _ in
            let splited = line.split(separator: "\t").map { String($0) }
            if splited.count != 2 {
                print(line)
            } else {
                codeTable[splited[1]] = (codeTable[splited[1]] ?? []) + [splited[0]]
            }
        }
        
    }
    
    var body: some Scene {
        WindowGroup {
            VStack {}
                .hidden()
        }
    }
}
