//
//  LVTask.h
//  MacTask
//
//  Created by Dacaiguoguo on 2021/7/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LVTask : NSObject
+ (NSDictionary *)runShell:(NSArray<NSString *> *)arguments workingDirectory:(NSURL *)workingDir;
@end

NS_ASSUME_NONNULL_END
