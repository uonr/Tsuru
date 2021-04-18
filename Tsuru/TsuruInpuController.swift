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
                             replacementRange: NSMakeRange(NSNotFound, NSNotFound))
    }
    
    func showCandidates(client tx: Sender, _ input: String!, _ candidates: [String]) {
        if (candidates.count == 0) {
            self._composedString = input
            commitComposition(tx)
        } else {
            self._originalString += input
            let first = candidates.first!
            self._composedString += first
            self._candidates = candidates
            candidatesWindow.update()
            candidatesWindow.show()
            writeMarkToClient(tx, first)
        }
    }

    override func inputText(_ string: String!, client sender: Any!) -> Bool {
        let tx = castSender(sender)
        switch string {
        case "h" where !candidatesWindow.isVisible():
            showCandidates(client: tx, string, ["h", "hello"])
        case "1", "2", "3", "4", "5", "6", "7", "8", "9":
            let n: Int = Int(string)!
            if !candidatesWindow.isVisible() || n > self._candidates.count {
                commitComposition(tx)
                tx.insertText(string, replacementRange: notFoundRange)
            } else {
                self._composedString = self._candidates[n - 1]
                commitComposition(tx)
            }
        case " " where candidatesWindow.isVisible():
            commitComposition(tx)
        default:
            commitComposition(tx)
            tx.insertText(string, replacementRange: notFoundRange)
        }
        return true
    }
    override func candidateSelected(_ candidateString: NSAttributedString!) {
        self._composedString = candidateString.string
        commitComposition(client())
    }
    override func commitComposition(_ sender: Any!) {
        if !self._composedString.isEmpty {
            let tx = castSender(sender)
            tx.insertText(self._composedString, replacementRange: notFoundRange)
        }

        self._originalString = ""
        self._composedString = ""
        self._candidates = []
        
        candidatesWindow.hide()
    }
}
