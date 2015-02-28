//
//  ChatViewController.m
//  Sockets
//
//  Created by Ilya Tsarev on 27.02.15.
//  Copyright (c) 2015 Ilya Tsarev. All rights reserved.
//

#import "ChatViewController.h"

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
    [self initTextField];
}

- (void)initData{
    [ServerManager sharedInstance].delegate = self;
    _chatArray = [NSMutableArray array];
}

- (void)initTableView{
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;

    _tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 40, screenWidth, 235)];
        tableView.backgroundColor = [UIColor whiteColor];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView;
    });
    [self.view addSubview:_tableView];
}

- (void)initTextField{
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    
    _messageField = ({
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0,
                                                                               _tableView.frame.origin.y + _tableView.frame.size.height,
                                                                               screenWidth,
                                                                               40)];
        textField.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.2];
        textField.placeholder = @"Введите сообщение";
        textField.delegate = self;
        [textField becomeFirstResponder];
        textField;
    });
    [self.view addSubview:_messageField];
}

#pragma mark - Server manager delegate

- (void)dataReceived:(NSData *)data{
    NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length] - 1)];
    NSString *msg = [[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding];
    [_chatArray addObject:msg];

    [self scrollTableToBottom];
}

- (void)connectionClosedWithError:(NSError *)error{
    NSString *errorString = [error localizedDescription];
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Ошибка" message:errorString delegate:nil cancelButtonTitle:@"Закрыть" otherButtonTitles:nil];
    [self dismissViewControllerAnimated:YES completion:^{
        [av show];
    }];
}

#pragma mark - Actions

- (void)scrollTableToBottom{
    [_tableView reloadData];
    NSIndexPath* ipath = [NSIndexPath indexPathForRow:[_chatArray count]-1 inSection:0];
    [_tableView scrollToRowAtIndexPath: ipath atScrollPosition: UITableViewScrollPositionTop animated: YES];
}

- (void)sendMessage{
    [[ServerManager sharedInstance] sendMessage:_messageField.text];
    _messageField.text = @"";
}

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;    //count of section
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_chatArray count];    //count number of row from counting array hear cataGorry is An Array
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 30;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *MyIdentifier = @"MyIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
    }
    
    NSString *message = _chatArray[indexPath.row];
    if ([message hasPrefix:[NSString stringWithFormat:@"%@:", _userName]] == YES) {
        cell.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.5];
    } else {
        cell.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.5];
    }
    
    cell.textLabel.text = message;
    return cell;
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendMessage];
    return NO;
}

@end
