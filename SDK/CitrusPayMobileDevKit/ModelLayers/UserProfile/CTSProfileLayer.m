//
//  CTSProfileLayer.m
//  RestFulltester
//
//  Created by Yadnesh Wankhede on 04/06/14.
//  Copyright (c) 2014 Citrus. All rights reserved.
//

#import "CTSProfileLayer.h"
#import "CTSProfileLayerConstants.h"
#import "CTSContactUpdate.h"
#import "CTSProfileContactRes.h"
#import "CTSAuthLayerConstants.h"
#import "CTSError.h"
#import "CTSOauthManager.h"
#import "CTSNewContactProfile.h"
#import "CTSNewUserProfileReq.h"
#import "CTSAuthLayer.h"

@implementation CTSProfileLayer
@synthesize delegate;

enum {
    ProfileGetContactReqId,
    ProfileUpdateContactReqId,
    ProfileGetPaymentReqId,
    ProfileUpdatePaymentReqId,
    ProfileGetBalanceReqId,
    ProfileActivatePrepaidAccountReqId,
    ProfileUpdateCashoutBankAccountReqId,
    ProfileGetCashoutBankAccountReqId,
    ProfileGetNewProfileReqId,
    ProfileUpdateMobileRequestId
};

- (instancetype)init {
    NSDictionary* dic = @{
                          toNSString(ProfileGetContactReqId) : toSelector(handleReqProfileGetContact:),
                          toNSString(ProfileUpdateContactReqId) : toSelector(handleProfileUpdateContact:),
                          toNSString(ProfileGetPaymentReqId) : toSelector(handleProfileGetPayment:),
                          toNSString(ProfileUpdatePaymentReqId) : toSelector(handleProfileUpdatePayment:),
                          toNSString(ProfileGetBalanceReqId) : toSelector(handleProfileGetBanlance:),
                          toNSString(ProfileActivatePrepaidAccountReqId) : toSelector(handleActivatePrepaidAccount:),
                          toNSString(ProfileUpdateCashoutBankAccountReqId) : toSelector(handleUpdateCashoutAccount:),
                          toNSString(ProfileGetCashoutBankAccountReqId) : toSelector(handleGetCashoutBankAccount:),
                          toNSString(ProfileGetNewProfileReqId) : toSelector(handleGetNewContactProfile:),
                          toNSString(ProfileUpdateMobileRequestId) : toSelector(handleProfileMobileUpdate:)
                          };
    
    self = [super initWithRequestSelectorMapping:dic
                                         baseUrl:CITRUS_PROFILE_BASE_URL];
    
    return self;
}

#pragma mark - class methods
- (void)updateContactInformation:(CTSContactUpdate*)contactInfo
           withCompletionHandler:(ASUpdateContactInfoCallBack)callback {
  [self addCallback:callback forRequestId:ProfileUpdateContactReqId];

  OauthStatus* oauthStatus = [CTSOauthManager fetchSigninTokenStatus];
  NSString* oauthToken = oauthStatus.oauthToken;

  if (oauthStatus.error != nil) {
    [self updateContactInfoHelper:oauthStatus.error];
    return;
  }

  CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
      initWithPath:MLC_PROFILE_UPDATE_CONTACT_PATH
         requestId:ProfileUpdateContactReqId
           headers:[CTSUtility readOauthTokenAsHeader:oauthToken]
        parameters:nil
              json:[contactInfo toJSONString]
        httpMethod:PUT];

  [restCore requestAsyncServer:request];
}

- (void)requestContactInformationWithCompletionHandler:
            (ASGetContactInfoCallBack)callback {
  [self addCallback:callback forRequestId:ProfileGetContactReqId];

  OauthStatus* oauthStatus = [CTSOauthManager fetchSigninTokenStatus];
  NSString* oauthToken = oauthStatus.oauthToken;

  if (oauthStatus.error != nil) {
    [self getContactInfoHelper:nil error:oauthStatus.error];

    return;
  }

  CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
      initWithPath:MLC_PROFILE_UPDATE_CONTACT_PATH
         requestId:ProfileGetContactReqId
           headers:[CTSUtility readOauthTokenAsHeader:oauthToken]
        parameters:nil
              json:nil
        httpMethod:GET];

  [restCore requestAsyncServer:request];
}

