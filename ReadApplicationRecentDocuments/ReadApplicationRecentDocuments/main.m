//
//  main.m
//  ReadApplicationRecentDocuments
//
//  Created by dacaiguoguo on 2021/8/18.
//

#import <Foundation/Foundation.h>
#import "SFLListItem.h"


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *recentDir = @"~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/".stringByStandardizingPath;
        NSDirectoryEnumerator<NSString *> *enumrator = [fileManager enumeratorAtPath:recentDir];
        NSMutableArray *mutArray = [NSMutableArray array];
        for (NSString *item in enumrator) {
//            if (![@"com.apple.console.sfl" isEqualToString:item]) {//测试 SFLListItem 支持
//                continue;
//            }
             //NSLog(@"%@",item);
            NSArray* result = readSflWithFile([recentDir stringByAppendingPathComponent:item]);
            if (result) {
                [mutArray addObject:@{@"name": item, @"value": result}];
            }
        }
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:mutArray options:NSJSONWritingPrettyPrinted error:nil];
        if (jsonData.length == 0) {
            printf("");
            return 0;
        }
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"%@", jsonString);
    }
    return 0;
}
