//
//  ViewController.m
//  XcodeRecentManager
//
//  Created by Dacaiguoguo on 2021/7/28.
//

#import "ViewController.h"
#import "SFLListItem.h"
#import "ProjectViewCell.h"
static NSString * const kApplicationRecentDocumentsKey = @"ApplicationRecentDocuments";
static NSString * const kXcodeSFLFileName = @"com.apple.dt.xcode.sfl3";

#import <Foundation/Foundation.h>

NSString *findGitFolder(NSString *currentPath, NSInteger maxDepth, NSInteger currentDepth) {
    while (![currentPath isEqualToString:@"/"] && currentDepth <= maxDepth) {
        NSString *gitFolderPath = [currentPath stringByAppendingPathComponent:@".git"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:gitFolderPath isDirectory:NULL]) {
            return gitFolderPath;
        } else {
            currentPath = [currentPath stringByDeletingLastPathComponent];
            currentDepth++;
        }
    }
    
    return nil;
}

NSString *readHEADContents(NSString *gitFolderPath) {
    NSString *headPath = [gitFolderPath stringByAppendingPathComponent:@"HEAD"];
    
    NSError *error;
    NSString *headContents = [NSString stringWithContentsOfFile:headPath
                                                       encoding:NSUTF8StringEncoding
                                                          error:&error];
    
    if (error) {
        NSLog(@"Error reading HEAD file: %@", error.localizedDescription);
        return nil;
    }
    
    return headContents;
}

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
    self.tableView.backgroundColor = UIColor.clearColor;
    // Remove unnecessary user defaults
    // [NSUserDefaults.standardUserDefaults removeObjectForKey:@"Developer"];
    // [NSUserDefaults.standardUserDefaults removeObjectForKey:@"ApplicationRecentDocuments"];
    
    NSString *username = NSUserName();
    
    homePath = [NSString stringWithFormat:@"/Users/%@", username];
    // Check and access the security-scoped resource for the developer folder
    NSURL *developerURL = [self resolveBookmarkDataOfKey:@"Developer"];
    if(developerURL) {
        homePath = developerURL.path;
    }
    
    self.title = @"Open Recent";
    
    // Register the nib for the table view
    [self.tableView registerNib:[UINib nibWithNibName:@"ProjectViewCell" bundle:nil] forCellReuseIdentifier:@"ProjectViewCell"];
    
    [self loadData];
    
    // Create and set up the "Refresh" button
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithTitle:@"刷新"
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(refreshAction:)];
    [refreshButton setTintColor:UIColor.systemBlueColor];
    
    // Create and set up the "Select Developer Folder" button
    UIBarButtonItem *devButton = [[UIBarButtonItem alloc] initWithTitle:@"选择开发文件夹"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(openDeveloper:)];
    [devButton setTintColor:UIColor.systemBlueColor];
    
    UIBarButtonItem *fileButton = [[UIBarButtonItem alloc] initWithTitle:@"授权历史文件夹"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(showApplicationRecentDocuments:)];
    [fileButton setTintColor:UIColor.systemBlueColor];
    self.navigationItem.rightBarButtonItems = @[refreshButton, devButton, fileButton];
    
    // 创建一个UILabel
    UILabel *hintLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    hintLabel.text = @"请点击<授权历史文件夹>按钮，确认路径是\n\"~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments\"，\n要显示git分支信息，请点击<选择开发者文件夹>";
    hintLabel.numberOfLines = 0; // 允许多行
    hintLabel.textAlignment = NSTextAlignmentCenter;
    hintLabel.textColor = [UIColor blackColor];
    
    // 设置UILabel的约束，使其在视图中央
    hintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:hintLabel];
    [self.view insertSubview:hintLabel atIndex:0];

    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:hintLabel
                                                                         attribute:NSLayoutAttributeCenterX
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeCenterX
                                                                        multiplier:1.0
                                                                          constant:0.0];
    
    NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:hintLabel
                                                                         attribute:NSLayoutAttributeCenterY
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeCenterY
                                                                        multiplier:1.0
                                                                          constant:0.0];
    
    // 添加约束
    [self.view addConstraints:@[centerXConstraint, centerYConstraint]];
    
}

