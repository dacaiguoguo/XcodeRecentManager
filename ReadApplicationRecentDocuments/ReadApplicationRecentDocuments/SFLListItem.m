//
//  SFLListItem.m
//  ReadApplicationRecentDocuments
//
//  Created by dacaiguoguo on 2021/8/18.
//

#import "SFLListItem.h"

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
