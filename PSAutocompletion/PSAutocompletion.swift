//
//  PSAutocompletion.swift
//  PSAutocompletion
//
//  Created by Pavel Stasyuk on 14/01/2017.
//  Copyright © 2017 Pavel Stasyuk. All rights reserved.
//

import UIKit

protocol PSAutocompletionDataSource: class {
    func autocompletion(_ completion: PSAutocompletion, completedForUserText userText:String) -> String?
}


protocol PSAutocompletionDelegate: class {
    func autocompletion(_ completion: PSAutocompletion, didChangeText text: String?)
    func autocompletion(_ completion: PSAutocompletion, willCompleteWithUserText: String, completedText: String)
    func autocompletion(_ completion: PSAutocompletion, didCompleteWithUserText: String, completedText: String)
}


extension PSAutocompletionDelegate {
    
    func autocompletion(_ completion: PSAutocompletion, willCompleteWithUserText: String, completedText: String) {
        
    }
    
    func autocompletion(_ completion: PSAutocompletion, didCompleteWithUserText: String, completedText: String) {
        
    }
}


class PSAutocompletion: NSObject, UIGestureRecognizerDelegate {
    
    var autocompleted: Bool {
        get {
            let result = textField.markedTextRange != nil && isSupportedInputLanguage()
            return result
        }
    }
    
    var notCompletedText: String? {
        didSet(oldValue) {
            if oldValue != notCompletedText {
                self.delegate?.autocompletion(self, didChangeText: notCompletedText)
            }
        }
    }
    
    weak var dataSource: PSAutocompletionDataSource?
    weak var delegate: PSAutocompletionDelegate?
    
    private var textField: UITextField
    private var lastAutocompletionResult: (String, String)?
    private var isTextChangedInternally: Bool = false
    
