//
//  main.m
//  ReadApplicationRecentDocuments
//
//  Created by dacaiguoguo on 2021/8/18.
//

#import <Foundation/Foundation.h>
#import "SFLListItem.h"

// com.apple.finder.sfl 需要测试
NSArray* readSflWithFile(NSString *filePath) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:filePath];
    if (!isExist) {
        return nil;
    }
    NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
    NSError *err = nil;
    NSData *data = [[NSData alloc] initWithContentsOfURL:fileUrl options:(NSDataReadingMappedIfSafe) error:&err];
    if (err || data == nil) {
        NSLog(@"%@",err.localizedDescription);
        return nil;
    }
    NSDictionary *recentListInfo = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:&err];
    NSArray *recentList = recentListInfo[@"items"];

    NSMutableArray *mutArray = [NSMutableArray array];
    if ([recentList.firstObject isKindOfClass:NSDictionary.class]) {
        [recentList enumerateObjectsUsingBlock:^(NSDictionary *bookmarkInfo, NSUInteger idx, BOOL * _Nonnull stop) {
            NSData *bookmark = bookmarkInfo[@"Bookmark"];
            NSError *resolveError = nil;
            NSURL *resolvedUrl = [NSURL URLByResolvingBookmarkData:bookmark options:(NSURLBookmarkResolutionWithoutUI) relativeToURL:nil bookmarkDataIsStale:nil error:&resolveError];
            if (resolvedUrl == nil) {
                // NSLog(@"%@",@"null");
                return;
            }
            // NSLog(@"%@",resolvedUrl.path);
            [mutArray addObject:resolvedUrl.path];

        }];
    } else if ([recentList.firstObject isKindOfClass:SFLListItem.class]) {
        [recentList enumerateObjectsUsingBlock:^(SFLListItem *bookmarkInfo, NSUInteger idx, BOOL * _Nonnull stop) {
            NSURL *resolvedUrl = bookmarkInfo.URL;
            if (resolvedUrl == nil) {
                // NSLog(@"%@",@"null");
                return;
            }
            // NSLog(@"%@",resolvedUrl.path);
            [mutArray addObject:resolvedUrl.path];

        }];
    }


    // NSLog(@"%@", mutArray);
    return mutArray.copy;;
}

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
             NSLog(@"%@",item);
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
