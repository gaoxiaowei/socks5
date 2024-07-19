//
//  WebBrowserViewController.h
//  SOCKS
//
//  Created by vincent on 2024/7/19.
//  Copyright © 2024 Robert Xiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WebBrowserViewController : UIViewController
@property (strong, nonatomic) WKWebView *webView;
@property (strong, nonatomic) UITextField *urlField;

-(instancetype)initWithSocks5Proxy:(NSString*)socks5Host socks5Port:(int)socks5Port;
@end

NS_ASSUME_NONNULL_END
