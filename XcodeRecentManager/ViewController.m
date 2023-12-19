//
//  ViewController.m
//  XcodeRecentManager
//
//  Created by Dacaiguoguo on 2021/7/28.
//

#import "ViewController.h"
#import "SFLListItem.h"
#import "ProjectViewCell.h"

// #if TARGET_OS_MACCATALYST

@interface ViewController () <UITableViewDelegate, UITableViewDataSource> {
    NSString *homePath;
}
@property (nonatomic, copy) NSArray *recentListArray;
@property (nonatomic, copy) NSDictionary *branchInfo;
@property (nonatomic, copy) NSDictionary *iconInfo;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    homePath = NSHomeDirectory();
    self.title = @"Open Recent";

    UINib *nib = [UINib nibWithNibName:@"ProjectViewCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"ProjectViewCell"];
    [self loadData];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage systemImageNamed:@"arrow.clockwise.circle"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(refreshAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.rightBarButtonItem = barButton;
}

- (void)refreshAction:(id)sender {
    [self loadData];
    [self.tableView reloadData];
}

- (void)loadData {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentPath = @"~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments".stringByStandardizingPath;
    NSString *filePath = [documentPath stringByAppendingPathComponent:@"com.apple.dt.xcode.sfl3"];
    
    BOOL isExist = [fileManager fileExistsAtPath:filePath];
    if (!isExist) {
        NSString *filePathold = [documentPath stringByAppendingPathComponent:@"com.apple.dt.xcode.sfl2"];
        BOOL isExistold = [fileManager fileExistsAtPath:filePathold];
        if (!isExistold) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"请设置完全磁盘访问权限" message:nil preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    NSURL *aUrl = [NSURL fileURLWithPath:documentPath];
                    [[UIApplication sharedApplication] openURL:aUrl options:@{} completionHandler:^(BOOL success) {
                        NSLog(@"%@", @(success));
                        NSString *pluginPath = [[NSBundle.mainBundle builtInPlugInsURL] URLByAppendingPathComponent:@"MacTask.bundle"].path;
                        NSBundle *bundle = [NSBundle bundleWithPath:pluginPath];
                        [bundle load];
                        NSFileManager *fileManager = [NSFileManager defaultManager];

                        // Load the principal class from the bundle
                        // This is set in MacTask/Info.plist
                        Class principalClass = bundle.principalClass;
                        SEL selector = NSSelectorFromString(@"runShell:workingDirectory:");
                        NSDictionary *result = [principalClass performSelector:selector withObject:@[@"open", @"-a", @"System Preferences"] withObject:NSHomeDirectory()];
                    }];
                }]];
                [self presentViewController:alert animated:YES completion:nil];
            });
            return;
        }
    }
    NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
    NSError *err = nil;
    NSData *data = [[NSData alloc] initWithContentsOfURL:fileUrl options:(NSDataReadingMappedIfSafe) error:&err];
    if (err || data==nil) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:(err.localizedDescription?:@"no data") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {

            }]];
            [self presentViewController:alert animated:YES completion:nil];
        });
        return;
    }

    self.recentListArray = readSflWithFile(filePath);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //#if TARGET_OS_MACCATALYST
        NSString *pluginPath = [[NSBundle.mainBundle builtInPlugInsURL] URLByAppendingPathComponent:@"MacTask.bundle"].path;
        NSBundle *bundle = [NSBundle bundleWithPath:pluginPath];
        [bundle load];
        NSFileManager *fileManager = [NSFileManager defaultManager];

        // Load the principal class from the bundle
        // This is set in MacTask/Info.plist
        Class principalClass = bundle.principalClass;
        NSURL *workingDir = [NSFileManager defaultManager].temporaryDirectory;
        NSMutableDictionary *branchInfo = [NSMutableDictionary dictionary];
        NSMutableDictionary *iconInfo = [NSMutableDictionary dictionary];

        //#endif
        [self->_recentListArray enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *workPath = obj.stringByDeletingLastPathComponent;
            NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:[NSURL fileURLWithPath:obj.stringByDeletingPathExtension] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
            // /Users/sunyanguo/Developer/newlvmama12/Lvmm/Resource/LvmmImage.xcassets/AppIcon.appiconset
            NSURL *appiconset = nil;
            for (NSURL *fileUrl in enumerator) {
                // NSLog(@"%@", fileUrl);todo:增加深度限制，max-depth
                NSString *aItem = [fileUrl lastPathComponent];
                if ([@"AppIcon.appiconset" isEqualToString:aItem]) {
                    appiconset = fileUrl;
                    break;
                }
            }
            if (appiconset) {
                NSDirectoryEnumerator *enumeratorIcon = [fileManager enumeratorAtURL:appiconset includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
                for (NSURL *fileUrl in enumeratorIcon) {
                    UIImage *image = [UIImage imageWithContentsOfFile:fileUrl.path];
                    if (image.size.width >= 60 && image.size.width <= 160) {
                        iconInfo[obj] = image;
                        break;
                    }
                }
            }

            SEL selector = NSSelectorFromString(@"runShell:workingDirectory:");
            NSDictionary *result = [principalClass performSelector:selector withObject:@[@"git", @"-C", workPath, @"branch", @"-a"] withObject:workingDir];
            NSNumber *code = result[@"code"];
            if (code.intValue == 0) { /// code == 0 命令执行成功
                NSString *output = result[@"output"];
                NSArray *resultArray = [output componentsSeparatedByString:@"\n"];
                for (NSString *item in resultArray) {
                    if ([item hasPrefix:@"*"]) {
                        NSLog(@"%@ %@", code, item);
                        branchInfo[obj] = [item substringFromIndex:1];
                        break;
                    }
                }
            }
        }];
        self.branchInfo = branchInfo;
        self.iconInfo = iconInfo;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
}


#pragma tableView UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.recentListArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"ProjectViewCell";
    ProjectViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    NSString *orgPath = self.recentListArray[indexPath.row];
    NSString *path = [orgPath stringByReplacingOccurrencesOfString:[homePath stringByAppendingString:@"/"] withString:@""];
    cell.pathLabel.text = path;
    NSString *branchName = self.branchInfo[orgPath];
    cell.branchLabel.text = branchName;
    cell.iconImageView.image = self.iconInfo[orgPath]?:[UIImage imageNamed:@"XcodeIcon"];
    cell.iconImageView.layer.cornerRadius = 8;
    return cell;
}

#pragma tableView--UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *orgPath = self.recentListArray[indexPath.row];
    NSURL *aUrl = [NSURL fileURLWithPath:orgPath];
    [[UIApplication sharedApplication] openURL:aUrl options:@{} completionHandler:^(BOOL success) {
        NSLog(@"%@", @(success));
    }];
}

@end
