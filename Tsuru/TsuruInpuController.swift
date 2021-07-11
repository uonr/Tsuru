import Cocoa

import InputMethodKit

typealias Sender = (IMKTextInput & IMKUnicodeTextInput)

private let notFoundRange = NSMakeRange(NSNotFound, NSNotFound)

class TsuruInputController: IMKInputController {
    private var _originalString: String = "" // what the user typed
    private var _composedString: String = "" // currently selected transliteration candidate
    private var _candidates: [String] = [] // list of candidates to choose from
    override func composedString(_ sender: Any!) -> Any! {
        return self._composedString
    }
    override func originalString(_ sender: Any!) -> NSAttributedString! {
        return NSAttributedString(string: self._originalString)
    }
    override func candidates(_ sender: Any!) -> [Any]! {
        return self._candidates
    }
    private func castSender(_ sender: Any? = nil) -> Sender {
        guard let downcast = sender as? Sender else {
            return client() as! Sender
        }
        return downcast
    }
    private func writeMarkToClient(_ client: Sender,_ string: String) {
        client.setMarkedText(string,
                             selectionRange: NSMakeRange(0, string.count),
                             replacementRange: notFoundRange)
    }
    
    override func inputText(_ string: String!, client sender: Any!) -> Bool {
        let tx = castSender(sender)
        switch string {
//        case "1", "2", "3", "4", "5", "6", "7", "8", "9":
//            let n: Int = Int(string)!
//            if !candidatesWindow.isVisible() || n > self._candidates.count {
//                commitComposition(tx)
//                tx.insertText(string, replacementRange: notFoundRange)
//            } else {
//                self._composedString = self._candidates[n - 1]
//                commitComposition(tx)
//            }
        case " ":
            if candidatesWindow.isVisible() {
                tx.insertText(self._candidates[0])
                self._originalString = ""
                self._composedString = ""
                self._candidates = []
                candidatesWindow.hide()
            } else {
                tx.insertText(self._originalString + string)
                self._originalString = ""
                self._composedString = ""
                self._candidates = []
            }
        default:
            self._originalString += string
            let match = codeTable[self._originalString] ?? []
            if match.count == 0 {
                tx.insertText(self._originalString)
                self._originalString = ""
                self._composedString = ""
                self._candidates = []
                candidatesWindow.hide()
            } else {
                self._candidates = match
                tx.setMarkedText(self._originalString,
                                 selectionRange: NSMakeRange(0, self._originalString.count),
                                 replacementRange: notFoundRange)
                candidatesWindow.update()
                candidatesWindow.show()
            }
//            self._originalString = ""
//            self._composedString = ""
//            self._candidates = []
//            tx.insertText(string, replacementRange: notFoundRange)
//            if (match.count > 0) {
//                showCandidates(client: tx, string, codeTable[self._composedString]!)
//            } else {
//                commitComposition(tx)
//                tx.insertText(string, replacementRange: notFoundRange)
//            }
//            let match = codeTable[self._composedString] ?? []
//            if (codeTable[self._composedString] ?? []).count > 0 && !candidatesWindow.isVisible() {
//                showCandidates(client: tx, string, codeTable[self._composedString]!)
//            } else {
//                commitComposition(tx)
//                tx.insertText(string, replacementRange: notFoundRange)
//            }
        }
        return true
    }
    override func candidateSelected(_ candidateString: NSAttributedString!) {
        self._composedString = candidateString.string
        commitComposition(client())
    }
}