- (void)updatePaymentInformation:(CTSPaymentDetailUpdate*)paymentInfo
           withCompletionHandler:(ASUpdatePaymentInfoCallBack)callback {
  [self addCallback:callback forRequestId:ProfileUpdatePaymentReqId];

  OauthStatus* oauthStatus = [CTSOauthManager fetchBindSigninTokenStatus];
  NSString* oauthToken = oauthStatus.oauthToken;

    if (oauthStatus.error != nil) {
        oauthStatus = [CTSOauthManager fetchSigninTokenStatus];
        oauthToken = oauthStatus.oauthToken;
    }
    
  if (oauthStatus.error != nil || oauthToken == nil) {
    [self updatePaymentInfoHelper:oauthStatus.error];
    return;
  } else {
    CTSErrorCode error = [paymentInfo validate];
    if (error != NoError) {
      [self updatePaymentInfoHelper:[CTSError getErrorForCode:error]];
      return;
    }
  }

  [paymentInfo clearCVV];
  [paymentInfo clearNetbankCode];

  if (oauthStatus.error != nil) {
    [self updatePaymentInfoHelper:[CTSError getErrorForCode:UserNotSignedIn]];

    return;
  }

  CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
      initWithPath:MLC_PROFILE_UPDATE_PAYMENT_PATH
         requestId:ProfileUpdatePaymentReqId
           headers:[CTSUtility readOauthTokenAsHeader:oauthToken]
        parameters:nil
              json:[paymentInfo toJSONString]
        httpMethod:PUT];

  [restCore requestAsyncServer:request];
}

- (void)requestPaymentInformationWithCompletionHandler:
            (ASGetPaymentInfoCallBack)callback {
  [self addCallback:callback forRequestId:ProfileGetPaymentReqId];

  OauthStatus* oauthStatus = [CTSOauthManager fetchBindSigninTokenStatus];
  NSString* oauthToken = oauthStatus.oauthToken;

    
    if (oauthStatus.error != nil) {
        oauthStatus = [CTSOauthManager fetchSigninTokenStatus];
        oauthToken = oauthStatus.oauthToken;
    }
    
    
  if (oauthStatus.error != nil || oauthToken == nil ) {
    [self getPaymentInfoHelper:nil error:oauthStatus.error];
  }

  CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
      initWithPath:MLC_PROFILE_UPDATE_PAYMENT_PATH
         requestId:ProfileGetPaymentReqId
           headers:[CTSUtility readOauthTokenAsHeader:oauthToken]
        parameters:nil
              json:nil
        httpMethod:GET];

  [restCore requestAsyncServer:request];
}


-(void)requetGetBalance:(ASGetBalanceCallBack)calback{
    [self addCallback:calback forRequestId:ProfileGetBalanceReqId];

    OauthStatus* oauthStatus = [CTSOauthManager fetchBindSigninTokenStatus];
    NSString* oauthToken = oauthStatus.oauthToken;
    
    
    
    
    if (oauthStatus.error != nil) {
        oauthStatus = [CTSOauthManager fetchSigninTokenStatus];
        oauthToken = oauthStatus.oauthToken;
    }
    
    
    if (oauthStatus.error != nil || oauthToken == nil) {
        [self getBalanceHelper:nil error:oauthStatus.error];

    }
    CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
                                   initWithPath:MLC_PROFILE_GET_BALANCE_PATH
                                   requestId:ProfileGetBalanceReqId
                                   headers:[CTSUtility readOauthTokenAsHeader:oauthToken]
                                   parameters:nil
                                   json:nil
                                   httpMethod:POST];
    
    [restCore requestAsyncServer:request];
}

-(void)requestActivatePrepaidAccount:(ASActivatePrepaidCallBack)callback{
    [self addCallback:callback forRequestId:ProfileActivatePrepaidAccountReqId];

    OauthStatus* oauthStatus = [CTSOauthManager fetchBindSigninTokenStatus];
    NSString* oauthToken = oauthStatus.oauthToken;
    
    
    
    if (oauthStatus.error != nil) {
        oauthStatus = [CTSOauthManager fetchSigninTokenStatus];
        oauthToken = oauthStatus.oauthToken;
    }
    
    
    if (oauthStatus.error != nil || oauthToken == nil) {
        [self activatePrepaidHelper:NO error:oauthStatus.error];
    }
    
    CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
                                   initWithPath:MLC_PROFILE_GET_BALANCE_ACTIVATE_PATH
                                   requestId:ProfileActivatePrepaidAccountReqId
                                   headers:[CTSUtility readOauthTokenAsHeader:oauthToken]
                                   parameters:nil
                                   json:nil
                                   httpMethod:GET];
    
    [restCore requestAsyncServer:request];


}




