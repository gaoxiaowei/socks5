//
//  WebBrowserViewController.m
//  SOCKS
//
//  Created by vincent on 2024/7/19.
//  Copyright © 2024 Robert Xiao. All rights reserved.
//

#import "WebBrowserViewController.h"

@interface WebBrowserViewController ()<WKNavigationDelegate, UITextFieldDelegate>
@property(nonatomic, copy) NSString*socks5Host;
@property(nonatomic, copy) NSString*socks5Port;
@end

@implementation WebBrowserViewController

-(instancetype)initWithSocks5Proxy:(NSString*)socks5Host socks5Port:(int)socks5Port{
    self = [super init];
    if (self) {
        self.socks5Host = socks5Host;
        self.socks5Port = [NSString stringWithFormat:@"%d", socks5Port];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.urlField = [[UITextField alloc] initWithFrame:CGRectMake(10, 40, self.view.frame.size.width - 20, 30)];
    self.urlField.borderStyle = UITextBorderStyleRoundedRect;
    self.urlField.delegate = self;
    self.urlField.placeholder = @"Enter URL";
    self.urlField.keyboardType = UIKeyboardTypeURL;
    self.urlField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.urlField.returnKeyType = UIReturnKeyGo;
    [self.view addSubview:self.urlField];

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    nw_endpoint_t socks5_endpoint = nw_endpoint_create_host(self.socks5Host.UTF8String, self.socks5Port.UTF8String);
    if (@available(iOS 17.0, *)) {
        nw_proxy_config_t proxy_config = nw_proxy_config_create_socksv5(socks5_endpoint);
        config.websiteDataStore.proxyConfigurations =@[proxy_config];
    } else {
        // Fallback on earlier versions
    }

    CGFloat yOffset = CGRectGetMaxY(self.urlField.frame) + 10;
    self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, yOffset, self.view.frame.size.width, self.view.frame.size.height - yOffset) configuration:config];
    self.webView.navigationDelegate = self;

    [self.view addSubview:self.webView];

    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    NSURL *url = [NSURL URLWithString:@"https://www.apple.com"];
    [self loadURL:url];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"Finished loading");
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"Failed to load with error: %@", error.localizedDescription);
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.urlField) {
        [textField resignFirstResponder];
        NSURL *url = [NSURL URLWithString:textField.text];
        if (url.scheme.length == 0) {
            url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", textField.text]];
        }
        [self loadURL:url];
        return NO;
    }
    return YES;
}

#pragma mark - Helper Methods

- (void)loadURL:(NSURL *)url {
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

@end
