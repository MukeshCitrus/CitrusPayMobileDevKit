//
//  CTSResponse.h
//  CTS iOS Sdk
//
//  Created by Yadnesh Wankhede on 21/05/15.
//  Copyright (c) 2015 Citrus. All rights reserved.
//

#import "JSONModel.h"

@interface CTSResponse : JSONModel
@property(strong,nonatomic)NSString *responseCode;
@property(strong,nonatomic)NSString *responseMessage;
@property(strong , nonatomic)NSDictionary *responseData;

-(BOOL)isError;
-(int)errorCode;
@end
