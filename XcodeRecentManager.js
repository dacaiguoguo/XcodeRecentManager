var plist = require('@atom/plist');

const objc = require('objc');
 
const {
  NSDate,
  NSData,
  NSURL,
  NSArray,
  NSString,
  NSDictionary,
  NSDateFormatter,
  NSKeyedUnarchiver 
} = objc;

// var path = NSString.stringWithString("/Users/boot/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/com.apple.dt.xcode.sfl2");
var path = NSString.stringWithString("/Users/boot/Downloads/com.apple.dt.xcode.sfl2");
// 
// var pathFull = path.stringByStandardizingPath();
console.log(path)
var url = NSURL.fileURLWithPath(path)
console.log(url)
var data = NSData.dataWithContentsOfURL(url)
if (!data) {
  return;
}
// console.log(data)
var recentListInfo = NSKeyedUnarchiver.unarchiveObjectWithData(data)
var recentList = recentListInfo.objectForKey("items")


for (var i = recentList.count() - 1; i >= 0; i--) {
    var firstObj = recentList.objectAtIndex(i)
    var bookmarkData = firstObj.objectForKey("Bookmark")
    //+ (nullable instancetype)URLByResolvingBookmarkData:(NSData *)bookmarkData options:(NSURLBookmarkResolutionOptions)options relativeToURL:(nullable NSURL *)relativeURL bookmarkDataIsStale:(BOOL * _Nullable)isStale error:(NSError **)error API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    var receurl = NSURL.URLByResolvingBookmarkData_options_relativeToURL_bookmarkDataIsStale_error(bookmarkData, 1 << 8, null, null, null)
    console.log(receurl)
}

// var obj = plist.parseFileSync();

// console.log(JSON.stringify(recentList));
