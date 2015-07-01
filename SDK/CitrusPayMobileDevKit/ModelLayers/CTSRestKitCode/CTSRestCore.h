//
//  CTSRestCore.h
//  CTSRestKit
//
//  Created by Yadnesh Wankhede on 29/07/14.
//  Copyright (c) 2014 CitrusPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTSRestCoreRequest.h"
#import "CTSRestCoreResponse.h"
#import "CTSRestCoreConstants.h"
#import "CTSError.h"
#import "UserLogging.h"

@class CTSRestCore;
@protocol CTSRestCoreDelegate
- (void)restCore:(CTSRestCore*)restCore
    didReceiveResponse:(CTSRestCoreResponse*)response;
@end

@interface CTSRestCore : NSObject{
    int delegationRequestId;
    BOOL finished;
}
@property(strong, nonatomic) NSString* baseUrl;
@property(weak) id<CTSRestCoreDelegate> delegate;
- (instancetype)initWithBaseUrl:(NSString*)url;
- (void)requestAsyncServer:(CTSRestCoreRequest*)restRequest;
+ (CTSRestCoreResponse*)requestSyncServer:(CTSRestCoreRequest*)restRequest
                              withBaseUrl:(NSString*)baseUrl;
+ (NSString*)serializeParams:(NSDictionary*)params ;
-(void)requestAsyncServerDelegation:(CTSRestCoreRequest *)restRequest;
@end