- (void)requestUpdateCashoutBankAccount:(CTSCashoutBankAccount*)bankAccount
                  withCompletionHandler:(ASUpdateCashoutBankAccountCallback)callback{
    
    [self addCallback:callback forRequestId:ProfileUpdateCashoutBankAccountReqId];
    
    OauthStatus* oauthStatus = [CTSOauthManager fetchSigninTokenStatus];
    NSString* oauthToken = oauthStatus.oauthToken;
    
    if (oauthStatus.error != nil) {
        [self updateCashoutbankAccountHelper:oauthStatus.error];
    }

    CTSCashoutBankAccountResp* bankAccountData = [[CTSCashoutBankAccountResp alloc] init];
    bankAccountData.currency = CURRENCY;
    bankAccountData.type = @"prepaid";
    bankAccountData.cashoutAccount = bankAccount;
    
    CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
                                   initWithPath:MLC_PROFILE_CASHOUT_BANK_ACCOUNT_PATH
                                   requestId:ProfileUpdateCashoutBankAccountReqId
                                   headers:[CTSUtility readOauthTokenAsHeader:oauthToken]
                                   parameters:nil
                                   json:[bankAccountData toJSONString]
                                   httpMethod:PUT];
    
    [restCore requestAsyncServer:request];
    

}


-(void)requestCashoutBankAccountCompletionHandler:(ASGetCashoutBankAccountCallback)callback{
    [self addCallback:callback forRequestId:ProfileGetCashoutBankAccountReqId];
    
    OauthStatus* oauthStatus = [CTSOauthManager fetchSigninTokenStatus];
    NSString* oauthToken = oauthStatus.oauthToken;
    
    if (oauthStatus.error != nil) {
        [self updateCashoutbankAccountHelper:oauthStatus.error];
    }

    
    CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
                                   initWithPath:MLC_PROFILE_CASHOUT_BANK_ACCOUNT_PATH
                                   requestId:ProfileGetCashoutBankAccountReqId
                                   headers:[CTSUtility readOauthTokenAsHeader:oauthToken]
                                   parameters:nil
                                   json:nil
                                   httpMethod:GET];
    
    [restCore requestAsyncServer:request];


}

-(void)requestMemberInfoMobile:(NSString *)mobile email:(NSString *)email withCompletionHandler:(ASNewContactProfileCallback)callback{
    
    [self addCallback:callback forRequestId:ProfileGetNewProfileReqId];
    
    
    if (![CTSUtility validateEmail:email]) {
        [self getNewContactProfileHelper:nil error:[CTSError getErrorForCode:EmailNotValid]];
        return;
    }
    
    
    mobile = [CTSUtility mobileNumberToTenDigitIfValid:mobile];
    if (![CTSUtility validateMobile:mobile]) {
        [self getNewContactProfileHelper:nil
                   error:[CTSError getErrorForCode:MobileNotValid]];
        return;
    }
    
    
    
    
    OauthStatus* oauthStatus = [CTSOauthManager fetchSignupTokenStatus];
    NSString* oauthToken = oauthStatus.oauthToken;
    
    if (oauthStatus.error != nil) {
        [self getNewContactProfileHelper:nil error:oauthStatus.error];
    }
    
    CTSNewUserProfileReq  *profileReq = [[CTSNewUserProfileReq alloc] init];
    profileReq.mobile = mobile;
    profileReq.email = email;
    
    
    
    CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
                                   initWithPath:MLC_NEW_CONTACT_PROFILE_GET_PATH
                                   requestId:ProfileGetNewProfileReqId
                                   headers:[CTSUtility readOauthTokenAsHeader:oauthToken]
                                   parameters:nil
                                   json:[profileReq toJSONString]
                                   httpMethod:POST];
    
    [restCore requestAsyncServer:request];
    
    
}

