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


class TsuruInputController: IMKInputController {
    private var inputed: String = "" // what the user typed
    private var selected: String = ""
    private var matched: [String] = [] // list of candidates to choose from

    override func deactivateServer(_ sender: Any!) {
        let client = getClient()
        if !inputed.isEmpty {
            client.insertText(inputed, replacementRange: notFoundRange)
        } else {
            writeMarkToClient(client, "")
        }
        self.matched = []
        self.inputed = ""
        candidatesWindow.hide()
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
        self.matched = []
        self.inputed = ""
        candidatesWindow.hide()
    }
    override func cancelComposition() {
        let client = getClient()
        writeMarkToClient(client, "")
        self.matched = []
        self.inputed = ""
        candidatesWindow.hide()
    }
    private func isRawMode() -> Bool {
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
    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        switch event.type {
            case .keyDown: return handleKeyDown(event, getClient(sender))
            default: return unhandled
        }
    }
    override func updateComposition() {
        let matched = codeTable[inputed] ?? []
        NSLog("inputed string: \(inputed) matched: \(matched.joined(separator: ", "))")
        if (matched.count > 0) {
            self.matched = matched
            candidatesWindow.update()
            candidatesWindow.show()
        } else {
            candidatesWindow.hide()
        }
        let client = getClient()
        writeMarkToClient(client, inputed)
    }
    private func submit(_ client: Client, _ submitted: String) {
        NSLog("submitted: \(submitted)")
        client.insertText(submitted, replacementRange: client.markedRange())
        candidatesWindow.hide()
        self.inputed = ""
        self.matched = []
    }

    private func handleKeyDown(_ event: NSEvent, _ client: Client) -> Bool {
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
            self.inputed = String(inputed.dropLast())

            if inputed.isEmpty {
                self.cancelComposition()
            } else {
                self.updateComposition()
            }
            return handled
        case " ":
            if inputed.isEmpty || matched.isEmpty || isRawMode() {
                inputed = ""
                matched = []
                return unhandled
            }
            submit(client, matched[0])
            return handled
        case enterKey, returnKey:
            if inputed.isEmpty {
                return unhandled
            }
            submit(client, inputed)
            return handled
        case ";":
            if inputed.isEmpty && self.matched.count < 2 {
                return unhandled
            }
            submit(client, matched[1])
            return handled
        case ".":
            submit(client, "。")
            return handled
        case ",":
            submit(client, "，")
            return handled
        default:
            let maxCode = 4
            if !char.isLetter {
                submit(client, inputed)
                return unhandled
            }
            
            if inputed.count == maxCode && !isRawMode() {
                if matched.isEmpty {
                    submit(client, inputed)
                } else {
                    submit(client, matched[0])
                }
            }
            self.inputed = inputed + String(char)
            self.updateComposition()
            return handled
        }
    }
}