- (NSURL *)resolveBookmarkDataOfKey:(NSString *)key {
    NSData *bookmarkData = [NSUserDefaults.standardUserDefaults objectForKey:key];
    
    BOOL isStale = NO;
    NSURL *docURL = [NSURL URLByResolvingBookmarkData:bookmarkData
                                              options:NSURLBookmarkResolutionWithSecurityScope
                                        relativeToURL:nil
                                  bookmarkDataIsStale:&isStale
                                                error:nil];
    // [docURL stopAccessingSecurityScopedResource];
    if (isStale) {
        NSData *savedata = [docURL bookmarkDataWithOptions:NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess
                            includingResourceValuesForKeys:nil
                                             relativeToURL:nil
                                                     error:nil];
        [NSUserDefaults.standardUserDefaults setObject:savedata forKey:key];
    }
    [docURL startAccessingSecurityScopedResource];
    return docURL;
}

- (void)refreshAction:(id)sender {
    [self loadData];
    [self.tableView reloadData];
}


- (void)loadData {
    NSURL *docURL = [self resolveBookmarkDataOfKey:kApplicationRecentDocumentsKey];
    
    NSString *filePath = [self filePathForDocumentPath:docURL.path];
    
    if (!filePath) {
        [self handleFileNotFound];
        return;
    }
    
    [self runWithFilePath:filePath];
}

- (NSString *)filePathForDocumentPath:(NSString *)documentPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [documentPath stringByAppendingPathComponent:kXcodeSFLFileName];
    
    if (![fileManager fileExistsAtPath:filePath]) {
        NSString *oldFilePath = [documentPath stringByAppendingPathComponent:@"com.apple.dt.xcode.sfl2"];
        if ([fileManager fileExistsAtPath:oldFilePath]) {
            filePath = oldFilePath;
        } else {
            return nil; // File not found
        }
    }
    
    return filePath;
}

- (void)handleFileNotFound {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"未获取到记录文件"
                                                                             message:@"请授予文件夹访问权限"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *grantAction = [UIAlertAction actionWithTitle:@"现在授予"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
        [self showApplicationRecentDocuments:nil];
    }];
    
    UIAlertAction *laterAction = [UIAlertAction actionWithTitle:@"稍后再说"
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil];
    
    [alertController addAction:grantAction];
    [alertController addAction:laterAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)handleReadFileError {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self handleFileNotFound];
    });
}

- (void)runWithFilePath:(NSString *)filePath {
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfURL:fileURL options:NSDataReadingMappedIfSafe error:&error];
    
    if (error || data == nil) {
        [self handleReadFileError];
        return;
    }
    
    self.recentListArray = readSflWithFile(filePath);
    // TODO: .Trash 路径排除
    self.tableView.backgroundColor = UIColor.whiteColor;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //#if TARGET_OS_MACCATALYST
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSMutableDictionary *branchInfo = [NSMutableDictionary dictionary];
        NSMutableDictionary *iconInfo = [NSMutableDictionary dictionary];
        
        //#endif
        [self->_recentListArray enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *workPath = obj.stringByDeletingLastPathComponent;
            NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:[NSURL fileURLWithPath:obj.stringByDeletingPathExtension] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
            NSURL *appiconset = nil;
            for (NSURL *fileUrl in enumerator) {
                // NSLog(@"%@", fileUrl);todo:增加深度限制，max-depth
                NSString *aItem = [fileUrl lastPathComponent];
                //appiconset
                if ([@"appiconset" isEqualToString:aItem.pathExtension]) {
                    appiconset = fileUrl;
                    break;
                }
            }
            if (appiconset) {
                NSDirectoryEnumerator *enumeratorIcon = [fileManager enumeratorAtURL:appiconset includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
                for (NSURL *fileUrl in enumeratorIcon) {
                    UIImage *image = [UIImage imageWithContentsOfFile:fileUrl.path];
                    if (image.size.width >= 60 && image.size.width <= 1200) {
                        iconInfo[obj] = image;
                        break;
                    }
                }
            }
            
            
            // 设置最大回溯层数为4
            NSInteger maxDepth = 4;
            
            NSString *gitFolder = findGitFolder(workPath, maxDepth, 0);
            
            if (gitFolder) {
                // NSLog(@"Found .git folder in: %@", gitFolder);
                
                NSString *headContents = readHEADContents(gitFolder);
                
                if (headContents) {
                    // NSLog(@"Contents of HEAD file:\n%@", headContents);
                    branchInfo[obj] = [headContents componentsSeparatedByString:@"/"].lastObject;
                } else {
                    NSLog(@"Failed to read HEAD file.");
                }
            } else {
                NSLog(@".git folder not found within the specified depth limit.");
            }
            
            //            SEL selector = NSSelectorFromString(@"runShell:workingDirectory:");
            //            NSDictionary *result = [principalClass performSelector:selector withObject:@[@"git", @"-C", workPath, @"branch", @"-a"] withObject:workingDir];
            //            NSLog(@"dacaiguoguogit:%@ %@", workPath, result);
            //            NSNumber *code = result[@"code"];
            //            if (code.intValue == 0) { /// code == 0 命令执行成功
            //                NSString *output = result[@"output"];
            //                NSArray *resultArray = [output componentsSeparatedByString:@"\n"];
            //                for (NSString *item in resultArray) {
            //                    if ([item hasPrefix:@"*"]) {
            //                        NSLog(@"%@ %@", code, item);
            //                        branchInfo[obj] = [item substringFromIndex:1];
            //                        break;
            //                    }
            //                }
            //            }
        }];
        self.branchInfo = branchInfo;
        self.iconInfo = iconInfo;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
}