// update mobile number
- (void)requestUpdateMobile:(NSString *)mobileNumber WithCompletionHandler:(ASUpdateMobileNumberCallback)callback{
    [self addCallback:callback forRequestId:ProfileUpdateMobileRequestId];
    
    
    mobileNumber = [CTSUtility mobileNumberToTenDigitIfValid:mobileNumber];
    if (![CTSUtility validateMobile:mobileNumber]) {
        [self updateMobileHelper:nil error:[CTSError getErrorForCode:MobileNotValid]];
        return;
    }
    
    OauthStatus* oauthStatus = [CTSOauthManager fetchSigninTokenStatus];
    NSString* oauthToken = oauthStatus.oauthToken;
    
    if (oauthStatus.error != nil) {
        oauthStatus = [CTSOauthManager fetchSigninTokenStatus];
        oauthToken = oauthStatus.oauthToken;
    }
    
    if (oauthStatus.error != nil || oauthToken == nil) {
        [self updateMobileHelper:nil error:oauthStatus.error];
    }
    
    CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
                                   initWithPath:MLC_PROFILE_UPDATE_MOBILE_PATH
                                   requestId:ProfileUpdateMobileRequestId
                                   headers:[CTSUtility readOauthTokenAsHeader:oauthToken]
                                   parameters:@{MLC_PROFILE_UPDATE_MOBILE_QUERY_MOBILE:mobileNumber}
                                   json:nil
                                   httpMethod:POST];
    
    [restCore requestAsyncServer:request];
}



#pragma mark - response handlers methods

- (void)handleReqProfileGetContact:(CTSRestCoreResponse*)response {
  NSError* error = response.error;
  JSONModelError* jsonError;
  CTSProfileContactRes* contact = nil;
  if (error == nil) {
    contact =
        [[CTSProfileContactRes alloc] initWithString:response.responseString
                                               error:&jsonError];
  }

  [self getContactInfoHelper:contact error:error];
}

- (void)handleProfileUpdateContact:(CTSRestCoreResponse*)response {
  [self updateContactInfoHelper:response.error];
}

- (void)handleProfileGetPayment:(CTSRestCoreResponse*)response {
  NSError* error = response.error;
  JSONModelError* jsonError;
  CTSProfilePaymentRes* paymentDetails = nil;

  if (error == nil) {
    paymentDetails =
        [[CTSProfilePaymentRes alloc] initWithString:response.responseString
                                               error:&jsonError];
    LogTrace(@"jsonError %@", jsonError);
  }
  [self getPaymentInfoHelper:paymentDetails error:error];
}

- (void)handleProfileUpdatePayment:(CTSRestCoreResponse*)response {
  [self updatePaymentInfoHelper:response.error];
}


-(void)handleProfileGetBanlance:(CTSRestCoreResponse*)response{
    NSError* error = response.error;
    JSONModelError* jsonError;
    CTSAmount* amount = nil;
    
    if(error == nil){
        amount = [[CTSAmount alloc] initWithString:response.responseString error:&jsonError];
    
    }
    
    [self getBalanceHelper:amount error:error];

}



-(void)handleActivatePrepaidAccount:(CTSRestCoreResponse *)response{
    NSError* error = response.error;
    JSONModelError* jsonError;
    CTSAmount* amount = nil;
    BOOL isActivated = NO;
    
    if(error == nil){
        amount = [[CTSAmount alloc] initWithString:response.responseString error:&jsonError];
        
    }
    if(amount != nil){
        
        isActivated = YES;
    }
    [self activatePrepaidHelper:isActivated error:error];
}


-(void)handleUpdateCashoutAccount:(CTSRestCoreResponse*)response{
    [self updateCashoutbankAccountHelper:response.error];

}

-(void)handleGetCashoutBankAccount:(CTSRestCoreResponse *)response{
    NSError* error = response.error;
    JSONModelError* jsonError;
    CTSCashoutBankAccountResp* cashoutAccount = nil;
    if(error == nil){
        cashoutAccount = [[CTSCashoutBankAccountResp alloc] initWithString:response.responseString error:&jsonError];
    }
    [self getCashoutAccountHelper:cashoutAccount error:error];

}

-(void)handleGetNewContactProfile:(CTSRestCoreResponse *)response{
    NSError* error = response.error;
    JSONModelError* jsonError;
    CTSNewContactProfile *profile = nil;
    
    if(error == nil){
        profile = [[CTSNewContactProfile alloc] initWithString:response.responseString error:&jsonError];
    }
    if(jsonError){
        error = jsonError;
    }
    
    
    [self getNewContactProfileHelper:profile error:error];
    
}


