
import Foundation
import UIKit
import SwiftSH
import SwiftUI

class ShellViewController: UIViewController, SSHViewController {
    
    @IBOutlet var textView: UITextView!
    
    var shell: SSHShell!
    var authenticationChallenge: AuthenticationChallenge?
    var semaphore: DispatchSemaphore!
    var lastCommand = ""
    
    var requiresAuthentication = false
    var hostname: String!
    var port: UInt16?
    var username: String!
    var password: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.textView.text = ""
        self.textView.isEditable = false
        self.textView.isSelectable = false
        
        if self.requiresAuthentication {
            if let password = self.password {
                self.authenticationChallenge = .byPassword(username: self.username, password: password)
            } else {
                self.authenticationChallenge = .byKeyboardInteractive(username: self.username) { [unowned self] challenge in
                    DispatchQueue.main.async {
                        self.appendToTextView(challenge)
                        self.textView.isEditable = true
                    }
                    
                    self.semaphore = DispatchSemaphore(value: 0)
                    _ = self.semaphore.wait(timeout: DispatchTime.distantFuture)
                    self.semaphore = nil
                    
                    return self.password ?? ""
                }
            }
        } else {
//            let key = """
//-----BEGIN OPENSSH PRIVATE KEY-----b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAlwAAAAdzc2gtcnNhAAAAAwEAAQAAAIEAq/+kSEsucQMxGGGeS23kmqnofy5dTFp4aoVhV7CBX8ePDbcyJyzw//DERs4TqNkM60ofnb+e+fAyM9gDaqutIisjbar3nSBiPNRPQwAGsLgrJkShUlGNQ1xmgLGenxnsg5H576J6AvVhSOFIoYO7T9yhUuxfa9Za2D+/2EUTahEAAAIg0m+KcdJvinEAAAAHc3NoLXJzYQAAAIEAq/+kSEsucQMxGGGeS23kmqnofy5dTFp4aoVhV7CBX8ePDbcyJyzw//DERs4TqNkM60ofnb+e+fAyM9gDaqutIisjbar3nSBiPNRPQwAGsLgrJkShUlGNQ1xmgLGenxnsg5H576J6AvVhSOFIoYO7T9yhUuxfa9Za2D+/2EUTahEAAAADAQABAAAAgQCePGliTTBjrkELojtkP6yyEaCg6QHSjeT8css0RmEvwcM9Jg4Q9oqdnF6mmU6C53S4PpBJq5HRdYZqJdA24cw8Abt5VM0P4PvWI7CwrZJzwAMV0SG4EWcNdaROqXbDmyVuS6juvHrfF1Pkwd11ZUFLLL0lBItH5Ti8+yYeuSJbQQAAAEEAzwqjJt1Qux+3oRVnAfW6Ig2sn4EDV52hDjhK+C9Mt4ZBNo/EDas4jfRrt9VcrrizlinIRthXC8L54+cL307f9QAAAEEA2g4iL/z1NJGQuE0ReJC3NU9ggAtbbRrHvO3yA433+9OSzSW0uVc6E01009/7AzcuddL5GOdPQkOdlN/dv2A8KQAAAEEAye3KWQF41nsDq8j5Rg9olkezW0wRPxFPouk/UfgOSjQ6LBJ4NRwpsZsf5gOc8yudG0/g2i5EzWQih6My2QR7qQAAACVqYWtlc2lsdmlhQE1hY0Jvb2stUHJvLTMuYWRkaWd5LW1hbmdvAQIDBA== -----END OPENSSH PRIVATE KEY-----
//""".data(using: .utf16)
//                        let pubkey = """
//            ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQCr/6RISy5xAzEYYZ5LbeSaqeh/Ll1MWnhqhWFXsIFfx48NtzInLPD/8MRGzhOo2QzrSh+dv5758DIz2ANqq60iKyNtqvedIGI81E9DAAawuCsmRKFSUY1DXGaAsZ6fGeyDkfnvonoC9WFI4Uihg7tP3KFS7F9r1lrYP7/YRRNqEQ== jakesilvia@MacBook-Pro-3.addigy-mango
//            """.data(using: .utf16)
//
//            self.authenticationChallenge = .byPublicKeyFromMemory(username: self.username, password: "Stinker00", publicKey: pubkey, privateKey: key!)
//            print("Starting...")
//            self.authenticationChallenge = .byPublicKeyFromFile(username: self.username, password: "", publicKey: "testest", privateKey: "/Users/jakesilvia/.ssh/id_rsa")
        }
        
        self.shell = try? SSHShell(host: self.hostname, port: self.port ?? 22, terminal: "vanilla")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.connect()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.disconnect()
    }
    
    @IBAction func connect() {
        self.shell
            .withCallback { [unowned self] (string: String?, error: String?) in
                DispatchQueue.main.async {
                    if let string = string {
                        self.appendToTextView(string)
                    }
                    if let error = error {
                        self.appendToTextView("[ERROR] \(error)")
                    }
                }
            }
            .connect()
            .authenticate(self.authenticationChallenge)
            .open { [unowned self] (error) in
                if let error = error {
                    self.appendToTextView("[ERROR] \(error)")
                    self.textView.isEditable = false
                } else {
                    self.textView.isEditable = true
                }                
            }
    }
    
    @IBAction func disconnect() {
        self.shell?.disconnect { [unowned self] in
            self.textView.isEditable = false
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func appendToTextView(_ text: String) {
        self.textView.text = "\(self.textView.text!)\(text)"
        self.textView.scrollRangeToVisible(NSRange(location: self.textView.text.utf8.count - 1, length: 1))
    }
    
    func performCommand() {
        if let semaphore = self.semaphore {
            self.password = self.lastCommand.trimmingCharacters(in: .newlines)
            semaphore.signal()
        } else {
            print("Last command is '\(self.lastCommand)'")
            self.shell.write(self.lastCommand) { [unowned self] (error) in
                if let error = error {
                    self.appendToTextView("[ERROR] \(error)")
                }
            }
        }
        
        self.lastCommand = ""
    }
    
}

extension ShellViewController: UITextViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.textView.resignFirstResponder()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard !text.isEmpty else {
            guard !self.lastCommand.isEmpty else {
                return false
            }
            
            let endIndex = self.lastCommand.endIndex
            self.lastCommand.removeSubrange(self.lastCommand.index(before: endIndex)..<endIndex)
            
            return true
        }
        
        self.lastCommand.append(text)
        
        if text == "\n" {
            self.performCommand()
        }
        
        return true
    }
    
}