    init(textField: UITextField) {
        
        self.textField = textField
        
        super.init()
        
        assert(textField.autocorrectionType == .no, "textField autocorrectionType must be .no")
        assert(textField.spellCheckingType == .no, "textField spellCheckingType must be .no")
        
        textField.addTarget(self, action: #selector(processInput(_:)), for: .editingChanged)

        let tapGesture = UITapGestureRecognizer.init(target: nil, action: nil)
        tapGesture.delegate = self
        textField.addGestureRecognizer(tapGesture)
        textField.addObserver(self, forKeyPath: #keyPath(UITextField.text), options: [.old, .new], context: nil)
    }
    
    deinit {
        textField.removeObserver(self, forKeyPath: #keyPath(UITextField.text))
        textField.removeTarget(self, action: #selector(processInput(_:)), for: .editingChanged)
    }
    
// MARK: Processing Input
    
    @objc func processInput(_ sender: UITextField) {
        let time = DispatchTime.now() + 0.05
        DispatchQueue.main.asyncAfter(deadline: time) {
            self.processInputDelayed(sender)
        }
    }
    
    // Delayed processing due to setMarkedText(_,selectedRange:) is unable to set marked text in UIControllEventEditingChanged handler
    func processInputDelayed(_ sender: UITextField) {
        var currentText:String?
        var endingText:String?
        
        if let markedTextRange = textField.markedTextRange {
            if let notMarkedTextRange = textField.textRange(from: textField.beginningOfDocument, to: markedTextRange.start) {
                currentText = textField.text(in: notMarkedTextRange)
                endingText = textField.text(in: markedTextRange)
            }
        }
        else {
            currentText = textField.text
        }
        
        let selectedTextRange = textField.selectedTextRange!
        let isCursorAtLastPosition = (selectedTextRange.start == textField.endOfDocument) && selectedTextRange.isEmpty;
        
        if isCursorAtLastPosition && shouldCompleteText() {
            
            let notCompletedText = self.notCompletedText ?? ""
            let currentText = currentText ?? ""
            
            let isSameText = notCompletedText == currentText
            
            let rangeOfString = notCompletedText.range(of: currentText) ?? notCompletedText.startIndex ..< notCompletedText.startIndex
            
            let backspaceInput = !notCompletedText.isEmpty && rangeOfString.lowerBound == notCompletedText.startIndex && !rangeOfString.isEmpty
            
            if (!isSameText && !backspaceInput) {
                performAutocompletion(text: currentText)
            }
            
            if let (userTypedResult, endingResult) = lastAutocompletionResult,
                let endingText = endingText {
                
                let isCorrect = (userTypedResult == currentText) && (endingResult == endingText)
                
                if !endingText.isEmpty && !isCorrect {
                    textField.text = currentText
                }
            }
            
            /**
             * @warning The text is completed with repeated capital letter after backspacing autocompleted part
             */
            let isEmptyEnding = (endingText ?? "").isEmpty
            if backspaceInput && currentText.characters.count == 1 && isEmptyEnding {
                
                self.isTextChangedInternally = true
                self.textField.text = "";
                self.textField.text = currentText;
                self.isTextChangedInternally = false
            }
            /**/

        }
        
        notCompletedText = currentText
    }
    
// MARK: KVO
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard object as! UITextField == textField && keyPath == #keyPath(UITextField.text) else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        guard let new = change?[.newKey] as? String else {
            return
        }
        
        let old = change?[.oldKey] as? String
        
        if (old != new && !isTextChangedInternally) {
            notCompletedText = new
        }
    }
    
// MARK: <UIGestureRecognizerDelegate>
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        textField.unmarkText()
        lastAutocompletionResult = nil
        return true
    }
    
// MARK: Other
    
    
    func performAutocompletion(text: String) {
        
        let completionResult = resultFor(userText: text)
        
        guard let (_, markedText) = completionResult else {
            return
        }
        
        if !markedText.isEmpty {
            notifyWillCompeteWith(result: completionResult)
            isTextChangedInternally = true
            textField.setMarkedText(markedText, selectedRange: NSRange.init(location: markedText.characters.count, length: 0))
            isTextChangedInternally = false
            notifyDidCompeteWith(result: completionResult)
        }
        
        defer {
            lastAutocompletionResult = completionResult
        }
    }

    func resultFor(userText: String) -> (String, String)? {
        
        guard !userText.isEmpty else {
            return nil
        }
        
        guard let completed = dataSource?.autocompletion(self, completedForUserText: userText) else {
            return nil
        }
        
        guard !completed.isEmpty else {
            return nil
        }
        
        let range = completed.range(of: userText, options: [.caseInsensitive, .diacriticInsensitive], range: nil, locale: nil)
        assert(range != nil, "Wrong completion string")
        
        let ending = completed.substring(from: range!.upperBound)
        return (userText, ending)
    }
    
    func shouldCompleteText() -> Bool {
        var result = true
        
        result = result && isSupportedInputLanguage()
        result = result && isSupportedInputMode()
        
        return result
    }
    
    func isSupportedInputLanguage() -> Bool {
        
        // These input languages are known to be uncompatible with this feature
        let unsupportedInputLanguages = [ "ko", "ja", "cs", "zh", "sk" ]
        
        guard let language = textField.textInputMode?.primaryLanguage else {
            return false
        }
        
        let lang = language.substring(to: language.index(language.startIndex, offsetBy: 2))
        let result = !unsupportedInputLanguages.contains(lang)
        
        return result
    }
    
    func isSupportedInputMode() -> Bool {
        // Dictation input is incorrent while trying to complete several words. Disabling autocompletion if text is entered with voice
        let result = textField.textInputMode?.primaryLanguage != "dictation"
        return result
    }
    
    func notifyWillCompeteWith(result: (String, String)?) {
        if let (userText, completedText) = result {
            delegate?.autocompletion(self, willCompleteWithUserText: userText, completedText: completedText)
        }
    }
    
    func notifyDidCompeteWith(result: (String, String)?) {
        if let (userText, completedText) = result {
            delegate?.autocompletion(self, didCompleteWithUserText: userText, completedText: completedText)
        }
    }
}
