//
//  LVTask.m
//  MacTask
//
//  Created by Dacaiguoguo on 2021/7/28.
//
// https://developer.apple.com/documentation/security/app_sandbox/accessing_files_from_the_macos_app_sandbox?language=objc
// https://www.appcoda.com/mac-app-sandbox/
#import "LVTask.h"
#import <AppKit/AppKit.h>
@implementation LVTask {

}
- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

+ (NSDictionary *)runShell:(NSArray<NSString *> *)arguments workingDirectory:(NSURL *)workingDir {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/env";

    [task setCurrentDirectoryPath:workingDir.path];

    NSPipe *output = [NSPipe pipe];
    [task setStandardOutput:output];

    task.arguments = arguments;
    [task launch];
    [task waitUntilExit];

    NSFileHandle *read = [output fileHandleForReading];
    NSData *dataRead = [read readDataToEndOfFile];
    NSString *stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];

    return @{
        @"output": stringRead,
        @"code": @(task.terminationStatus)
    };
}

+ (NSURL *)selectopenDeveloperFolderBtnClicked:(id)sender {
    NSOpenPanel *folderSelectionDialog = [NSOpenPanel openPanel]; // a modal dialog
    
    [folderSelectionDialog setPrompt:@"Select"];
    [folderSelectionDialog setMessage:@"Please select a folder"];
    
    [folderSelectionDialog setCanChooseFiles:NO];
    [folderSelectionDialog setAllowedFileTypes:@[@"N/A"]];
    [folderSelectionDialog setAllowsOtherFileTypes:NO];
    
    [folderSelectionDialog setAllowsMultipleSelection:NO];
    
    [folderSelectionDialog setCanChooseDirectories:YES];
    NSString *documentPath = @"~/Developer".stringByStandardizingPath;
    // Set default directory URL
       NSURL *defaultDirectoryURL = [NSURL fileURLWithPath:documentPath];
       [folderSelectionDialog setDirectoryURL:defaultDirectoryURL];
    // open the MODAL folder selection panel/dialog
    NSInteger dialogButtonPressed = [folderSelectionDialog runModal];
    
    // if the user pressed the "Select" (affirmative or "OK")
    // button, then they've probably chosen a folder
    if (dialogButtonPressed == NSModalResponseOK) {
        
        if ([[folderSelectionDialog URLs] count] == 1) {
            
            NSURL *url = [[folderSelectionDialog URLs] firstObject];
            
            // if the user doesn't select anything, then
            // the URL "file:///" is returned, which we ignore
            if (![[url absoluteString] isEqualToString:@"file:///"]) {
                
                // save the user's selection so that we can
                // access the folder they specified (in Part II)
                
                NSLog(@"User selected folder: %@", url);
                return url;
            } else {
                NSLog(@"User did not select a folder: file:///");
            }
            
        } else {
            
            NSLog(@"User did not select a folder");
            
        }
        
    } else { // user clicked on "Cancel"
        
        NSLog(@"User cancelled folder selection panel");
        
    }
    return nil;
}


+ (NSURL *)selectFolderBtnClicked:(id)sender {
    NSOpenPanel *folderSelectionDialog = [NSOpenPanel openPanel]; // a modal dialog
    
    [folderSelectionDialog setPrompt:@"Select"];
    [folderSelectionDialog setMessage:@"Please select a folder"];
    
    [folderSelectionDialog setCanChooseFiles:NO];
    [folderSelectionDialog setAllowedFileTypes:@[@"N/A"]];
    [folderSelectionDialog setAllowsOtherFileTypes:NO];
    
    [folderSelectionDialog setAllowsMultipleSelection:NO];
    
    [folderSelectionDialog setCanChooseDirectories:YES];
    NSString *documentPath = @"~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments".stringByStandardizingPath;
    // Set default directory URL
       NSURL *defaultDirectoryURL = [NSURL fileURLWithPath:documentPath];
       [folderSelectionDialog setDirectoryURL:defaultDirectoryURL];
    // open the MODAL folder selection panel/dialog
    NSInteger dialogButtonPressed = [folderSelectionDialog runModal];
    
    // if the user pressed the "Select" (affirmative or "OK")
    // button, then they've probably chosen a folder
    if (dialogButtonPressed == NSModalResponseOK) {
        
        if ([[folderSelectionDialog URLs] count] == 1) {
            
            NSURL *url = [[folderSelectionDialog URLs] firstObject];
            
            // if the user doesn't select anything, then
            // the URL "file:///" is returned, which we ignore
            if (![[url absoluteString] isEqualToString:@"file:///"]) {
                
                // save the user's selection so that we can
                // access the folder they specified (in Part II)
                
                NSLog(@"User selected folder: %@", url);
                return url;
            } else {
                NSLog(@"User did not select a folder: file:///");
            }
            
        } else {
            
            NSLog(@"User did not select a folder");
            
        }
        
    } else { // user clicked on "Cancel"
        
        NSLog(@"User cancelled folder selection panel");
        
    }
    return nil;
}


@end
