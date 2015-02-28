//
//  ViewController.m
//  Sockets
//
//  Created by Ilya Tsarev on 27.02.15.
//  Copyright (c) 2015 Ilya Tsarev. All rights reserved.
//

#import "ViewController.h"
#import "ServerManager.h"
#import "ChatViewController.h"

@interface ViewController ()

@property (nonatomic, strong) UITextField *nameTextField;
@property (nonatomic, strong) UIButton *loginButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self initUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Init

- (void)initUI{
    [self initNameField];
    [self initLoginButton];
}

- (void)initLoginButton{
    CGRect fieldFrame = _nameTextField.frame;
    
    _loginButton = ({
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(fieldFrame.origin.x + fieldFrame.size.width + 20,
                                                                      fieldFrame.origin.y + 10,
                                                                      60,
                                                                      fieldFrame.size.height - 10)];
        button.layer.borderColor = [UIColor blueColor].CGColor;
        button.layer.cornerRadius = 8.0f;
        button.layer.borderWidth = 1.0f;
        
        [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [button setTitle:@"Войти" forState:UIControlStateNormal];
        
        [button addTarget:self action:@selector(loginAction:) forControlEvents:UIControlEventTouchUpInside];
        
        button;
    });
    [self.view addSubview:_loginButton];
}

- (void)initNameField{
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;

    _nameTextField = ({
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(20, 100, screenWidth - 120, 40)];
        textField.placeholder = @"Введите свое имя";
        
        CALayer *bottomBorder = [CALayer layer];
        bottomBorder.frame = CGRectMake(0.0f, textField.frame.size.height - 1, textField.frame.size.width, 1.0f);
        bottomBorder.backgroundColor = [UIColor blueColor].CGColor;
        [textField.layer addSublayer:bottomBorder];
        
        textField;
    });
    [self.view addSubview:_nameTextField];
}

#pragma mark - Actions

- (void)loginAction:(id)sender{
    [self joinServerWithUser];
}

#pragma mark - Server

- (void)joinServerWithUser{
    NSString *nick = _nameTextField.text;
    
    [[ServerManager sharedInstance] initNetworkCommunication];
    [[ServerManager sharedInstance] joinChatWithUser:nick];
    
    ChatViewController *vc = [[ChatViewController alloc] init];
    vc.userName = nick;
    [self presentViewController:vc animated:YES completion:^{}];
}

@end
