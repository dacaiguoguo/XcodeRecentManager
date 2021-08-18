//
//  SFLListItem.m
//  ReadApplicationRecentDocuments
//
//  Created by dacaiguoguo on 2021/8/18.
//

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

@implementation SFLListItem
+ (BOOL)supportsSecureCoding {
    return YES;
}
- (void)encodeWithCoder:(id)arg1 {

}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    _name = [decoder decodeObjectOfClass:[NSString class] forKey:@"name"];
    _URL = [decoder decodeObjectOfClass:[NSURL class] forKey:@"URL"];
    _bookmark = [decoder decodeObjectOfClass:[NSData class] forKey:@"bookmark"];
    _uniqueIdentifier = [decoder decodeObjectOfClass:[NSUUID class] forKey:@"uniqueIdentifier"];
    return self;
}

@end
