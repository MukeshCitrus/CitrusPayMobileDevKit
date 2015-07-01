//
//  CTSProfileContactRes.h
//  RestFulltester
//
//  Created by Yadnesh Wankhede on 13/06/14.
//  Copyright (c) 2014 Citrus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONModel.h"

@interface CTSProfileContactRes : JSONModel
@property(nonatomic, strong) NSString* type, *firstName, *lastName, *email,
    *mobile;

@end
