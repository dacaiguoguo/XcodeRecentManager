//
//  SFLListItem.m
//  ReadApplicationRecentDocuments
//
//  Created by dacaiguoguo on 2021/8/18.
//

#import "SFLListItem.h"
NSArray* readSflWithFile(NSString *filePath) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath]) {
        return nil;
    }
    
    NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
    NSError *err = nil;
    NSData *data = [NSData dataWithContentsOfURL:fileUrl options:NSDataReadingMappedIfSafe error:&err];
    
    if (err || data == nil) {
        NSLog(@"%@", err.localizedDescription);
        return nil;
    }
    return readSflWithData(data);
}

NSArray* readSflWithData(NSData *data) {
    NSError *err = nil;

    if (data == nil) {
        return nil;
    }
    
    NSArray *recentList;
    @try {
        NSDictionary *recentListInfo = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:&err];
        recentList = recentListInfo[@"items"];
    } @catch (NSException *exception) {
        NSLog(@"Exception during unarchiving: %@", exception);
        return nil;
    }
    
    if (!recentList) {
        return nil;
    }

    NSMutableArray *mutArray = [NSMutableArray array];
    
    for (id item in recentList) {
        NSURL *resolvedUrl;
        
        if ([item isKindOfClass:NSDictionary.class]) {
            NSData *bookmark = item[@"Bookmark"];
            NSError *resolveError = nil;
            resolvedUrl = [NSURL URLByResolvingBookmarkData:bookmark options:NSURLBookmarkResolutionWithoutUI relativeToURL:nil bookmarkDataIsStale:nil error:&resolveError];
        } else if ([item isKindOfClass:SFLListItem.class]) {
            resolvedUrl = ((SFLListItem *)item).URL;
        }

        if (resolvedUrl) {
            [mutArray addObject:resolvedUrl.path];
        }
    }

    return mutArray.copy;
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
