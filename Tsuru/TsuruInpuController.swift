import Cocoa

import InputMethodKit

typealias Sender = (IMKTextInput & IMKUnicodeTextInput)

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

    override func inputText(_ string: String!, client sender: Any!) -> Bool {
        let IME_HANDLE = true
        let SYS_HANDLE = false
        let tx = castSender(sender)
        switch string {
        case "h":
            self._originalString = string
            let s = "hello"
            self._composedString = s
            self._candidates = ["hello", "h"]
            writeMarkToClient(tx, s)
            candidatesWindow.show()
            candidatesWindow.update()
        case "1", "2", "3", "4", "5", "6", "7", "8", "9":
            let n: Int = Int(string)!
            if !candidatesWindow.isVisible() || n > self._candidates.count {
                fallthrough
            }
            self._composedString = self._candidates[n - 1]
            commitComposition(tx)
        case " " where candidatesWindow.isVisible():
            commitComposition(tx)
        default:
            return SYS_HANDLE
        }
        return IME_HANDLE
    }
    override func commitComposition(_ sender: Any!) {
        let tx = castSender(sender)
        tx.insertText(self._composedString)

        self._originalString = ""
        self._composedString = ""
        self._candidates = []

        candidatesWindow.hide()
    }
}
