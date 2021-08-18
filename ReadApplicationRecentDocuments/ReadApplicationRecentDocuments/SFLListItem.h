//
//  SFLListItem.h
//  ReadApplicationRecentDocuments
//
//  Created by dacaiguoguo on 2021/8/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SFLListItem : NSObject <NSSecureCoding>

@property(copy) NSDictionary *properties; // @synthesize properties=_properties;
@property(copy) NSString *name; // @synthesize name=_name;
@property(retain) NSURL *URL; // @synthesize URL=_URL;
@property(copy) NSData *bookmark; // @synthesize bookmark=_bookmark;
@property(retain) NSUUID *uniqueIdentifier; // @synthesize uniqueIdentifier=_uniqueIdentifier;
- (void)encodeWithCoder:(id)arg1;
- (id)initWithCoder:(id)arg1;
//- (BOOL)isEqual:(id)arg1;
//- (unsigned long long)hash;
//- (unsigned long long)_cfTypeID;
//- (void)synthesizeMissingPropertyValues;
//- (id)initWithItem:(id)arg1;
//- (id)initWithName:(id)arg1 bookmarkData:(id)arg2 properties:(id)arg3;
//- (id)initWithName:(id)arg1 URL:(id)arg2 properties:(id)arg3;

@end

NS_ASSUME_NONNULL_END
