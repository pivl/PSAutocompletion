//
//  ViewController.swift
//  PSAutocompletion
//
//  Created by Pavel Stasyuk on 14/01/2017.
//  Copyright © 2017 Pavel Stasyuk. All rights reserved.
//

import UIKit

class ViewController: UIViewController, PSAutocompletionDelegate, PSAutocompletionDataSource {

    @IBOutlet weak var mainTextField: UITextField!
    var autocompletion: PSAutocompletion!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainTextField.autocorrectionType = .no
        mainTextField.spellCheckingType = .no

        autocompletion = PSAutocompletion.init(textField: mainTextField)
        autocompletion.delegate = self
        autocompletion.dataSource = self
    }
    
    // MARK: Delegate
    
    func autocompletion(_ _: PSAutocompletion, didChangeText text: String?) {
        print("current text is: \(text)")
    }
    
    func autocompletion(_ completion: PSAutocompletion, didCompleteWithUserText: String, completedText: String) {
        print("did complete: \(completedText)")
    }
    
    // MARK: Data Source
    
    func autocompletion(_ _: PSAutocompletion, completedForUserText userText: String) -> String? {
        
        let texts = [
            "Apples",
            "Candies",
            "Anananas",
            "Grapefruit",
            "Bananas",
            "Lemons"
        ]
        let filtered = texts.filter { $0.hasPrefix(userText) }
        
        return filtered.first
    }

}
