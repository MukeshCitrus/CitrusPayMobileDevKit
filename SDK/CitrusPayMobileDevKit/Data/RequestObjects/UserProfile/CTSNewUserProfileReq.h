//
//  CTSNewUserProfileReq.h
//  CTS iOS Sdk
//
//  Created by Yadnesh Wankhede on 30/03/15.
//  Copyright (c) 2015 Citrus. All rights reserved.
//

#import "JSONModel.h"

@interface CTSNewUserProfileReq : JSONModel
@property(nonatomic, strong) NSString<Optional>* email;
@property(nonatomic, strong) NSString<Optional>* mobile;
@end
