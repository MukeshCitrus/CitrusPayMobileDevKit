//
//  SampleViewController.h
//  CitrusPayMobileSampleApp
//
//  Created by Mukesh Patil on 13/07/15.
//  Copyright (c) 2015 CitrusPay. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CitrusSdk.h"

@interface SampleViewController : UIViewController{
    CTSAuthLayer *authLayer;
    CTSProfileLayer *proifleLayer;
    CTSPaymentLayer *paymentLayer;
    CTSContactUpdate* contactInfo;
    CTSUserAddress* addressInfo;
    int seedState;
    NSDictionary *customParams;
}
@end

