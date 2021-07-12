import Cocoa

import InputMethodKit

typealias Client = (IMKTextInput & IMKUnicodeTextInput)

private let notFoundRange = NSMakeRange(NSNotFound, NSNotFound)
let handled = true
let unhandled = false

// convert Int representing a Unicode character to a Character
func char(_ unicodeInt: Int) -> Character {
    return Character(UnicodeScalar(unicodeInt) ?? UnicodeScalar(0))
}

let arrowUp = char(NSUpArrowFunctionKey)
let arrowDown = char(NSDownArrowFunctionKey)
let arrowLeft = char(NSLeftArrowFunctionKey)
let arrowRight = char(NSRightArrowFunctionKey)
let backspaceKey = char(NSBackspaceCharacter)
let enterKey = char(NSEnterCharacter)
let returnKey = char(NSCarriageReturnCharacter)
let shiftKeyCode: UInt16 = 0x38
let escapeKeyCode: UInt16 = 0x35

class TsuruInputController: IMKInputController {
    private var inputed: String = "" // what the user typed
    private var matched: [String] = []
    private var manuallyRawMode = false
    override func recognizedEvents(_ sender: Any!) -> Int {
        // https://stackoverflow.com/a/34245230
        return Int(NSEvent.EventTypeMask.keyDown.rawValue | NSEvent.EventTypeMask.flagsChanged.rawValue)
    }
    private func updateInput(_ next: String) {
        if next.isEmpty {
            self.inputed = ""
            self.matched = []
            self.manuallyRawMode = false
            candidatesWindow.hide()
            return
        }
        self.inputed = next
        self.matched = codeTable[inputed] ?? []
    }

    override func deactivateServer(_ sender: Any!) {
        let client = getClient()
        if !inputed.isEmpty {
            client.insertText(inputed, replacementRange: notFoundRange)
        } else {
            writeMarkToClient(client, "")
        }
        updateInput("")
    }
    override func composedString(_ sender: Any!) -> Any! {
        return self.inputed
    }
    override func originalString(_ sender: Any!) -> NSAttributedString! {
        return NSAttributedString(string: inputed)
    }
    override func candidates(_ sender: Any!) -> [Any]! {
        return self.matched
    }
    override func candidateSelected(_ candidateString: NSAttributedString!) {
        let client = getClient()
        client.insertText(candidateString.string, replacementRange: client.markedRange())
        updateInput("")
    }
    override func cancelComposition() {
        let client = getClient()
        writeMarkToClient(client, "")
        updateInput("")
    }
    private func isRawMode() -> Bool {
        if manuallyRawMode {
            return true
        }
        if self.inputed.count >= 4 && self.matched.isEmpty {
            return true
        }
        let rawMode = false
        for char in inputed {
            if char.isUppercase {
                return true
            }
        }
        return rawMode
    }
    private func getClient(_ sender: Any? = nil) -> Client {
        guard let downcast = sender as? Client else {
            return client() as! Client
        }
        return downcast
    }
    
    private func writeMarkToClient(_ client: Client, _ string: String, replace: Bool = true) {
        var replacementRange = notFoundRange
        let markedRange = client.markedRange()
        if replace && markedRange.length > 0 {
            replacementRange = markedRange
        }
        client.setMarkedText(string,
                             selectionRange: NSMakeRange(0, string.count),
                             replacementRange: replacementRange)
    }
    override func handle(_ event: NSEvent!, client: Any!) -> Bool {
        switch event.type {
        case .keyDown:
            return handleKeyDown(event, getClient(client))
        case .flagsChanged:
            if event.keyCode == shiftKeyCode && !inputed.isEmpty {
                manuallyRawMode = true
                return handled
            }
            return unhandled
        default:
            return unhandled
        }
    }
    override func updateComposition() {
        candidatesWindow.update()
        if (matched.isEmpty) {
            candidatesWindow.hide()
        } else {
            candidatesWindow.show()
        }
        let client = getClient()
        writeMarkToClient(client, inputed)
    }
    private func submit(_ client: Client, _ submitted: String) {
        client.insertText(submitted, replacementRange: client.markedRange())
        candidatesWindow.hide()
    }

    private func handleKeyDown(_ event: NSEvent, _ client: Client) -> Bool {
        if event.keyCode == escapeKeyCode && !inputed.isEmpty {
            cancelComposition()
            return handled
        }
        if (event.modifierFlags.contains(.command)) {
            return unhandled
        }
        guard let char = event.characters?.first, event.characters?.count == 1 else {
            NSLog("illegal characters: \(event.characters ?? "not found")")
            return unhandled
        }
        switch char {
        case arrowUp, arrowDown, arrowLeft, arrowRight, "1", "2", "3", "4", "5", "6", "7", "8", "9":
            if (candidatesWindow.isVisible()) {
                candidatesWindow.perform(Selector(("handleKeyboardEvent:")), with: event)
                return handled
            } else {
                return unhandled
            }
        case backspaceKey:
            if inputed.isEmpty {
                return unhandled
            }
            updateInput(String(inputed.dropLast()))

            if inputed.isEmpty {
                cancelComposition()
            } else {
                updateComposition()
            }
            return handled
        case " ":
            let matched = self.matched
            if isRawMode() {
                updateInput(inputed + " ")
                updateComposition()
                return handled
            } else if inputed.isEmpty || matched.isEmpty {
                updateInput("")
                return unhandled
            }
            submit(client, matched[0])
            updateInput("")
            return handled
        case enterKey, returnKey:
            if inputed.isEmpty {
                return unhandled
            }
            submit(client, inputed)
            updateInput("")
            return handled
        case ";":
            let matched = self.matched
            if matched.count >= 2 {
                submit(client, matched[1])
                updateInput("")
                return handled
            } else if inputed.isEmpty {
                return unhandled
            } else if matched.isEmpty {
                submit(client, inputed)
                updateInput("")
                return unhandled
            } else {
                submit(client, matched[0])
                updateInput("")
                return unhandled
            }
        case "." where !isRawMode():
            submit(client, "。")
            return handled
        case "," where !isRawMode():
            submit(client, "，")
            return handled
        default:
            let maxCode = 4
            let matched = matched
            if !char.isLetter {
                submit(client, inputed)
                updateInput("")
                return unhandled
            }
            if inputed.count == maxCode && !isRawMode() && !matched.isEmpty {
                submit(client, matched[0])
                updateInput("")
            }
            updateInput(inputed + String(char))
            self.updateComposition()
            return handled
        }
    }
}
