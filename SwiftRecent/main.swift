//
//  main.swift
//  SwiftRecent
//
//  Created by dacaiguoguo on 2021/9/1.
//

import Foundation
let FD = FileManager.default


class SFLListItem: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool = true

    var bookmark:NSData
    var url:NSURL

    func encode(with coder: NSCoder) {

    }

    required init?(coder: NSCoder) {
        bookmark = coder.decodeObject(of: NSData.self, forKey: "bookmark") ?? NSData()
        url = coder.decodeObject(of: NSURL.self, forKey: "URL") ?? NSURL()
    }
}



let pathOfRecent = ("~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/" as NSString).standardizingPath
let enumrator = FD.enumerator(atPath: pathOfRecent)
var resultArray:[[String]] = []

func readSflWithFile(_ filePath:String) -> [String] {
    var resultArray:[String] = []
    if let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
        do {
            NSKeyedUnarchiver.setClass(SFLListItem.self, forClassName: "SFLListItem")
            if let recentListInfo = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String: Any]{
                if let recentList = recentListInfo["items"] as? [Any] {
                    for item in recentList {
                        if let dicItem = item as? [String: Any] {
                            if let bookData = dicItem["Bookmark"] as? Data {
                                var bookmarkDataIsStale:Bool = false
                                if let resultUrl = try? URL(resolvingBookmarkData: bookData, bookmarkDataIsStale: &bookmarkDataIsStale) {
                                    resultArray.append(resultUrl.path)
                                }
                            }
                        } else if let dicItem = item as? SFLListItem {
                            if let aPath = dicItem.url.path {
                                resultArray.append(aPath)
                            }
                        }
                    }
                }
            }
        } catch  {
             print(error)
        }
    } else {
        print("没有权限访问!\(pathOfRecent)")
    }

    return resultArray
}
var hasnext = false
while let item =  enumrator?.nextObject() {
    hasnext = true
//    if item as! String == /*"io.realm.realmbrowser.sfl"*/"com.apple.dt.xcode.sfl2" {
        let toFindPath = "\(pathOfRecent)/\(item)"
        let findResult = readSflWithFile(toFindPath)
        resultArray.append(findResult)
        print(item, findResult)
//    }
}

if hasnext == false {
    print("没有权限访问!\(pathOfRecent)")
}




