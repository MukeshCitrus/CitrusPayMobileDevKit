//
//  SubcriptionRes.m
//  RestFulltester
//
//  Created by Yadnesh Wankhede on 14/05/14.
//  Copyright (c) 2014 Citrus. All rights reserved.
//

#import "CTSOauthTokenRes.h"
#import "CTSAuthLayerConstants.h"

@implementation CTSOauthTokenRes
@synthesize accessToken, tokenType, tokenExpiryTime, scope, refreshToken,
    tokenSaveDate;
- (NSString*)description {
  return [NSString
      stringWithFormat:
          @"accessToken %@ \n tokenType %@ \n tokenExpiryTime %ld \nscope %@",
          accessToken,
          tokenType,
          tokenExpiryTime,
          scope];
};

- (void)encodeWithCoder:(NSCoder*)encoder {
  // Encode properties, other class variables, etc
  [encoder encodeObject:self.accessToken forKey:MLC_SIGNUP_ACCESS_OAUTH_TOKEN];
  [encoder encodeObject:self.tokenType forKey:MLC_OAUTH_TYPE];
  [encoder encodeObject:self.scope forKey:MLC_OAUTH_SCOPE];
  [encoder encodeObject:self.refreshToken forKey:MLC_SIGNIN_REFRESH_TOKEN];
  [encoder encodeObject:self.tokenSaveDate forKey:MLC_OAUTH_TOKEN_SAVE_DATE];
  [encoder encodeObject:[NSNumber numberWithLong:self.tokenExpiryTime]
                 forKey:MLC_TOKEN_EXPIRY];
}

- (id)initWithCoder:(NSCoder*)decoder {
  if ((self = [super init])) {
    // decode properties, other class vars
    self.accessToken =
        [decoder decodeObjectForKey:MLC_SIGNUP_ACCESS_OAUTH_TOKEN];
    self.tokenType = [decoder decodeObjectForKey:MLC_OAUTH_TYPE];
    self.scope = [decoder decodeObjectForKey:MLC_OAUTH_SCOPE];
    self.refreshToken = [decoder decodeObjectForKey:MLC_SIGNIN_REFRESH_TOKEN];
    self.tokenSaveDate = [decoder decodeObjectForKey:MLC_OAUTH_TOKEN_SAVE_DATE];
    NSNumber* number = [decoder decodeObjectForKey:MLC_TOKEN_EXPIRY];
    self.tokenExpiryTime = [number longValue];
  }
  return self;
}

//+ (JSONKeyMapper*)keyMapper {
//  return [JSONKeyMapper mapperFromUnderscoreCaseToCamelCase];
//}

+ (JSONKeyMapper*)keyMapper {
  return [[JSONKeyMapper alloc] initWithDictionary:@{
    @"access_token" : @"accessToken",
    @"token_type" : @"tokenType",
    @"expires_in" : @"tokenExpiryTime",
    @"refresh_token" : @"refreshToken",
    @"scope" : @"scope"
  }];
}
@end
