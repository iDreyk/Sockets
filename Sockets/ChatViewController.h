//
//  ChatViewController.h
//  Sockets
//
//  Created by Ilya Tsarev on 27.02.15.
//  Copyright (c) 2015 Ilya Tsarev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServerManager.h"

@interface ChatViewController : UIViewController <ServerManagerDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, copy) NSString *userName;

@end
