//
//  CTSRestError.h
//  RestFulltester
//
//  Created by Yadnesh Wankhede on 29/05/14.
//  Copyright (c) 2014 Citrus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONModel.h"
@interface CTSRestError : JSONModel

@property(nonatomic,strong)NSString<Optional>*errorDescription;
@property(nonatomic,strong)NSString<Optional>*description;
@property(nonatomic, strong) NSString<Optional>* error;
@property(nonatomic, strong) NSString<Optional>* type;
@property(nonatomic, strong) NSString<Ignore>* serverResponse;

@end
