//
//  CTSPaymentRequest.h
//  RestFulltester
//
//  Created by Raji Nair on 24/06/14.
//  Copyright (c) 2014 Citrus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTSAmount.h"
#import "CTSPaymentToken.h"
#import "CTSUserDetails.h"
#import "JSONModel.h"
@interface CTSPaymentRequest : JSONModel
@property(nonatomic, strong) CTSAmount* amount;
@property(strong) NSString<Optional>* merchantAccessKey;
@property(strong) NSString<Optional>* merchantTxnId;
@property(strong) NSString<Optional>* notifyUrl;
@property(strong) NSString<Optional>* requestSignature;
@property(strong) NSString<Optional>* returnUrl;
@property(nonatomic, strong) CTSPaymentToken* paymentToken;
@property(nonatomic, strong) CTSUserDetails* userDetails;
@property(nonatomic, strong) NSDictionary<Optional>* customParameters;

@end
