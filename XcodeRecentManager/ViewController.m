//
//  ViewController.m
//  XcodeRecentManager
//
//  Created by Dacaiguoguo on 2021/7/28.
//

#import "ViewController.h"
#import "SFLListItem.h"
#import "JsonViewController.h"
#import "ProjectViewCell.h"
static NSString * const kApplicationRecentDocumentsKey = @"ApplicationRecentDocuments";
static NSString * const kXcodeSFLFileName = @"com.apple.dt.xcode.sfl3";
static NSString * const kXcodeSFLFileName2 = @"com.apple.dt.xcode.sfl2";
static NSString * const kXcodeSFLFileDoc = @"~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments";

#import <Foundation/Foundation.h>

NSString * findGitFolder(NSString *currentPath, NSInteger maxDepth, NSInteger currentDepth) {
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

NSString * readHEADContents(NSString *gitFolderPath) {
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


NSURL *replaceSchemeWithXcodeScheme(NSURL *originalURL) {
    NSURLComponents *components = [NSURLComponents componentsWithURL:originalURL resolvingAgainstBaseURL:NO];

    // 替换scheme为"xcode"
    components.scheme = @"xcode";

    // 创建替换后的URL
    NSURL *modifiedURL = components.URL;
    
    return modifiedURL;
}


NSString *stringToHex(NSString *inputString) {
    // 将字符串转换为 UTF-8 编码的 NSData
    NSData *data = [inputString dataUsingEncoding:NSUTF8StringEncoding];
    
    // 获取 NSData 中的字节数组
    const uint8_t *bytes = [data bytes];
    
    // 用于存储结果的可变字符串
    NSMutableString *hexString = [NSMutableString stringWithCapacity:[data length] * 2];
    
    // 遍历字节数组，将每个字节转换为十六进制表示
    for (NSInteger i = 0; i < [data length]; i++) {
        [hexString appendFormat:@"%02X ", bytes[i]];
    }
    
    return hexString.lowercaseString;
}


NSArray<NSString *> *readURLsFromFile(NSString *filePath) {
    // 从文件中读取字符串数组
    NSArray *stringURLs = [NSArray arrayWithContentsOfFile:filePath];
    
    if (stringURLs == nil) {
        NSLog(@"Failed to read array from file at path: %@", filePath);
        return @[];
    }    
    return stringURLs;
}

@implementation NSMutableArray (UniqueAddition)

- (void)addUniqueObject:(id)object {
    if (![self containsObject:object]) {
        [self addObject:object];
    }
}

@end

NSArray<NSString *> *mergeAndSortURLArrays(NSArray<NSString *> *firstArray, NSArray<NSString *> *secondArray) {
    NSMutableArray<NSString *> *sortedArray = [NSMutableArray array];
    [firstArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        if (![obj containsString:@".Trash"]) {
            [sortedArray addUniqueObject:obj];
//        }
    }];
    [secondArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        if (![obj containsString:@".Trash"]) {
            [sortedArray addUniqueObject:obj];
//        }
    }];
    
    return [sortedArray copy];
}



// #if TARGET_OS_MACCATALYST

@interface ViewController () <UITableViewDelegate, UITableViewDataSource> {
    NSString *homePath;
}
@property (nonatomic, copy) NSArray *recentListArray;
@property (nonatomic, copy) NSDictionary *branchInfo;
@property (nonatomic, copy) NSDictionary *iconInfo;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UITextView *hintLabel;

@end




@implementation ViewController

- (void)cleanSave:(id)sender {
//    JsonViewController *jvc = [[JsonViewController alloc] init];
//    [self.navigationController pushViewController:jvc animated:YES];
    NSURL *developerURL = [self resolveBookmarkDataOfKey:@"Developer"];
    [developerURL stopAccessingSecurityScopedResource];
    NSURL *docURL = [self resolveBookmarkDataOfKey:kApplicationRecentDocumentsKey];
    [docURL stopAccessingSecurityScopedResource];
    // Remove unnecessary user defaults
    [NSUserDefaults.standardUserDefaults removeObjectForKey:@"Developer"];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:@"ApplicationRecentDocuments"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //    NSString *outpou = stringToHex(@"com.apple.Terminal");
    // 63 6f 6d 2e 61 70 70 6c 65 2e 54 65 72 6d 69 6e 61 6c
    // 64 65 76 2e 77 61 72 70 2e 57 61 72 70 2d 53 74 61 62 6c 65
    //    NSString *outpou = stringToHex(@"dev.warp.Warp-Stable");
    //    NSLog(@"%@", outpou);
    self.tableView.backgroundColor = UIColor.clearColor;


    NSString *username = NSUserName();

    homePath = [NSString stringWithFormat:@"/Users/%@", username];
    // Check and access the security-scoped resource for the developer folder
    NSURL *developerURL = [self resolveBookmarkDataOfKey:@"Developer"];
    if (developerURL) {
        homePath = developerURL.path;
    }

    self.title = @"Open Recent";

    // Register the nib for the table view
    [self.tableView registerNib:[UINib nibWithNibName:@"ProjectViewCell" bundle:nil] forCellReuseIdentifier:@"ProjectViewCell"];


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

    UIBarButtonItem *cleanButton = [[UIBarButtonItem alloc] initWithTitle:@"授权重置"
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(cleanSave:)];
    [cleanButton setTintColor:UIColor.systemBlueColor];
    self.navigationItem.rightBarButtonItems = @[refreshButton, devButton, fileButton];
    self.navigationItem.leftBarButtonItem = cleanButton;
    // 创建一个UILabel
    self.hintLabel = [[UITextView alloc] initWithFrame:CGRectZero];
    NSString *message = [NSString stringWithFormat:@"如果已经授权，请确认\"%@\"，\n文件夹下是否存在%@或者%@", kXcodeSFLFileDoc, kXcodeSFLFileName, kXcodeSFLFileName2];
    _hintLabel.text = [NSString stringWithFormat:@"请点击<授权历史文件夹>按钮，确认路径是\n\"%@\"，\n要显示git分支信息，请点击<选择开发者文件夹>\n%@", kXcodeSFLFileDoc, message];
    _hintLabel.textAlignment = NSTextAlignmentCenter;
    _hintLabel.textColor = [UIColor blackColor];
    _hintLabel.editable = NO;
    // 设置UILabel的约束，使其在视图中央
    _hintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_hintLabel];
    _hintLabel.font = [UIFont systemFontOfSize:20];
    [self.view bringSubviewToFront:_hintLabel];

    // Set up constraints for width and height equal to self.view
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:_hintLabel
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.view
                                                                       attribute:NSLayoutAttributeWidth
                                                                      multiplier:0.6
                                                                        constant:0];

    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:_hintLabel
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.view
                                                                        attribute:NSLayoutAttributeHeight
                                                                       multiplier:0.6
                                                                         constant:0];



    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:_hintLabel
                                                                         attribute:NSLayoutAttributeCenterX
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeCenterX
                                                                        multiplier:1.0
                                                                          constant:0.0];

    NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:_hintLabel
                                                                         attribute:NSLayoutAttributeCenterY
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeCenterY
                                                                        multiplier:1.0
                                                                          constant:0.0];

    // 添加约束
    [self.view addConstraints:@[centerXConstraint, centerYConstraint, widthConstraint, heightConstraint]];
    
    [self loadData];
    

} /* viewDidLoad */

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
} /* resolveBookmarkDataOfKey */