- (void)handleProfileMobileUpdate:(CTSRestCoreResponse*)response {
    NSError* error = response.error;
    JSONModelError* jsonError;
    CTSUpdateMobileNumberRes* updateMobileNumber = nil;
    if(error == nil){
        updateMobileNumber = [[CTSUpdateMobileNumberRes alloc] initWithString:response.responseString error:&jsonError];
    }
    [self updateMobileHelper:updateMobileNumber error:response.error];
}

#pragma mark - helper methods

- (void)updateContactInfoHelper:(NSError*)error {
  ASUpdateContactInfoCallBack callback =
      [self retrieveAndRemoveCallbackForReqId:ProfileUpdateContactReqId];
  if (callback != nil) {
    callback(error);
  } else {
    [delegate profile:self didUpdateContactInfoError:error];
  }
}

- (void)getContactInfoHelper:(CTSProfileContactRes*)contact
                       error:(NSError*)error {
  ASGetContactInfoCallBack callback =
      [self retrieveAndRemoveCallbackForReqId:ProfileGetContactReqId];

  if (callback != nil) {
    callback(contact, error);
  } else {
    [delegate profile:self didReceiveContactInfo:contact error:error];
  }
}

- (void)updatePaymentInfoHelper:(NSError*)error {
  ASUpdatePaymentInfoCallBack callback =
      [self retrieveAndRemoveCallbackForReqId:ProfileUpdatePaymentReqId];

  if (callback != nil) {
    callback(error);

  } else {
    [delegate profile:self didUpdatePaymentInfoError:error];
  }
}

- (void)getPaymentInfoHelper:(CTSProfilePaymentRes*)payment
                       error:(NSError*)error {
  ASGetPaymentInfoCallBack callback =
      [self retrieveAndRemoveCallbackForReqId:ProfileGetPaymentReqId];
  if (callback != nil) {
    callback(payment, error);

  } else {
    [delegate profile:self didReceivePaymentInformation:payment error:error];
  }
}

-(void)getBalanceHelper:(CTSAmount *)amount error:(NSError *)error{

    ASGetBalanceCallBack callback =
    [self retrieveAndRemoveCallbackForReqId:ProfileGetBalanceReqId];
    if (callback != nil) {
        callback(amount, error);
        
    } else {
        [delegate profile:self didGetBalance:amount error:error];
    }
}


-(void)activatePrepaidHelper:(BOOL )isActivated error:(NSError *)error{
    
    
    ASActivatePrepaidCallBack callback =
    [self retrieveAndRemoveCallbackForReqId:ProfileActivatePrepaidAccountReqId];
    if (callback != nil) {
        callback(isActivated, error);
    }
    
}



- (void)updateCashoutbankAccountHelper:(NSError*)error {
    ASUpdateCashoutBankAccountCallback callback =
    [self retrieveAndRemoveCallbackForReqId:ProfileUpdateCashoutBankAccountReqId];
    
    if (callback != nil) {
        callback(error);
        
    } else {
        [delegate profile:self didAddCashoutAccount:error];
    }
}


- (void)getCashoutAccountHelper:(CTSCashoutBankAccountResp *)cashoutBankResponse error:(NSError *)error{
    ASGetCashoutBankAccountCallback callback =
    [self retrieveAndRemoveCallbackForReqId:ProfileGetCashoutBankAccountReqId];
    
    if (callback != nil) {
        callback(cashoutBankResponse,error);
        
    } else {
        [delegate profile:self didReceiveCashoutAccount:cashoutBankResponse error:error];
    }
}


-(void)getNewContactProfileHelper:(CTSNewContactProfile *)profile error:(NSError *)error{
    ASNewContactProfileCallback callback = [self retrieveAndRemoveCallbackForReqId:ProfileGetNewProfileReqId];
    if (callback != nil) {
        callback(profile, error);
        
    } else {
        [delegate profile:self didGetNewProfile:profile error:error];
    }
}


-(void)updateMobileHelper:(CTSUpdateMobileNumberRes *)updateMobileNumber error:(NSError *)error{
    ASUpdateMobileNumberCallback callback = [self retrieveAndRemoveCallbackForReqId:ProfileUpdateMobileRequestId];
    if (callback != nil) {
        callback(updateMobileNumber, error);
    }
}

@end
