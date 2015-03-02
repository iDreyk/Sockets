//
//  ChatViewController.m
//  Sockets
//
//  Created by Ilya Tsarev on 27.02.15.
//  Copyright (c) 2015 Ilya Tsarev. All rights reserved.
//

#import "ChatViewController.h"
#import "SPHTextBubbleCell.h"
#import <CoreData/CoreData.h>

@interface ChatViewController ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITextField *messageField;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIButton *logoutButton;
@property (nonatomic, strong) NSMutableArray *chatArray;

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    [self initData];
    [self initUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Init

- (void)initUI{
    [self initTableView];
    [self initBackButton];
    [self initTextField];
}

- (void)initData{
    [ServerManager sharedInstance].delegate = self;
    _chatArray = [NSMutableArray array];
    [self loadData];
}

- (void)initBackButton{
    UIImage *btnImage = [UIImage imageNamed:@"Close"];
    
    _logoutButton = ({
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 40, 22, 30, 30)];
        [button setImage:btnImage forState:UIControlStateNormal];
        [button addTarget:self action:@selector(logout) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.view addSubview:_logoutButton];
}

- (void)initTableView{
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;

    _tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 62, screenWidth, 213)];
        tableView.backgroundColor = [UIColor clearColor];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView;
    });
    [self.view addSubview:_tableView];
}

- (void)initTextField{
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    
    UIView *backgroundView = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                _tableView.frame.origin.y + _tableView.frame.size.height,
                                                                screenWidth,
                                                                40)];
        view.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.2];
        view;
    });
    [self.view addSubview:backgroundView];
    
    _messageField = ({
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(20,
                                                                               backgroundView.frame.origin.y,
                                                                               backgroundView.frame.size.width - 40,
                                                                               backgroundView.frame.size.height)];
        textField.placeholder = @"Введите сообщение";
        textField.delegate = self;
        [textField becomeFirstResponder];
        textField;
    });
    [self.view addSubview:_messageField];
}

#pragma mark - Core Data Methods

- (void)loadData{
    id delegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [delegate managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ChatData" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSError *error = [[NSError alloc] init];
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        [_chatArray addObject:@{@"message" : [info valueForKey:@"message"],
                                @"date"    : [info valueForKey:@"date"]}];
    }
    [_tableView reloadData];
}

- (void)saveMessage:(NSString *)message andDate:(NSDate *)date{
    id delegate = [[UIApplication sharedApplication] delegate];

    NSManagedObjectContext *managedObjectContext = [delegate managedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ChatData" inManagedObjectContext:managedObjectContext];
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:managedObjectContext];
        
    [newManagedObject setValue:date forKey:@"date"];
    [newManagedObject setValue:message forKey:@"message"];
        
    NSError *error = nil;
    if(![managedObjectContext save:&error]){
        NSLog(@"Unresolved error: %@, %@", error, [error userInfo]);
        abort();
    }
}

#pragma mark - Server manager delegate

- (void)dataReceived:(NSData *)data{
    NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length] - 1)];
    NSString *msg = [[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding];
    
    NSDate *date = [NSDate date];
    
    [_chatArray addObject:@{@"message" : msg,
                            @"date" : date}];

    [self saveMessage:msg andDate:date];
    [self scrollTableToBottom];
}

- (void)connectionClosedWithError:(NSError *)error{
    NSString *errorString = [error localizedDescription];
    [self logoutWithMessage:errorString];
}

#pragma mark - Actions

- (void)scrollTableToBottom{
    [_tableView reloadData];
    NSIndexPath* ipath = [NSIndexPath indexPathForRow:[_chatArray count]-1 inSection:0];
    [_tableView scrollToRowAtIndexPath:ipath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)sendMessage{
    [[ServerManager sharedInstance] sendMessage:_messageField.text];
    _messageField.text = @"";
}

- (void)logoutWithMessage:(NSString *)message{
    if (message != nil) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Ошибка" message:message delegate:nil cancelButtonTitle:@"Закрыть" otherButtonTitles:nil];
        [self dismissViewControllerAnimated:YES completion:^{
            [[ServerManager sharedInstance] disconnect];
            [av show];
        }];
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            [[ServerManager sharedInstance] disconnect];
        }];
    }
}

- (void)logout{
    [self logoutWithMessage:nil];
}

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_chatArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize labelSize =[_chatArray[indexPath.row][@"message"] boundingRectWithSize:CGSizeMake(tableView.frame.size.width, MAXFLOAT)
                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                        attributes:@{ NSFontAttributeName:[UIFont systemFontOfSize:14.0f] }
                                                           context:nil].size;
    return labelSize.height + 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellId = @"CellIdentifier";
    
    SPHTextBubbleCell *cell = (SPHTextBubbleCell *) [tableView dequeueReusableCellWithIdentifier:CellId];
    if (cell == nil)
    {
        cell = [[SPHTextBubbleCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellId];
    }
    NSString *message = _chatArray[indexPath.row][@"message"];
    
    NSDate *messageDate = _chatArray[indexPath.row][@"date"];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm.ss"];
    NSString *dateString = [formatter stringFromDate:messageDate];
    
    NSString *prefix = [NSString stringWithFormat:@"%@: ", _userName];
    
    if ([message hasPrefix:prefix] == YES) {
        cell.bubbletype = @"RIGHT";
        message = [message substringFromIndex:[prefix length]];
    } else {
        cell.bubbletype = @"LEFT";
    }
    cell.textLabel.text = message;
    cell.textLabel.tag = indexPath.row;
    cell.timestampLabel.text = dateString;

    return cell;
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendMessage];
    return NO;
}

@end