- (void)refreshAction:(id)sender {
    [self loadData];
    [self.tableView reloadData];
}

- (void)loadData {
    NSURL *docURL = [self resolveBookmarkDataOfKey:kApplicationRecentDocumentsKey];
    if (!docURL) {

        
        NSString *message = [NSString stringWithFormat:@"如果已经授权，请确认\"%@\"，文件夹下是否存在%@或者%@", kXcodeSFLFileDoc, kXcodeSFLFileName, kXcodeSFLFileName2];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"未获取到记录文件"
                                                                                 message:message
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *grantAction = [UIAlertAction actionWithTitle:@"现在授予"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * _Nonnull action) {
            [self showApplicationRecentDocuments:nil];
        }];
        
        UIAlertAction *laterAction = [UIAlertAction actionWithTitle:@"我知道了"
                                                              style:UIAlertActionStyleCancel
                                                            handler:nil];
        [alertController addAction:grantAction];

        [alertController addAction:laterAction];

        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    NSString *filePath = [self filePathForDocumentPath:docURL.path];

    if (!filePath) {
        [self handleFileNotFound];
        return;
    }
    [self callMethodInCatalystApp];

    [self runWithFilePath:filePath];
}

- (NSString *)filePathForDocumentPath:(NSString *)documentPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [documentPath stringByAppendingPathComponent:kXcodeSFLFileName];

    if (![fileManager fileExistsAtPath:filePath]) {
        NSString *oldFilePath = [documentPath stringByAppendingPathComponent:kXcodeSFLFileName2];
        if ([fileManager fileExistsAtPath:oldFilePath]) {
            filePath = oldFilePath;
        } else {
            return nil; // File not found
        }
    }

    return filePath;
}

