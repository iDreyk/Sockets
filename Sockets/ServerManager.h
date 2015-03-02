//
//  ServerManager.h
//  Sockets
//
//  Created by Ilya Tsarev on 27.02.15.
//  Copyright (c) 2015 Ilya Tsarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GCDAsyncSocket.h"

@protocol ServerManagerDelegate <NSObject>

@required
- (void)dataReceived:(NSData *)data;
@optional
- (void)connectionClosedWithError:(NSError *)error;
@end

@interface ServerManager : NSObject <GCDAsyncSocketDelegate>
{
    id <ServerManagerDelegate> _delegate;
}

@property (nonatomic,strong) id delegate;
@property (nonatomic, strong) GCDAsyncSocket *socket;


+ (ServerManager *)sharedInstance;


- (void)initNetworkCommunication;
- (void)joinChatWithUser:(NSString *)userName;
- (void)sendMessage:(NSString *)message;
- (void)disconnect;

@end
