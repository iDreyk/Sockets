//
//  ServerManager.m
//  Sockets
//
//  Created by Ilya Tsarev on 27.02.15.
//  Copyright (c) 2015 Ilya Tsarev. All rights reserved.
//

// info: https://github.com/robbiehanson/CocoaAsyncSocket/wiki/Intro_GCDAsyncSocket

#import "ServerManager.h"

#define TAG_LOGIN 10
#define TAG_MESSAGE 11
#define TAG_RUNLOOP 100

@interface ServerManager ()

@end

@implementation ServerManager

+ (ServerManager *)sharedInstance{
    static ServerManager *sharedInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once( &predicate, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)initAll{
    _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
}

- (void)initNetworkCommunication {
    static dispatch_once_t predicate;
    dispatch_once( &predicate, ^{
        [[ServerManager sharedInstance] initAll];
    });
    
    NSError *err = nil;
    if (![_socket connectToHost:@"localhost" onPort:8080 error:&err]) // Asynchronous!
    {
        NSLog(@"Error: %@", err);
    }
}

- (void)joinChatWithUser:(NSString *)userName{
    NSString *dataString  = [NSString stringWithFormat:@"iam:%@", userName];
    
    NSData *data = [[NSData alloc] initWithData:[dataString dataUsingEncoding:NSASCIIStringEncoding]];
    [_socket writeData:data withTimeout:-1 tag:TAG_LOGIN];
}

- (void)sendMessage:(NSString *)message{
    NSString *dataString  = [NSString stringWithFormat:@"msg:%@", message];

    NSData *data = [[NSData alloc] initWithData:[dataString dataUsingEncoding:NSASCIIStringEncoding]];
    [_socket writeData:data withTimeout:-1 tag:TAG_MESSAGE];
}

- (void)disconnect{
    [_socket disconnectAfterReadingAndWriting];
}

#pragma mark - Self delegate

- (void)dataReceived:(NSData *)data{
    NSLog(@"Data received. You need to override it to work with data.");
}

- (void)connectionClosedWithError:(NSError *)error{
    NSLog(@"Connection closed: ERROR: %@", [error localizedDescription]);
}

#pragma mark - Socket delegate

- (void)socket:(GCDAsyncSocket *)sender didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"Connected");
    [_socket readDataWithTimeout:-1 tag:TAG_RUNLOOP];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    [self.delegate connectionClosedWithError:err];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{

}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length] - 1)];
            NSString *msg = [[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding];
            if (msg)
            {
                [self.delegate dataReceived:data];
            }
            else
            {
                NSLog(@"Error converting received data into UTF-8 String");
            }
            [_socket readDataWithTimeout:-1 tag:TAG_RUNLOOP];
        }
    });    
}

@end