- (void)openDeveloper:(id)sender {
    NSString *pluginPath = [[NSBundle.mainBundle builtInPlugInsURL] URLByAppendingPathComponent:@"SwiftTool.bundle"].path;
    NSBundle *bundle = [NSBundle bundleWithPath:pluginPath];
    [bundle load];
    
    // Load the principal class from the bundle
    // This is set in MacTask/Info.plist
    Class principalClass = bundle.principalClass;
    SEL selector = NSSelectorFromString(@"selectFolderBtnClicked:");
    NSString *documentPath = @"~/Developer".stringByStandardizingPath;
    NSURL *docurl = [principalClass performSelector:selector withObject:documentPath];
    if (docurl) {
        NSData *savedata = [docurl bookmarkDataWithOptions:NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
        [NSUserDefaults.standardUserDefaults setObject:savedata forKey:@"Developer"];
        [self loadData];
    }
}

- (void)showApplicationRecentDocuments:(id)sender {
    NSString *pluginPath = [[NSBundle.mainBundle builtInPlugInsURL] URLByAppendingPathComponent:@"SwiftTool.bundle"].path;
    NSBundle *bundle = [NSBundle bundleWithPath:pluginPath];
    [bundle load];
    
    // Load the principal class from the bundle
    // This is set in MacTask/Info.plist
    Class principalClass = bundle.principalClass;
    SEL selector = NSSelectorFromString(@"selectFolderBtnClicked:");
    NSString *documentPath = @"~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments".stringByStandardizingPath;
    NSURL *docurl = [principalClass performSelector:selector withObject:documentPath];
    if ([docurl.path.lastPathComponent isEqualToString:@"com.apple.LSSharedFileList.ApplicationRecentDocuments"]) {
        NSData *savedata = [docurl bookmarkDataWithOptions:NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
        [NSUserDefaults.standardUserDefaults setObject:savedata forKey:@"ApplicationRecentDocuments"];
        [self loadData];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"授权文件夹路径错误"
                                                                                 message:@"请确认是\"~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments\"，再次点击<授权历史文件夹>按钮"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *laterAction = [UIAlertAction actionWithTitle:@"我知道了"
                                                              style:UIAlertActionStyleCancel
                                                            handler:nil];
        
        [alertController addAction:laterAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
    
    //    SEL selector = NSSelectorFromString(@"runShell:workingDirectory:");
    //    __unused NSDictionary *result = [principalClass performSelector:selector withObject:@[@"open", @"-a", @"System Preferences"] withObject:NSHomeDirectory()];
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
    cell.path = orgPath;
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
