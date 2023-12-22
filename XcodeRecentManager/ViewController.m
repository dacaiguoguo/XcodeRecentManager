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
    
    // Remove unnecessary user defaults
    [NSUserDefaults.standardUserDefaults removeObjectForKey:@"Developer"];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:@"ApplicationRecentDocuments"];
    
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
                                                                  action:@selector(openSystemPreferences:)];
    [fileButton setTintColor:UIColor.systemBlueColor];
    self.navigationItem.rightBarButtonItems = @[refreshButton, devButton, fileButton];
    
    // Check and access the security-scoped resource for the developer folder
    NSURL *docURL = [self resolveBookmarkDataOfKey:@"Developer"];
    [docURL startAccessingSecurityScopedResource];
}

- (NSURL *)resolveBookmarkDataOfKey:(NSString *)key {
    NSData *bookmarkData = [NSUserDefaults.standardUserDefaults objectForKey:key];
    
    BOOL isStale = NO;
    NSURL *docURL = [NSURL URLByResolvingBookmarkData:bookmarkData
                                              options:NSURLBookmarkResolutionWithSecurityScope
                                        relativeToURL:nil
                                  bookmarkDataIsStale:&isStale
                                                error:nil];
    
    if (isStale) {
        NSData *savedata = [docURL bookmarkDataWithOptions:NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess
                            includingResourceValuesForKeys:nil
                                             relativeToURL:nil
                                                     error:nil];
        [NSUserDefaults.standardUserDefaults setObject:savedata forKey:key];
    }
    
    return docURL;
}

- (void)refreshAction:(id)sender {
    [self loadData];
    [self.tableView reloadData];
}


- (void)loadData {
    NSURL *docURL = [self resolveBookmarkDataOfKey:kApplicationRecentDocumentsKey];
    [docURL startAccessingSecurityScopedResource];
    
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
        [self openSystemPreferences:nil];
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
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"读取失败"
                                                                       message:@"请授予文件夹访问权限"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
            [self openSystemPreferences:nil];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
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

- (void)openSystemPreferences:(id)sender {
    NSString *pluginPath = [[NSBundle.mainBundle builtInPlugInsURL] URLByAppendingPathComponent:@"SwiftTool.bundle"].path;
    NSBundle *bundle = [NSBundle bundleWithPath:pluginPath];
    [bundle load];
    
    // Load the principal class from the bundle
    // This is set in MacTask/Info.plist
    Class principalClass = bundle.principalClass;
    SEL selector = NSSelectorFromString(@"selectFolderBtnClicked:");
    NSString *documentPath = @"~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments".stringByStandardizingPath;
    NSURL *docurl = [principalClass performSelector:selector withObject:documentPath];
    if (docurl) {
        NSData *savedata = [docurl bookmarkDataWithOptions:NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
        [NSUserDefaults.standardUserDefaults setObject:savedata forKey:@"ApplicationRecentDocuments"];
        [self loadData];
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
