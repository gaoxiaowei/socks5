//
//  ViewController.m
//  socks5-mac
//
//  Created by vincent on 2024/7/18.
//

#import "ViewController.h"
#include "TargetConditionals.h"
#include <ifaddrs.h>
#include <arpa/inet.h>

extern int socks_main(int argc, const char** argv);
const int port = 6886;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.statusLabel setStringValue:[NSString stringWithFormat:@"Socks5 Srv Running at %@:%d", [[self class] deviceIPAddress], port]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        char portbuf[32];
        sprintf(portbuf, "%d", port);
        const char *argv[] = {"microsocks", "-p", portbuf, NULL};
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
    NSNumber *proxyPort = @(port);
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

+ (NSString *)deviceIPAddress{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;

    NSString *networkInterface = @"en0";
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if( temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:networkInterface]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }

            temp_addr = temp_addr->ifa_next;
        }
    }

    // Free memory
    freeifaddrs(interfaces);

    return address;
}

@end
