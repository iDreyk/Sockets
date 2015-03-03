//
//  DataManager.h
//  Sockets
//
//  Created by Ilya Tsarev on 03.03.15.
//  Copyright (c) 2015 Ilya Tsarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DataManager : NSObject

+ (DataManager *)sharedInstance;

- (NSArray *)getChatDataForUser:(NSString *)username;
- (BOOL)saveChatDataForUser:(NSString *)username message:(NSString *)message date:(NSDate *)date;

@end
