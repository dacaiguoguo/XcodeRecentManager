//
//  ProjectViewCell.m
//  XcodeRecentManager
//
//  Created by Dacaiguoguo on 2022/1/27.
//

#import "ProjectViewCell.h"

@implementation ProjectViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (IBAction)fangda:(UIButton *)sender {
    NSString *pluginPath = [[NSBundle.mainBundle builtInPlugInsURL] URLByAppendingPathComponent:@"SwiftTool.bundle"].path;
    NSBundle *bundle = [NSBundle bundleWithPath:pluginPath];

    [bundle load];
    Class principalClass = bundle.principalClass;
    SEL selector = NSSelectorFromString(@"runShell:workingDirectory:");
    __unused NSDictionary *result = [principalClass performSelector:selector withObject:@[@"open", self.path.stringByDeletingLastPathComponent, @"-a", @"Finder"] withObject:NSHomeDirectory()];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