- (void)handleFileNotFound {
    NSString *message = [NSString stringWithFormat:@"如果已经授权，请确认\"%@\"，文件夹下是否存在%@或者%@", kXcodeSFLFileDoc, kXcodeSFLFileName, kXcodeSFLFileName2];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"未获取到记录文件"
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *laterAction = [UIAlertAction actionWithTitle:@"我知道了"
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil];

    [alertController addAction:laterAction];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)handleReadFileError {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self handleFileNotFound];
    });
}

- (void)runWithFilePath:(NSString *)filePath {
    // Use NSURLResourceKeyIsRegularFile to check if the file at the given URL is a regular file
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    NSNumber *isRegularFile;
    NSError *fileError = nil;
    [fileURL getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:&fileError];

    if (fileError || ![isRegularFile boolValue]) {
        [self handleReadFileError];
        return;
    }

    NSError *readError = nil;
    NSData *data = [NSData dataWithContentsOfURL:fileURL options:NSDataReadingMappedIfSafe error:&readError];

    if (readError || data == nil) {
        [self handleReadFileError];
        return;
    }

    // Use NSURL method to get the document directory
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    NSString *historyFilePath = [documentsDirectoryURL URLByAppendingPathComponent:@"recentListArray.plist"].path;

    // Use NSURL method to read and write arrays to URLs
    NSArray *historyInFile = [NSArray arrayWithContentsOfURL:[NSURL fileURLWithPath:historyFilePath]] ?: @[];
    NSArray *xcodeHistory = readSflWithData(data) ?: @[];
    self.recentListArray = [mergeAndSortURLArrays(xcodeHistory, historyInFile) filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT SELF CONTAINS[c] %@", @".Trash"]];

    // Use NSURL method to delete the file
    [[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:historyFilePath] error:nil];

    NSError *writeError = nil;
    BOOL writeSuccess = [self.recentListArray writeToURL:[NSURL fileURLWithPath:historyFilePath] error:&writeError];

    if (!writeSuccess || writeError) {
        NSLog(@"writeToURL Fail:%@", writeError);
    }

    // TODO: .Trash 路径排除 /Users/yanguosun/.Trash/Demo1/Demo1.xcodeproj,
    self.hintLabel.hidden = YES;
    NSArray *recentListArraySafe = self.recentListArray;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // #if TARGET_OS_MACCATALYST
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSMutableDictionary *branchInfo = [NSMutableDictionary dictionary];
        NSMutableDictionary *iconInfo = [NSMutableDictionary dictionary];

        // #endif
        [recentListArraySafe enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
             NSString *workPath = obj.stringByDeletingLastPathComponent;
             NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:[NSURL fileURLWithPath:workPath] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
             NSURL *appiconset = nil;
             for (NSURL *fileUrl in enumerator) {
                 // appiconset
                 if ([@"appiconset" isEqualToString:fileUrl.pathExtension]) {
                     appiconset = fileUrl;
                     break;
                 }
             }
             if (appiconset) {
                 NSDirectoryEnumerator *enumeratorIcon = [fileManager enumeratorAtURL:appiconset 
                                                           includingPropertiesForKeys:nil
                                                                              options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
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
         }];
        self.branchInfo = branchInfo;
        self.iconInfo = iconInfo;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
} /* runWithFilePath */

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

- (void)callMethodInCatalystApp {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:@"MyNotification" object:nil];

    NSString *pluginPath = [[NSBundle.mainBundle builtInPlugInsURL] URLByAppendingPathComponent:@"SwiftTool.bundle"].path;
    NSBundle *bundle = [NSBundle bundleWithPath:pluginPath];

    [bundle load];

    // Load the principal class from the bundle
    // This is set in MacTask/Info.plist
    Class principalClass = bundle.principalClass;
    SEL selector = NSSelectorFromString(@"callMethodInCatalystApp:vc:");
    NSURL *docURL = [self resolveBookmarkDataOfKey:kApplicationRecentDocumentsKey];
    NSString *documentPath = [self filePathForDocumentPath:docURL.path];
    [principalClass performSelector:selector withObject:@[documentPath] withObject:self];
    NSLog(@"%@", @"");
}
- (void)handleNotification:(NSNotification *)notification {
    // 处理接收到的通知
    NSLog(@"Received Notification: %@", notification.name);
    [self refreshAction:nil];
}

- (void)dealloc {
    // 在对象销毁时取消注册
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)showApplicationRecentDocuments:(id)sender {
    NSString *pluginPath = [[NSBundle.mainBundle builtInPlugInsURL] URLByAppendingPathComponent:@"SwiftTool.bundle"].path;
    NSBundle *bundle = [NSBundle bundleWithPath:pluginPath];

    [bundle load];

    // Load the principal class from the bundle
    // This is set in MacTask/Info.plist
    Class principalClass = bundle.principalClass;
    SEL selector = NSSelectorFromString(@"selectFolderBtnClicked:");
    NSString *documentPath = kXcodeSFLFileDoc.stringByStandardizingPath;
    NSLog(@"gettingdocumentPath:%@", documentPath);
    NSURL *docurl = [principalClass performSelector:selector withObject:documentPath];
    if ([docurl.path.lastPathComponent isEqualToString:@"com.apple.LSSharedFileList.ApplicationRecentDocuments"]) {
        NSData *savedata = [docurl bookmarkDataWithOptions:NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
        [NSUserDefaults.standardUserDefaults setObject:savedata forKey:@"ApplicationRecentDocuments"];
        [self loadData];
    } else if(docurl.path.length > 0) {
        NSString *message = [NSString stringWithFormat:@"请确认是\"%@\"，再次点击<授权历史文件夹>按钮", kXcodeSFLFileDoc];

        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"授权文件夹路径错误"
                                                                                 message:message
                                                                          preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *laterAction = [UIAlertAction actionWithTitle:@"我知道了"
                                                              style:UIAlertActionStyleCancel
                                                            handler:nil];

        [alertController addAction:laterAction];

        [self presentViewController:alertController animated:YES completion:nil];
    }

    //    SEL selector = NSSelectorFromString(@"runShell:workingDirectory:");
    //    __unused NSDictionary *result = [principalClass performSelector:selector withObject:@[@"open", @"-a", @"System Preferences"] withObject:NSHomeDirectory()];
} /* showApplicationRecentDocuments */
#pragma tableView UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.recentListArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"ProjectViewCell";
    ProjectViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    NSString *orgPath = self.recentListArray[indexPath.row];
    NSString *path = [orgPath stringByReplacingOccurrencesOfString:[homePath stringByAppendingString:@"/"] withString:@""];
    cell.pathLabel.text = path;
    cell.path = orgPath;
    NSString *branchName = self.branchInfo[orgPath];
    cell.branchLabel.text = branchName;
    UIImage *iconinf = self.iconInfo[orgPath];
    if (iconinf) {
        cell.iconImageView.image = iconinf;
    } else if ([orgPath.pathExtension isEqualToString:@"plist"]) {
        cell.iconImageView.image = [UIImage imageNamed:@"plisticon"];
    } else {
        cell.iconImageView.image = [UIImage imageNamed:@"XcodeIcon"];
    }
    cell.iconImageView.layer.cornerRadius = 8;
    return cell;
}

#pragma tableView--UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *orgPath = self.recentListArray[indexPath.row];
    NSURL *xcodeURL = [NSURL fileURLWithPath:orgPath];
    if (![orgPath.lastPathComponent containsString:@"."]) {
        xcodeURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/Package.swift", orgPath]];
    }
//    NSString *pluginPath = [[NSBundle.mainBundle builtInPlugInsURL] URLByAppendingPathComponent:@"SwiftTool.bundle"].path;
//    NSBundle *bundle = [NSBundle bundleWithPath:pluginPath];
//
//    [bundle load];
//
//    // Load the principal class from the bundle
//    // This is set in MacTask/Info.plist
//    Class principalClass = bundle.principalClass;
//    SEL selector = NSSelectorFromString(@"openURLs:appUrl:");
//    [principalClass performSelector:selector withObject:@[xcodeURL] withObject:[NSURL fileURLWithPath:@"/Applications/Xcode.app"]];

//    xcode
    // 示例用法
//    NSURL *xcodeURL = replaceSchemeWithXcodeScheme(aUrl);
//    NSLog(@"xcodeURL:%@", xcodeURL);
    [[UIApplication sharedApplication] openURL:xcodeURL options:@{} completionHandler:^(BOOL success) {
         NSLog(@"%@", @(success));
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        if (!success) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"打开失败，请检查权限"
                                                                                     message:nil
                                                                              preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *laterAction = [UIAlertAction actionWithTitle:@"我知道了"
                                                                  style:UIAlertActionStyleCancel
                                                                handler:nil];

            [alertController addAction:laterAction];

            [self presentViewController:alertController animated:YES completion:nil];
        }
     }];
}

@end

