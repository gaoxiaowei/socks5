//
//  ViewController.m
//  socks5-mac
//
//  Created by vincent on 2024/7/18.
//

#import "ViewController.h"
#import "AppDelegate.h"

extern int socks_main(int argc, const char** argv);

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    int port = 4884;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        char portbuf[32];
        sprintf(portbuf, "%d", port);
        const char *argv[] = {"microsocks", "-p", portbuf, NULL};

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.statusLabel setStringValue:[NSString stringWithFormat:@"Socks5 Srv Running at %@:%d", [AppDelegate deviceIPAddress], port]];
        });

        int status = socks_main(3, argv);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.statusLabel setStringValue:[NSString stringWithFormat:@"Socks5 Srv Failed to start: %d", status]];
        });
    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self testHttpRequest];
    });
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

-(void)testHttpRequest{
    NSURL *url = [NSURL URLWithString:@"https://raw.githubusercontent.com/gaoxiaowei/relay_proxy_test/master/relay_config.json"];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];

    NSString *proxyHost = @"localhost";
    NSNumber *proxyPort = @4884;
//   NSString *proxyHost = @"10.17.24.245";
//   NSNumber *proxyPort = @1082;
    NSDictionary *proxyDict = @{
        (NSString *)kCFNetworkProxiesSOCKSEnable : @1,
        (NSString *)kCFNetworkProxiesSOCKSProxy: proxyHost,
        (NSString *)kCFNetworkProxiesSOCKSPort: proxyPort,
        (NSString *)kCFStreamPropertySOCKSVersion : (NSString *)kCFStreamSocketSOCKSVersion5
//        (NSString *)kCFNetworkProxiesHTTPEnable  :@1,
//        (NSString *)kCFNetworkProxiesHTTPProxy  : proxyHost,
//        (NSString *)kCFNetworkProxiesHTTPPort  : proxyPort,
//        (NSString *)kCFNetworkProxiesHTTPSEnable  :@1,
//        (NSString *)kCFNetworkProxiesHTTPSProxy  : proxyHost,
//        (NSString *)kCFNetworkProxiesHTTPSPort  : proxyPort,
    };

    configuration.connectionProxyDictionary = proxyDict;


    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];

    NSURLSessionDataTask *task = [session dataTaskWithURL:url
                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", [error localizedDescription]);
        } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSLog(@"Response status code: %ld", (long)[httpResponse statusCode]);
            NSLog(@"Data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self testHttpRequest];
        });
    }];

    [task setValue:proxyDict
            forKey:@"_proxySettings"];

    [task resume];
}
@end
