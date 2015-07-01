//
//  CTSRestPluginBase.m
//  CTSRestKit
//
//  Created by Yadnesh Wankhede on 30/07/14.
//  Copyright (c) 2014 CitrusPay. All rights reserved.
//

#import "CTSRestPluginBase.h"
#import "CTSRestError.h"
#import "CTSOauthManager.h"
#import "CTSAuthLayerConstants.h"

@implementation CTSRestPluginBase
@synthesize requestBlockCallbackMap;
- (instancetype)initWithRequestSelectorMapping:(NSDictionary*)mapping
                                       baseUrl:(NSString*)baseUrl {
  self = [super init];
  if (self) {
    restCore = [[CTSRestCore alloc] initWithBaseUrl:baseUrl];
    restCore.delegate = self;
    requestSelectorMap = mapping;

    requestBlockCallbackMap = [[NSMutableDictionary alloc] init];
    dataCache = [[NSMutableDictionary alloc] init];
    if (self != [CTSRestPluginBase class] &&
        ![self conformsToProtocol:@protocol(CTSRestCoreDelegate)]) {
      @throw
          [[NSException alloc] initWithName:@"UnImplimented Protocol"
                                     reason:@"CTSRestCoreDelegate - not adopted"
                                   userInfo:nil];
    }
  }
  return self;
}

- (void)restCore:(CTSRestCore*)restCore
    didReceiveResponse:(CTSRestCoreResponse*)response {
  SEL sel = [[requestSelectorMap
      valueForKey:toNSString(response.requestId)] pointerValue];

  if ([self respondsToSelector:sel]) {
    if (response.error != nil) {
      response = [self addJsonErrorToResponse:response];
    }

      [self performSelector:sel onThread:[NSThread currentThread] withObject:response waitUntilDone:YES];
  } else {
    @throw [[NSException alloc]
        initWithName:@"No Selector Found"
              reason:[NSString stringWithFormat:@"method %@ | NOT FOUND",
                                                NSStringFromSelector(sel)]
            userInfo:nil];
  }
}





- (CTSRestCoreResponse*)addJsonErrorToResponse:(CTSRestCoreResponse*)response {
  JSONModelError* jsonError = nil;
  NSError* serverError = response.error;
  CTSRestError* error;
  error = [[CTSRestError alloc] initWithString:response.responseString
                                         error:&jsonError];
  if (error != nil) {
    if (error.type != nil) {
      error.error = error.type;
    } else {
      error.type = error.error;
    }
      
      if(error.errorDescription == nil){
          error.errorDescription = error.description;
      }
      else{
    error.description = error.errorDescription;
    }
  } else {
    error = [[CTSRestError alloc] init];
  }

  error.serverResponse = response.responseString;

    NSString *newDes;
    if(error.errorDescription != nil){
        newDes =error.errorDescription;
    }
    else {
        newDes =[[serverError userInfo] valueForKey:NSLocalizedDescriptionKey];
    
    }
    
    
    
  NSDictionary* userInfo = @{
    CITRUS_ERROR_DESCRIPTION_KEY : error,
    NSLocalizedDescriptionKey :newDes
        
  };
  response.error = [NSError errorWithDomain:CITRUS_ERROR_DOMAIN
                                       code:[serverError code]
                                   userInfo:userInfo];
  return response;
}

- (void)addCallback:(id)callBack forRequestId:(int)reqId {
  if (callBack != nil)
    [self.requestBlockCallbackMap setObject:[callBack copy]
                                     forKey:toNSString(reqId)];
}

- (id)retrieveAndRemoveCallbackForReqId:(int)reqId {
  id callback = [self.requestBlockCallbackMap objectForKey:toNSString(reqId)];
  [self.requestBlockCallbackMap removeObjectForKey:toNSString(reqId)];
  return callback;
}

- (void)addData:(id)object atCacheIndex:(long)index {
  [dataCache setValue:object forKey:toLongNSString(index)];
}
- (id)fetchDataFromCache:(long)index {
  return [dataCache valueForKey:toLongNSString(index)];
}
- (id)fetchAndRemoveDataFromCache:(long)index {
  id object = [self fetchDataFromCache:index];
  [dataCache removeObjectForKey:toLongNSString(index)];
  return object;
}

- (long)addDataToCacheAtAutoIndex:(id)object {
  long index = [self getNewIndex];
  [self addData:object atCacheIndex:index];
  return index;
}

- (long)getNewIndex {
  return cacheId++;
}

@end
