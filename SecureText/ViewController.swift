//
//  ViewController.swift
//  SecureText
//
//  Created by RnD on 6/3/20.
//  Copyright © 2020 RnD. All rights reserved.
//

import UIKit
import LocalAuthentication

class ViewController: UIViewController {

    @IBOutlet weak var secretTextView: UITextView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNotifications()
        
        title = "Welcome to SecureText"
        
        // Initial state of button
        doneButton.tintColor = .clear
    }

    func setupNotifications() {
        // Notify when the keyboard hides or changes
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplication.willResignActiveNotification, object: nil)
    }

    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            // Hardware keyboards
            secretTextView.contentInset = .zero
        } else {
            secretTextView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        secretTextView.scrollIndicatorInsets = secretTextView.contentInset
        
        let selectedRange = secretTextView.selectedRange
        secretTextView.scrollRangeToVisible(selectedRange)
    }
    
    // MARK: - Actions
    
    @IBAction func authenticateTapped(_ sender: Any) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate to unlock editor.") { [weak self] success, authenticationError in
                
                DispatchQueue.main.async {
                    if success {
                        self?.unlockSecretMessage()
                        
                        self?.doneButton.tintColor = .systemBlue
                    } else {
                        let alertController = UIAlertController(title: "Authentication failed", message: "Please try again", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(alertController, animated: true)
                    }
                }
            }
        } else {
            let alertController = UIAlertController(title: "Biometrics unavailable", message: "Your device is not configured for biometric authentication", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            present(alertController, animated: true)
        }
    }
    
    @IBAction func doneTapped(_ sender: Any) {
        secretTextView.isHidden = false
        saveSecretMessage()
    }
    
    func unlockSecretMessage() {
        secretTextView.isHidden = false
        
        let customSymbol = UIImage(systemName: "lock.open.fill")
        let imageView = UIImageView(image: customSymbol)
        imageView.tintColor = .label
        navigationItem.titleView = imageView
        
        if let text = KeychainWrapper.standard.string(forKey: "SecretMessage") {
            secretTextView.text = text
        }
    }
    
    @objc func saveSecretMessage() {
        // Proceed only if text view is visible
        guard secretTextView.isHidden == false else { return }
        
        KeychainWrapper.standard.set(secretTextView.text, forKey: "SecretMessage")
        secretTextView.resignFirstResponder()
        secretTextView.isHidden = true
        
        navigationItem.titleView = nil
        title = "Locked"
        
        doneButton.tintColor = .clear
    }
}

