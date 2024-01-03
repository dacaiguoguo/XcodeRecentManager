//
//  JsonViewController.m
//  XcodeRecentManager
//
//  Created by yanguo sun on 2024/1/2.
//

#import "JsonViewController.h"


@interface JsonViewController ()

@end

@implementation JsonViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    // Do any additional setup after loading the view.
    
    // JSON 字符串
    NSString *jsonString = @"{\"text\":{\"objectId\":\"1704176303739\",\"turn_AGC\":false,\"use_robot\":false,\"userId\":\"5100\",\"room_id\":\"1704176303739\",\"is_private\":false,\"name\":\"语聊房-0102-90\",\"member_count\":3,\"id\":\"1704176303739\",\"roomPassword\":\"\",\"created_at\":1704176303739,\"gift_amount\":0,\"owner\":{\"amount\":0,\"portrait\":\"https:\\/\\/accktvpic.oss-cn-beijing.aliyuncs.com\\/pic\\/meta\\/demo\\/fulldemoStatic\\/man3.png\",\"micStatus\":1,\"invited\":false,\"chat_uid\":\"5100\",\"uid\":\"5100\",\"rtc_uid\":\"5100\",\"volume\":0,\"channel_id\":\"\",\"name\":\"Qing\"},\"rtc_uid\":5100,\"sound_effect\":1,\"member_list\":[],\"chatroom_id\":\"235696893788166\",\"type\":0,\"turn_AIAEC\":false,\"channel_id\":\"1704176303739\",\"ranking_list\":[],\"click_count\":3}}";

    // 将 JSON 字符串转为 NSData
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

    // 解析 JSON 数据
    NSError *error;
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];

    if (!error) {
        // 获取包含转义字符的字符串
        NSString *textWithEscapes = jsonObject[@"text"];
        NSLog(@"Original String: %@", textWithEscapes);

        // 去除转义字符
        NSData *data = [textWithEscapes dataUsingEncoding:NSUTF8StringEncoding];
        NSString *decodedString = [[NSString alloc] initWithData:data encoding:NSNonLossyASCIIStringEncoding];
        NSLog(@"Decoded String: %@", decodedString);
    } else {
        NSLog(@"Error parsing JSON: %@", [error localizedDescription]);
    }
    
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
