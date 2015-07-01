//
//  GetProfileRes.h
//  RestFulltester
//
//  Created by Yadnesh Wankhede on 04/06/14.
//  Copyright (c) 2014 Citrus. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GetProfileRes : NSObject
@property(nonatomic, strong) NSString* mobileMoneyId;
@property(nonatomic, strong) NSString* scheme;
@property(nonatomic, strong) NSString* token;
@property(nonatomic, strong) NSString* expiryDate;
@property(nonatomic, strong) NSString* name;
@property(nonatomic, strong) NSString* owner;
@property(nonatomic, strong) NSString* bank;
@property(nonatomic, strong) NSString* accountNumber;
@property(nonatomic, strong) NSString* impsRegisteredMobile;


@end
