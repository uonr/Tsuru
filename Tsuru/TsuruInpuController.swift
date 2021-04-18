import Cocoa

import InputMethodKit

class TsuruInputController: IMKInputController {
    private var buffer = ""
    override func inputText(_ string: String!, client sender: Any!) -> Bool {
        if string == " " {
            self.buffer = ""
        } else {
            self.buffer += string
        }
        NSLog(self.buffer)
        return false
    }
}
