//
//  CTSTokenizedPayment.h
//  RestFulltester
//
//  Created by Yadnesh Wankhede on 24/06/14.
//  Copyright (c) 2014 Citrus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTSObject.h"

@interface CTSTokenizedPayment : CTSObject
@property(strong, nonatomic, readonly) NSString* type;
@property(strong, nonatomic) NSString* token, *cvv;

- (instancetype)initWithToken:(NSString*)tokenArg cvv:(NSString*)cvvArg;

@end
