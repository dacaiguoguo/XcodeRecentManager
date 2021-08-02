//
//  ViewController.m
//  XcodeRecentManager
//
//  Created by Dacaiguoguo on 2021/7/28.
//

#import "ViewController.h"
// #if TARGET_OS_MACCATALYST
@implementation List
+ (BOOL)supportsSecureCoding {
    return YES;
}
- (void)encodeWithCoder:(nonnull NSCoder *)coder {

}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    self = [super init];
    return self;
}

@end
@interface ViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, copy) NSArray *recentListArray;
@property (nonatomic, copy) NSDictionary *branchInfo;
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadData];
    [self.view addSubview:self.tableView];

//    [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
//        [self loadData];
//        [self.tableView reloadData];
//    }];
}

- (void)loadData {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *err = nil;
    NSString *filePath = @"~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/com.apple.dt.xcode.sfl2".stringByStandardizingPath;
    BOOL isExist = [fileManager fileExistsAtPath:filePath];
    if (!isExist) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"file Not Exists" message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {

            }]];
            [self presentViewController:alert animated:YES completion:nil];
        });
        return;
    }
    NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
    NSData *data = [[NSData alloc] initWithContentsOfURL:fileUrl options:(NSDataReadingMappedIfSafe) error:&err];
    if (err) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:err.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {

            }]];
            [self presentViewController:alert animated:YES completion:nil];
        });
        return;
    }
    // NSDictionary *archver = [NSKeyedUnarchiver unarchivedObjectOfClass:NSDictionary.class fromData:data error:&err];
    NSDictionary *recentListInfo = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSArray *recentList = recentListInfo[@"items"];

    NSMutableArray *mutArray = [NSMutableArray array];
    [recentList enumerateObjectsUsingBlock:^(NSDictionary *bookmarkInfo, NSUInteger idx, BOOL * _Nonnull stop) {
        NSData *bookmark = bookmarkInfo[@"Bookmark"];
        CFErrorRef *errorRef = NULL;
        CFURLRef resolvedUrl = CFURLCreateByResolvingBookmarkData (NULL, CFBridgingRetain(bookmark), kCFBookmarkResolutionWithoutUIMask, NULL, NULL, false, errorRef);
        if (resolvedUrl == NULL) {
            NSLog(@"%@",@"null");
        } else {
            NSLog(@"%@",resolvedUrl);
            NSURL *aUrl = CFBridgingRelease(resolvedUrl);
            [mutArray addObject:aUrl];
        }
    }];
    self.recentListArray = mutArray;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //#if TARGET_OS_MACCATALYST
        NSString *pluginPath = [[NSBundle.mainBundle builtInPlugInsURL] URLByAppendingPathComponent:@"MacTask.bundle"].path;
        NSBundle *bundle = [NSBundle bundleWithPath:pluginPath];
        [bundle load];

        // Load the principal class from the bundle
        // This is set in MacTask/Info.plist
        Class principalClass = bundle.principalClass;

        NSURL *workingDir = [NSFileManager defaultManager].temporaryDirectory;            // [@"testing" writeToFile:[workingDir URLByAppendingPathComponent:@"test.txt"].path atomically:YES encoding:NSUTF8StringEncoding error:nil];
        NSMutableDictionary *branchInfo = [NSMutableDictionary dictionary];
        //#endif
        [mutArray enumerateObjectsUsingBlock:^(NSURL *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSURL *aUrl = obj;
            NSString *workPath = aUrl.path.stringByDeletingLastPathComponent;
            SEL selector = NSSelectorFromString(@"runShell:workingDirectory:");
            NSDictionary *result = [principalClass performSelector:selector withObject:@[@"git", @"-C", workPath, @"branch", @"-a"] withObject:workingDir];
            NSString *code = result[@"code"];
            NSString *output = result[@"output"];

            NSArray *resultArray = [output componentsSeparatedByString:@"\n"];
            for (NSString *item in resultArray) {
                if ([item hasPrefix:@"*"]) {
                    NSLog(@"%@ %@", code, item);
                    branchInfo[obj.path] = item;
                }
            }
        }];
        self.branchInfo = branchInfo;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
}

#pragma mark tableView lazy
-(UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

#pragma tableView UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.recentListArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"identifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }
    NSURL *aUrl = self.recentListArray[indexPath.row];
    NSString *path = aUrl.path;
    cell.textLabel.text = path;
    NSString *branchName = self.branchInfo[aUrl.path];
    cell.detailTextLabel.text = branchName;
    return cell;
}

#pragma tableView--UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSURL *aUrl = self.recentListArray[indexPath.row];
    [[UIApplication sharedApplication] openURL:aUrl options:@{} completionHandler:^(BOOL success) {
        NSLog(@"%@", @(success));
    }];
}

@end
