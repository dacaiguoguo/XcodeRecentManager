//
//  LVTask.m
//  MacTask
//
//  Created by Dacaiguoguo on 2021/7/28.
//

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
@end
