//
//  WebGatewayViewController.m
//  CitrusPay-iOS-SDK-Sample-App
//
//  Created by Mukesh Patil on 19/06/15.
//  Copyright (c) 2015 CitrusPay. All rights reserved.
//

#import "WebGatewayViewController.h"
#import "CTSUtility.h"
#import "UIUtility.h"
#import "TestParams.h"

@interface WebGatewayViewController ()
@property(nonatomic,strong) UIWebView *webview;
@property(nonatomic,strong) UIActivityIndicatorView* indicator;
@end

@implementation WebGatewayViewController
@synthesize redirectURL;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"3D Secure";
    self.webview = [[UIWebView alloc] init];
    self.webview.delegate = self;
    self.webview.frame = self.view.frame;
    self.webview.backgroundColor = [UIColor redColor];
    self.indicator = [[UIActivityIndicatorView alloc]
                 initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.indicator.frame = CGRectMake(160, 300, 30, 30);
    [self.view addSubview:self.webview];
    [self.webview addSubview:self.indicator];
    
    
    [self.webview loadRequest:[[NSURLRequest alloc]
                               initWithURL:[NSURL URLWithString:redirectURL]]];

}

#pragma mark - webview delegates

- (void)webViewDidStartLoad:(UIWebView*)webView {
    NSLog(@"webView %@",[webView.request URL].absoluteString);
    [self.indicator startAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView*)webView {
    [self.indicator stopAnimating];
    
    //for payment proccessing return url finish
    NSDictionary *responseDict = [CTSUtility getResponseIfTransactionIsComplete:webView];
    if(responseDict){
        //responseDict> contains all the information related to transaction
        [self transactionComplete:responseDict];
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    NSLog(@"request url %@ scheme %@",[request URL],[[request URL] scheme]);
    
    //for load balance return url finish
    NSArray *loadMoneyResponse = [CTSUtility getLoadResponseIfSuccesfull:request];
    NSLog(@"loadMoneyResponse %@",loadMoneyResponse);
    if(loadMoneyResponse){
        LogTrace(@"loadMoneyResponse %@",loadMoneyResponse);
        
        [self loadMoneyComplete:loadMoneyResponse];
    }
    
    return YES;
}



-(void)transactionComplete:(NSDictionary *)responseDictionary{
    if([responseDictionary valueForKey:@"TxStatus"] != nil){
        [UIUtility toastMessageOnScreen:[NSString stringWithFormat:@" transaction complete\n txStatus: %@",[responseDictionary valueForKey:@"TxStatus"] ]];
    }
    else{
        [UIUtility toastMessageOnScreen:[NSString stringWithFormat:@" transaction complete\n Response: %@",responseDictionary]];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
    [self finishWebView];
}


-(void)loadMoneyComplete:(NSArray *)resPonseArray{
    [UIUtility toastMessageOnScreen:[NSString stringWithFormat:@" load Money Complete\n Response: %@",resPonseArray]];
    [self.navigationController popViewControllerAnimated:YES];
}


-(void)finishWebView{
    
    if( [self.webview isLoading]){
        [self.webview stopLoading];
    }
    [self.webview removeFromSuperview];
    self.webview.delegate = nil;
    self.webview = nil;
}


@end
