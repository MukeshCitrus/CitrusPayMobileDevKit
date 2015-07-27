//
//  WebGatewayViewController.h
//  CitrusPay-iOS-SDK-Sample-App
//
//  Created by Mukesh Patil on 19/06/15.
//  Copyright (c) 2015 CitrusPay. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebGatewayViewController : UIViewController <UIWebViewDelegate>
@property(nonatomic,strong) NSString *redirectURL;
@end
