//
//  CTSNetBankingUpdate.h
//  RestFulltester
//
//  Created by Yadnesh Wankhede on 19/06/14.
//  Copyright (c) 2014 Citrus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTSProfileLayerConstants.h"
#import "CTSObject.h"

@interface CTSNetBankingUpdate : CTSObject
@property(strong, nonatomic, readonly) NSString* type;
@property(strong, nonatomic) NSString* name;
@property(strong, nonatomic) NSString* bank;
@property(strong, nonatomic) NSString* code;
@property(strong, nonatomic) NSString* token;
@property(strong, nonatomic) NSString* issuerCode;

@end
