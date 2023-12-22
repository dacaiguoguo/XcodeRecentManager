//
//  LVTaskSwift.swift
//  MacTask
//
//  Created by yanguo sun on 2023/12/22.
//

import Foundation
import AppKit

@objc class LVTaskSwift: NSObject {

    @objc static func runShell(arguments: [String], workingDirectory: URL) -> [String: Any] {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        
        task.currentDirectoryPath = workingDirectory.path
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        task.arguments = arguments
        task.launch()
        task.waitUntilExit()
        
        let readHandle = outputPipe.fileHandleForReading
        let dataRead = readHandle.readDataToEndOfFile()
        let stringRead = String(data: dataRead, encoding: .utf8) ?? ""
        
        return [
            "output": stringRead,
            "code": NSNumber(value: task.terminationStatus)
        ]
    }
    
    @objc static func selectFolderBtnClicked(sender: String) -> URL? {
        let folderSelectionDialog = NSOpenPanel()
        
        folderSelectionDialog.prompt = "Select"
        folderSelectionDialog.message = "Please select a folder"
        
        folderSelectionDialog.canChooseFiles = false
        folderSelectionDialog.allowedFileTypes = ["N/A"]
        folderSelectionDialog.allowsOtherFileTypes = false
        
        folderSelectionDialog.allowsMultipleSelection = false
//        let documentPath = NSString(string: "~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments").expandingTildeInPath
//        // Set default directory URL
        let defaultDirectoryURL = URL(fileURLWithPath: sender)
        folderSelectionDialog.directoryURL = defaultDirectoryURL
        
        // Open the MODAL folder selection panel/dialog
        let dialogButtonPressed = folderSelectionDialog.runModal()
        
        // If the user pressed the "Select" (affirmative or "OK") button,
        // then they've probably chosen a folder
        if dialogButtonPressed == .OK {
            
            if let url = folderSelectionDialog.urls.first {
                
                // If the user doesn't select anything, then
                // the URL "file:///" is returned, which we ignore
                if url.absoluteString != "file:///" {
                    // Save the user's selection so that we can
                    // access the folder they specified (in Part II)
                    print("User selected folder: \(url)")
                    return url
                } else {
                    print("User did not select a folder: file:///")
                }
                
            } else {
                print("User did not select a folder")
            }
            
        } else { // User clicked on "Cancel"
            
            print("User cancelled folder selection panel")
            
        }
        return nil
    }
}
