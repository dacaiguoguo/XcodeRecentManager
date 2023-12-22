//
//  ProjectViewCell.h
//  XcodeRecentManager
//
//  Created by Dacaiguoguo on 2022/1/27.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProjectViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *pathLabel;
@property (strong, nonatomic) IBOutlet UILabel *branchLabel;
@property (strong, nonatomic) IBOutlet UIImageView *iconImageView;
@property (strong, nonatomic) NSString *path;

@end

NS_ASSUME_NONNULL_END
