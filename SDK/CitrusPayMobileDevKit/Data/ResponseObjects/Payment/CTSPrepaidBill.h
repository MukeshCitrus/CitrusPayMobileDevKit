//
//  CTSPrepaidBill.h
//  CTS iOS Sdk
//
//  Created by Yadnesh Wankhede on 03/03/15.
//  Copyright (c) 2015 Citrus. All rights reserved.
//

#import "JSONModel.h"
#import "CTSAmount.h"

@interface CTSPrepaidBill : JSONModel
@property(nonatomic,strong) NSString *merchantTransactionId;
@property(nonatomic,strong) NSString *merchant;
@property(nonatomic,strong) NSString *customer;
@property(nonatomic,strong) NSString *description;
@property(nonatomic,strong) NSString *signature;
@property(nonatomic,strong) NSString *merchantAccessKey;
@property(nonatomic,strong) NSString *returnUrl;
@property(nonatomic,strong) NSString *notifyUrl;
@property(nonatomic,strong) CTSAmount *amount;

@end
