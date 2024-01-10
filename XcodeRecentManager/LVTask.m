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
#import "SCEvents.h"

@interface LVTask ()<SCEventListenerProtocol>
@property (nonatomic, strong) SCEvents *events;
@end
@implementation LVTask {

}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.events = SCEvents.new;
        self.events.delegate = self;
    }
    return self;
}

+ (void)openURLs:(NSArray<NSURL *> *)urls appUrl:(NSURL *)appurl {
    NSWorkspaceOpenConfiguration *config = NSWorkspaceOpenConfiguration.configuration;
    [NSWorkspace.sharedWorkspace openURLs:urls withApplicationAtURL:appurl configuration:config completionHandler:^(NSRunningApplication * _Nullable app, NSError * _Nullable error) {
        NSLog(@"NSRunningApplication:%@", app);
    }];
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
} /* runShell */

+ (NSURL *)selectFolderBtnClicked:(NSString *)documentPath {
    NSOpenPanel *folderSelectionDialog = [NSOpenPanel openPanel];  // a modal dialog
    [folderSelectionDialog setPrompt:@"Select"];
    [folderSelectionDialog setMessage:@"Please select a folder"];

    [folderSelectionDialog setCanChooseFiles:NO];
    [folderSelectionDialog setAllowedFileTypes:@[@"N/A"]];
    [folderSelectionDialog setAllowsOtherFileTypes:NO];

    [folderSelectionDialog setAllowsMultipleSelection:NO];

    [folderSelectionDialog setCanChooseDirectories:YES];
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
} /* selectFolderBtnClicked */

+ (instancetype)sharedInstance {
    static LVTask *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}


+ (BOOL)callMethodInCatalystApp:(NSArray *)paths {
    return [[LVTask sharedInstance].events startWatchingPaths:paths];
}

- (void)pathWatcher:(SCEvents *)pathWatcher eventOccurred:(SCEvent *)event { 
    // 获取 Catalyst App 的主要类
    Class catalystAppClass = NSClassFromString(@"ViewController");
    if (catalystAppClass) {
        // 创建 Catalyst App 类的实例        // 调用方法并获取返回值
        SEL selector = NSSelectorFromString(@"refreshAction22:");
        if ([catalystAppClass respondsToSelector:selector]) {
            NSString *result = [catalystAppClass performSelector:selector withObject:@"hhh"];
            NSLog(@"Result from Catalyst App: %@", result);
        } else {
            NSLog(@"Catalyst App method not found.");
        }
    } else {
        NSLog(@"Catalyst App class not found.");
    }
}

@end
