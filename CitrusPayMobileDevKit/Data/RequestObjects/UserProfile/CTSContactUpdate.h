//
//  CTSContactUpdate.h
//  RestFulltester
//
//  Created by Yadnesh Wankhede on 12/06/14.
//  Copyright (c) 2014 Citrus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTSProfileLayerConstants.h"
#import "JSONModel.h"

@interface CTSContactUpdate : JSONModel
@property(nonatomic, strong) NSString* firstName, *lastName;
@property(nonatomic, strong) NSString* type;
@property(nonatomic, strong) NSString<Optional>* email;
@property(nonatomic, strong) NSString<Optional>* mobile;
@property(nonatomic, strong) NSString<Optional>* password;

@end
