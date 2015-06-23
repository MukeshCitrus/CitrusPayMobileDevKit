//
//  CTSBill.h
//  CTS iOS Sdk
//
//  Created by Yadnesh Wankhede on 21/11/14.
//  Copyright (c) 2014 Citrus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONModel.h"
#import "CTSAmount.h"
@interface CTSBill : JSONModel
@property(nonatomic)NSString *merchantTxnId;
@property(nonatomic)CTSAmount *amount;
@property(nonatomic)NSString *requestSignature;
@property(nonatomic)NSString *merchantAccessKey;
@property(nonatomic)NSString *returnUrl;
@property(nonatomic)NSString <Optional>*notifyUrl;


@end
