//
//  CTSPaymentLayer.m
//  RestFulltester
//
//  Created by Raji Nair on 19/06/14.
//  Copyright (c) 2014 Citrus. All rights reserved.
//
#import "CTSPaymentDetailUpdate.h"
#import "CTSContactUpdate.h"
#import "CTSPaymentLayer.h"
#import "CTSPaymentMode.h"
#import "CTSPaymentRequest.h"
#import "CTSAmount.h"
#import "CTSPaymentToken.h"
#import "CTSPaymentMode.h"
#import "CTSUserDetails.h"
#import "CTSUserAddress.h"
#import "CTSPaymentTransactionRes.h"
#import "CTSGuestCheckout.h"
#import "CTSPaymentNetbankingRequest.h"
#import "CTSTokenizedCardPayment.h"
#import "CTSUtility.h"
#import "CTSError.h"
#import "CTSProfileLayer.h"
#import "CTSAuthLayer.h"
#import "CTSRestCoreRequest.h"
#import "CTSUtility.h"
#import "CTSOauthManager.h"
#import "CTSTokenizedPaymentToken.h"
#import "CTSUserAddress.h"
#import "CTSCashoutToBankRes.h"
#import "PayLoadWebviewDto.h"
//#import "WebViewViewController.h"
//#import "UIUtility.h"
@interface CTSPaymentLayer ()
@end

@implementation CTSPaymentLayer
@synthesize merchantTxnId;
@synthesize signature;
@synthesize delegate,citrusCashBackViewController,paymentWebViewController;

- (CTSPaymentRequest*)configureReqPayment:(CTSPaymentDetailUpdate*)paymentInfo
                                  contact:(CTSContactUpdate*)contact
                                  address:(CTSUserAddress*)address
                                   amount:(NSString*)amount
                                returnUrl:(NSString*)returnUrl
                                notifyUrl:(NSString*)notifyUrl
                                signature:(NSString*)signatureArg
                                    txnId:(NSString*)txnId
                           merchantAccess:(NSString *)merchantAccessKey
                           withCustParams:(NSDictionary *)custParams
{
  CTSPaymentRequest* paymentRequest = [[CTSPaymentRequest alloc] init];
  paymentRequest.amount = [self ctsAmountForAmount:amount];
  paymentRequest.merchantAccessKey = merchantAccessKey;
  paymentRequest.merchantTxnId = txnId;
  paymentRequest.notifyUrl = notifyUrl;
  paymentRequest.requestSignature = signatureArg;
  paymentRequest.returnUrl = returnUrl;
  paymentRequest.paymentToken =
      [[paymentInfo.paymentOptions objectAtIndex:0] fetchPaymentToken];
    paymentRequest.customParameters = custParams;
    contact.email = contact.email.lowercaseString;
  paymentRequest.userDetails =
      [[CTSUserDetails alloc] initWith:contact address:address];
  return paymentRequest;
}


- (CTSAmount*)ctsAmountForAmount:(NSString*)amount {
  CTSAmount* ctsAmount = [[CTSAmount alloc] init];
  ctsAmount.value = amount;
  ctsAmount.currency = CURRENCY_INR;
  return ctsAmount;
}


- (void)requestChargeTokenizedPayment:(CTSPaymentDetailUpdate*)paymentInfo
                 withContact:(CTSContactUpdate*)contactInfo
                 withAddress:(CTSUserAddress*)userAddress
                        bill:(CTSBill *)bill
                         customParams:(NSDictionary *)custParams
       withCompletionHandler:(ASMakeTokenizedPaymentCallBack)callback{

    [self addCallback:callback forRequestId:PaymentUsingtokenizedCardBankReqId];
    
    CTSPaymentRequest* paymentrequest =
    [self configureReqPayment:paymentInfo
                      contact:contactInfo
                      address:userAddress
                       amount:bill.amount.value
                    returnUrl:bill.returnUrl
                    notifyUrl:bill.notifyUrl
                    signature:bill.requestSignature
                        txnId:bill.merchantTxnId
     merchantAccess:bill.merchantAccessKey
               withCustParams:custParams];

    
    CTSErrorCode error = [paymentInfo validateTokenized];
    LogTrace(@" validation error %d ", error);
    
    if (error != NoError) {
        [self makeTokenizedPaymentHelper:nil
                                   error:[CTSError getErrorForCode:error]];
        return;
    }
    if(![CTSUtility validateBill:bill]){
        [self makeTokenizedPaymentHelper:nil
                               error:[CTSError getErrorForCode:WrongBill]];
        return;
    }
    
    CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
                                   initWithPath:MLC_CITRUS_SERVER_URL
                                   requestId:PaymentUsingtokenizedCardBankReqId
                                   headers:nil
                                   parameters:nil
                                   json:[paymentrequest toJSONString]
                                   httpMethod:POST];
    [restCore requestAsyncServer:request];


}

- (void)requestChargePayment:(CTSPaymentDetailUpdate*)paymentInfo
                      withContact:(CTSContactUpdate*)contactInfo
                      withAddress:(CTSUserAddress*)userAddress
                             bill:(CTSBill *)bill
                customParams:(NSDictionary *)custParams
            withCompletionHandler:(ASMakeGuestPaymentCallBack)callback{

    [self addCallback:callback forRequestId:PaymentAsGuestReqId];
    
    if([paymentInfo.paymentOptions count] != 1){
        [self makeGuestPaymentHelper:nil
                               error:[CTSError getErrorForCode:NoOrMoreInstruments]];
        return;

    }
    CTSErrorCode error = [paymentInfo validate];
    
    [paymentInfo dummyCVVAndExpiryIfMaestro];
    
    LogTrace(@"validation error %d ", error);
    
    if (error != NoError) {
        [self makeGuestPaymentHelper:nil
                               error:[CTSError getErrorForCode:error]];
        return;
    }
    if(![CTSUtility validateBill:bill]){
        [self makeGuestPaymentHelper:nil
                               error:[CTSError getErrorForCode:WrongBill]];
        return;
    }
    
    CTSPaymentRequest* paymentrequest =
    [self configureReqPayment:paymentInfo
                      contact:contactInfo
                      address:userAddress
                       amount:bill.amount.value
                    returnUrl:bill.returnUrl
                    notifyUrl:bill.notifyUrl
                    signature:bill.requestSignature
                        txnId:bill.merchantTxnId
                  merchantAccess:bill.merchantAccessKey
                    withCustParams:custParams];

    
    CTSRestCoreRequest* request =
    [[CTSRestCoreRequest alloc] initWithPath:MLC_CITRUS_SERVER_URL
                                   requestId:PaymentAsGuestReqId
                                     headers:nil
                                  parameters:nil
                                        json:[paymentrequest toJSONString]
                                  httpMethod:POST];
    [restCore requestAsyncServer:request];



}



- (void)requestChargeCitrusCashWithContact:(CTSContactUpdate*)contactInfo
                               withAddress:(CTSUserAddress*)userAddress
                                      bill:(CTSBill *)bill
                              customParams:(NSDictionary *)custParams
                      returnViewController:(UIViewController *)controller
                     withCompletionHandler:(ASCitruspayCallback)callback{
    
    [self addCallback:callback forRequestId:PaymentAsCitruspayReqId];
    
    //vallidate
    //check if signed in if no then return error accordigly(from handler)
    //save controller
    //save callback
    //when the reply comesback
    //redirect it on web controller
    //from webcontroller keep detecting if verifypage has come if yes then reutrn for signin error
    //when webview controller returns with proper callback from ios get the reply back

    if(controller == nil){
        [self makeCitrusPayHelper:nil error:[CTSError getErrorForCode:NoViewController]];
        return;
    
    }
    if(![CTSUtility isCookieSetAlready]){
        [self makeCitrusPayHelper:nil error:[CTSError getErrorForCode:NoCookieFound]];
        return;
    
    }
    
        if(![CTSUtility validateBill:bill]){
        [self makeCitrusPayHelper:nil error:[CTSError getErrorForCode:WrongBill]];
        return;
        
    }
    
    
    
    citrusCashBackViewController = controller;
    cCashReturnUrl = bill.returnUrl;
    
    CTSProfileLayer *profileLayer = [[CTSProfileLayer alloc] init];
    [profileLayer requetGetBalance:^(CTSAmount *amount, NSError *error) {
        float balance = [amount.value floatValue];
        float txAmount = [bill.amount.value floatValue];
        if((balance *100) >= (txAmount*100)){
            [self requestChargeInternalCitrusCashWithContact:contactInfo withAddress:userAddress bill:bill customParams:custParams  withCompletionHandler:^(CTSPaymentTransactionRes *paymentInfo, NSError *error) {
                NSLog(@"paymentInfo %@",paymentInfo);
                NSLog(@"error %@",error);
                [self handlePaymentResponse:paymentInfo error:error] ;
            }];

        }
        else{
            [self makeCitrusPayHelper:nil error:[CTSError getErrorForCode:InsufficientBalance]];
        }
        
    }];
  
}



- (void)requestChargeInternalCitrusCashWithContact:(CTSContactUpdate*)contactInfo
                               withAddress:(CTSUserAddress*)userAddress
                                      bill:(CTSBill *)bill
                                      customParams:(NSDictionary *)custParams
                     withCompletionHandler:(ASMakeCitruspayCallBackInternal)callback{
    [self addCallback:callback forRequestId:PaymentAsCitruspayInternalReqId];
    NSString *email = contactInfo.email.lowercaseString;

    CTSPaymentDetailUpdate *paymentCitrus = [[CTSPaymentDetailUpdate alloc] initCitrusPayWithEmail:email];

    
    
    CTSPaymentRequest* paymentrequest =
    [self configureReqPayment:paymentCitrus
                      contact:contactInfo
                      address:userAddress
                       amount:bill.amount.value
                    returnUrl:bill.returnUrl
                    notifyUrl:bill.notifyUrl
                    signature:bill.requestSignature
                        txnId:bill.merchantTxnId
               merchantAccess:bill.merchantAccessKey
     withCustParams:custParams];
    

    
    CTSRestCoreRequest* request =
    [[CTSRestCoreRequest alloc] initWithPath:MLC_CITRUS_SERVER_URL
                                   requestId:PaymentAsCitruspayInternalReqId
                                     headers:nil
                                  parameters:nil
                                        json:[paymentrequest toJSONString]
                                  httpMethod:POST];
    [restCore requestAsyncServer:request];

}


- (void)requestLoadMoneyInCitrusPay:(CTSPaymentDetailUpdate *)paymentInfo
                        withContact:(CTSContactUpdate*)contactInfo
                                       withAddress:(CTSUserAddress*)userAddress
                                        amount:( NSString *)amount
                                     returnUrl:(NSString *)returnUrl
                       customParams:(NSDictionary *)custParams
withCompletionHandler:(ASLoadMoneyCallBack)callback{
    [self addCallback:callback forRequestId:PaymentLoadMoneyCitrusPayReqId];
    
    __block NSString *amountBlock = amount;
    
    
    if([paymentInfo.paymentOptions count] != 1){
        [self loadMoneyHelper:nil
                               error:[CTSError getErrorForCode:NoOrMoreInstruments]];
        return;
        
    }
    
    CTSErrorCode error = NoError;
    if([paymentInfo isTokenized]){
         error = [paymentInfo validateTokenized];
    }
    else{
    error = [paymentInfo validate];
    }
    
    [paymentInfo dummyCVVAndExpiryIfMaestro];
    
   // LogTrace(@"validation error %d ", error);
    
    if (error != NoError) {
        [self loadMoneyHelper:nil
                               error:[CTSError getErrorForCode:error]];
        return;
    }

    
    [self requestGetPrepaidBillForAmount:amount returnUrl:returnUrl withCompletionHandler:^(CTSPrepaidBill *prepaidBill, NSError *error) {
       
        if(error == nil){
        CTSPaymentRequest* paymentrequest =
        [self configureReqPayment:paymentInfo
                          contact:contactInfo
                          address:userAddress
                           amount:amountBlock
                        returnUrl:prepaidBill.returnUrl
                        notifyUrl:prepaidBill.notifyUrl
                        signature:prepaidBill.signature
                            txnId:prepaidBill.merchantTransactionId
                   merchantAccess:prepaidBill.merchantAccessKey
                   withCustParams:custParams];
        
        paymentrequest.notifyUrl = prepaidBill.notifyUrl;
        
        CTSRestCoreRequest* request =
        [[CTSRestCoreRequest alloc] initWithPath:MLC_CITRUS_SERVER_URL
                                       requestId:PaymentLoadMoneyCitrusPayReqId
                                         headers:nil
                                      parameters:nil
                                            json:[paymentrequest toJSONString]
                                      httpMethod:POST];
        [restCore requestAsyncServer:request];
        }
        else {
            [self loadMoneyHelper:nil error:error];
        }
    }];

    
}





- (void)requestMerchantPgSettings:(NSString*)vanityUrl
            withCompletionHandler:(ASGetMerchantPgSettingsCallBack)callback {
  [self addCallback:callback forRequestId:PaymentPgSettingsReqId];

  if (vanityUrl == nil) {
    [self getMerchantPgSettingsHelper:nil
                                error:[CTSError
                                          getErrorForCode:InvalidParameter]];
  }

  CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
      initWithPath:MLC_PAYMENT_GET_PGSETTINGS_PATH
         requestId:PaymentPgSettingsReqId
           headers:nil
        parameters:@{
          MLC_PAYMENT_GET_PGSETTINGS_QUERY_VANITY : vanityUrl
        } json:nil
        httpMethod:POST];
  [restCore requestAsyncServer:request];
}

-(void)requestGetPrepaidBillForAmount:(NSString *)amount returnUrl:(NSString *)returnUrl withCompletionHandler:(ASGetPrepaidBill)callback{

    [self addCallback:callback forRequestId:PaymentGetPrepaidBillReqId];
    
    
    OauthStatus* oauthStatus = [CTSOauthManager fetchSigninTokenStatus];
    NSString* oauthToken = oauthStatus.oauthToken;
    
    if (oauthStatus.error != nil) {
        [self getPrepaidBillHelper:nil error:oauthStatus.error];
        return;
    }
    
    if(returnUrl == nil){
        [self getPrepaidBillHelper:nil error:[CTSError
                                              getErrorForCode:ReturnUrlNotValid]];
    }

    if(amount == nil){
        [self getPrepaidBillHelper:nil error:[CTSError
                                              getErrorForCode:AmountNotValid]];
    
    }

    NSDictionary *params = @{MLC_PAYMENT_GET_PREPAID_BILL_QUERY_AMOUNT:amount,
                                MLC_PAYMENT_GET_PREPAID_BILL_QUERY_CURRENCY:MLC_PAYMENT_GET_PREPAID_BILL_QUERY_CURRENCY_INR,
                                MLC_PAYMENT_GET_PREPAID_BILL_QUERY_REDIRECT:returnUrl};

    CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
                                   initWithPath:MLC_PAYMENT_GET_PREPAID_BILL_PATH
                                   requestId:PaymentGetPrepaidBillReqId
                                   headers:[CTSUtility readOauthTokenAsHeader:oauthToken]
                                   parameters:params
                                   json:nil
                                   httpMethod:POST];
    [restCore requestAsyncServer:request];


}


#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)requestChargeTokenizedPayment:(CTSPaymentDetailUpdate*)paymentInfo
                          withContact:(CTSContactUpdate*)contactInfo
                          withAddress:(CTSUserAddress*)userAddress
                                 bill:(CTSBill *)bill
                         customParams:(NSDictionary *)custParams
                 returnViewController:(UIViewController *)controller
                withCompletionHandler:(ASCitruspayCallback)callback{
    
    
    [self addCallback:callback forRequestId:PaymentChargeInnerWeblTokenReqId];

    
    if(controller == nil || ![controller isKindOfClass:[UIViewController class]]){
        [self chargeTokenInnerWebviewHelper:nil error:[CTSError getErrorForCode:NoViewController]];
        return;
    }
    
//    if(citrusCashBackViewController){
//        [self chargeTokenInnerWebviewHelper:nil error:[CTSError getErrorForCode:TransactionAlreadyInProgress]];
//        return;
//    }
    
    citrusCashBackViewController = controller;

    
    [self requestChargeTokenizedPayment:paymentInfo withContact:contactInfo withAddress:userAddress bill:bill customParams:custParams withCompletionHandler:^(CTSPaymentTransactionRes *paymentInfo, NSError *error) {
        if(!error){
            
            BOOL hasSuccess =
            ((paymentInfo != nil) && ([paymentInfo.pgRespCode integerValue] == 0) &&
             (error == nil))
            ? YES
            : NO;
            if(hasSuccess){
                // Your code to handle success.
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (hasSuccess && error.code != ServerErrorWithCode) {
                        [self loadPaymentWebview:paymentInfo.redirectUrl reqId:PaymentChargeInnerWeblTokenReqId returnUrl:bill.returnUrl];
                    }else{
                        [self chargeTokenInnerWebviewHelper:nil error:[CTSError convertToError:paymentInfo]];
                    }
                });
            }
        }
        else {
            [self chargeTokenInnerWebviewHelper:nil error:error];
        }

    }];
    

}
#pragma GCC diagnostic pop



#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)requestChargePayment:(CTSPaymentDetailUpdate*)paymentInfo
                 withContact:(CTSContactUpdate*)contactInfo
                 withAddress:(CTSUserAddress*)userAddress
                        bill:(CTSBill *)bill
                customParams:(NSDictionary *)custParams
        returnViewController:(UIViewController *)controller
       withCompletionHandler:(ASCitruspayCallback)callback{
    [self addCallback:callback forRequestId:PaymentChargeInnerWebNormalReqId];
    //add callback
    //do validation
    if(controller == nil || ![controller isKindOfClass:[UIViewController class]]){
        [self chargeNormalInnerWebviewHelper:nil error:[CTSError getErrorForCode:NoViewController]];
        return;
    }
    
//    if(citrusCashBackViewController){
//        [self chargeNormalInnerWebviewHelper:nil error:[CTSError getErrorForCode:TransactionAlreadyInProgress]];
//        return;
//    }
    
    
    citrusCashBackViewController = controller;
    
    
    [self requestChargePayment:paymentInfo withContact:contactInfo withAddress:userAddress bill:bill customParams:custParams withCompletionHandler:^(CTSPaymentTransactionRes *paymentInfo, NSError *error) {
        if(!error){
            
            BOOL hasSuccess =
            ((paymentInfo != nil) && ([paymentInfo.pgRespCode integerValue] == 0) &&
             (error == nil))
            ? YES
            : NO;
                // Your code to handle success.
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (hasSuccess && error.code != ServerErrorWithCode) {
                        [self loadPaymentWebview:paymentInfo.redirectUrl reqId:PaymentChargeInnerWebNormalReqId returnUrl:bill.returnUrl];
                    }
                    else{
                        [self chargeNormalInnerWebviewHelper:nil error:[CTSError convertToError:paymentInfo]];
                    }
                });
        }
        else {
            [self chargeNormalInnerWebviewHelper:nil error:error];
        }
    }];
    
}
#pragma GCC diagnostic pop

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)requestLoadMoneyInCitrusPay:(CTSPaymentDetailUpdate *)paymentInfo
                        withContact:(CTSContactUpdate*)contactInfo
                        withAddress:(CTSUserAddress*)userAddress
                             amount:( NSString *)amount
                          returnUrl:(NSString *)returnUrl
                       customParams:(NSDictionary *)custParams
               returnViewController:(UIViewController *)controller
              withCompletionHandler:(ASCitruspayCallback)callback{

    [self addCallback:callback forRequestId:PaymentChargeInnerWebLoadMoneyReqId];
    //add callback
    //do validation
    
    
    if(controller == nil || ![controller isKindOfClass:[UIViewController class]]){
        [self chargeLoadMoneyInnerWebviewHelper:nil error:[CTSError getErrorForCode:NoViewController]];
        return;
    }
    
//    if(citrusCashBackViewController){
//    
//        [self chargeLoadMoneyInnerWebviewHelper:nil error:[CTSError getErrorForCode:TransactionAlreadyInProgress]];
//        return;
//    }

    
    
    citrusCashBackViewController = controller;
    
    
    
    
    [self requestLoadMoneyInCitrusPay:paymentInfo withContact:contactInfo withAddress:userAddress amount:amount returnUrl:returnUrl  customParams:custParams withCompletionHandler:^(CTSPaymentTransactionRes *paymentInfo, NSError *error) {
        if(!error){
            
            BOOL hasSuccess =
            ((paymentInfo != nil) && ([paymentInfo.pgRespCode integerValue] == 0) &&
             (error == nil))
            ? YES: NO;
            if(hasSuccess){
                // Your code to handle success.
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (hasSuccess && error.code != ServerErrorWithCode) {
                        //[self loadPaymentWebview:<#(PayLoadWebviewDto *)#>];
                        
                        [self loadPaymentWebview:paymentInfo.redirectUrl reqId:PaymentChargeInnerWebLoadMoneyReqId returnUrl:returnUrl];
                    }else{
                        [self chargeLoadMoneyInnerWebviewHelper:nil error:[CTSError convertToError:paymentInfo]];
                    }
                });
            }
        }
        else {
            [self chargeLoadMoneyInnerWebviewHelper:nil error:error];
        }
    }];
    
}
#pragma GCC diagnostic pop



-(void)requestCashoutToBank:(CTSCashoutBankAccount *)bankAccount amount:(NSString *)amount completionHandler:(ASCashoutToBankCallBack)callback{

    [self addCallback:callback forRequestId:PaymentCashoutToBankReqId];
    
    
    OauthStatus* oauthStatus = [CTSOauthManager fetchSigninTokenStatus];
    NSString* oauthToken = oauthStatus.oauthToken;
    
    if (oauthStatus.error != nil) {
        [self cashoutToBankHelper:nil error:oauthStatus.error];
        return;
    }
    
    if(bankAccount == nil){
        [self cashoutToBankHelper:nil error:[CTSError
                                             getErrorForCode:BankAccountNotValid]];

    }
    
    if(amount == nil){
        [self getPrepaidBillHelper:nil error:[CTSError
                                              getErrorForCode:AmountNotValid]];
        
    }
    
    NSDictionary *params = @{MLC_CASHOUT_QUERY_AMOUNT:amount,
                             MLC_CASHOUT_QUERY_CURRENCY:MLC_CASHOUT_QUERY_CURRENCY_INR,
                             MLC_CASHOUT_QUERY_ACCOUNT:bankAccount.number,
                             MLC_CASHOUT_QUERY_IFSC:bankAccount.branch,
                             MLC_CASHOUT_QUERY_OWNER:bankAccount.owner
                             };
    
    CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
                                   initWithPath:MLC_CASHOUT_PATH
                                   requestId:PaymentCashoutToBankReqId
                                   headers:[CTSUtility readOauthTokenAsHeader:oauthToken]
                                   parameters:params
                                   json:nil
                                   httpMethod:POST];
    [restCore requestAsyncServer:request];

}


-(void)requestGetPGHealthWithCompletionHandler:(ASGetPGHealth)callback{
    [self addCallback:callback forRequestId:PGHealthReqId];
    
    CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
                                   initWithPath:MLC_PGHEALTH_PATH
                                   requestId:PGHealthReqId
                                   headers:nil
                                   parameters:@{MLC_PGHEALTH_QUERY_BANKCODE:MLC_PGHEALTH_QUERY_ALLBANKS}
                                   json:nil
                                   httpMethod:POST];
    [restCore requestAsyncServer:request];
}


#pragma mark - authentication protocol mehods
- (void)signUp:(BOOL)isSuccessful
    accessToken:(NSString*)token
          error:(NSError*)error {
  if (isSuccessful) {
  }
}


- (instancetype)init {
    finished = YES;
    NSDictionary* dict = [self getRegistrationDict];
    self = [super initWithRequestSelectorMapping:dict
                                       baseUrl:CITRUS_PAYMENT_BASE_URL];
  return self;
}

-(NSDictionary *)getRegistrationDict{
    return @{
             toNSString(PaymentAsGuestReqId) : toSelector(handleReqPaymentAsGuest:),
             toNSString(PaymentUsingtokenizedCardBankReqId) : toSelector(handleReqPaymentUsingtokenizedCardBank:),
             toNSString(PaymentUsingSignedInCardBankReqId) : toSelector(handlePaymentUsingSignedInCardBank:),
             toNSString(PaymentPgSettingsReqId) : toSelector(handleReqPaymentPgSettings:),
             toNSString(PaymentAsCitruspayInternalReqId) : toSelector(handlePayementUsingCitruspayInternal:),
             toNSString(PaymentAsCitruspayReqId) : toSelector(handlePayementUsingCitruspay:),
             toNSString(PaymentGetPrepaidBillReqId) : toSelector(handleGetPrepaidBill:),
             toNSString(PaymentLoadMoneyCitrusPayReqId) : toSelector(handleLoadMoneyCitrusPay:),
             toNSString(PaymentCashoutToBankReqId) : toSelector(handleCashoutToBank:),
             toNSString(PaymentChargeInnerWebNormalReqId) : toSelector(handleChargeNormalInnerWebview:),
             toNSString(PaymentChargeInnerWeblTokenReqId) : toSelector(handleChargeTokenInnerWebview:),
             toNSString(PaymentChargeInnerWebLoadMoneyReqId) : toSelector(handleChargeLoadMoneyInnerWebview:),
             toNSString(PGHealthReqId) : toSelector(handlePGHealthResponse:)
             };
}


- (instancetype)initWithUrl:(NSString *)url
{
    
    if(url == nil){
        url = CITRUS_PAYMENT_BASE_URL;
    }
    self = [super initWithRequestSelectorMapping:[self getRegistrationDict]
                                         baseUrl:url];
    return self;
}



#pragma mark - response handlers methods


-(void)handleGetPrepaidBill:(CTSRestCoreResponse *)response{
    NSError* error = response.error;
    JSONModelError* jsonError;
    CTSPrepaidBill* bill = nil;
    if (error == nil) {
        bill =
        [[CTSPrepaidBill alloc] initWithString:response.responseString
                                                   error:&jsonError];
        
    }
    
    [self getPrepaidBillHelper:bill error:error];

}



- (void)handleReqPaymentAsGuest:(CTSRestCoreResponse*)response {
  NSError* error = response.error;
  JSONModelError* jsonError;
  CTSPaymentTransactionRes* payment = nil;
  if (error == nil) {
    payment =
        [[CTSPaymentTransactionRes alloc] initWithString:response.responseString
                                                   error:&jsonError];

    //    [delegate payment:self
    //        didMakePaymentUsingGuestFlow:resultObject
    //                               error:error];
  }
  [self makeGuestPaymentHelper:payment error:error];
}

- (void)handleReqPaymentUsingtokenizedCardBank:(CTSRestCoreResponse*)response {
  NSError* error = response.error;
  JSONModelError* jsonError;
  CTSPaymentTransactionRes* payment = nil;
  if (error == nil) {
    NSLog(@"error:%@", jsonError);
    payment =
        [[CTSPaymentTransactionRes alloc] initWithString:response.responseString
                                                   error:&jsonError];
  }
  [self makeTokenizedPaymentHelper:payment error:error];
}

- (void)handlePaymentUsingSignedInCardBank:(CTSRestCoreResponse*)response {
  NSError* error = response.error;
  JSONModelError* jsonError;
  CTSPaymentTransactionRes* payment = nil;
  if (response.indexData > -1) {
    CTSPaymentDetailUpdate* paymentDetail =
        [self fetchAndRemoveDataFromCache:response.indexData];
    __block CTSProfileLayer* profile = [[CTSProfileLayer alloc] init];
    [profile updatePaymentInformation:paymentDetail
                withCompletionHandler:^(NSError* error) {
                    LogTrace(@" error %@ ", error);
                }];

    payment =
        [[CTSPaymentTransactionRes alloc] initWithString:response.responseString
                                                   error:&jsonError];
  }
  [self makeUserPaymentHelper:payment error:error];
}


-(void)handleLoadMoneyCitrusPay:(CTSRestCoreResponse *)response {
    
    NSError* error = response.error;
    JSONModelError* jsonError;
    CTSPaymentTransactionRes* payment = nil;
    if (error == nil) {
        NSLog(@"error:%@", jsonError);
        payment =
        [[CTSPaymentTransactionRes alloc] initWithString:response.responseString
                                                   error:&jsonError];
    }
    [self loadMoneyHelper:payment error:error];
    
}

-(void)handlePayementUsingCitruspayInternal:(CTSRestCoreResponse*)response  {

    NSError* error = response.error;
    JSONModelError* jsonError;
    CTSPaymentTransactionRes* payment = nil;
    if (error == nil) {
        NSLog(@"error:%@", jsonError);
        payment =
        [[CTSPaymentTransactionRes alloc] initWithString:response.responseString
                                                   error:&jsonError];
    }
    [self makeCitrusPayInternalHelper:payment error:error];



}

-(void)handlePayementUsingCitruspay:(CTSRestCoreResponse*)response  {
    
    //call back view controller
    // or delegate
    //reset view controller and callback
    
    
    
    
}



- (void)handleReqPaymentPgSettings:(CTSRestCoreResponse*)response {
  NSError* error = response.error;
  JSONModelError* jsonError;
  CTSPgSettings* pgSettings = nil;
  if (error == nil) {
    pgSettings = [[CTSPgSettings alloc] initWithString:response.responseString
                                                 error:&jsonError];
  }
  [self getMerchantPgSettingsHelper:pgSettings error:error];
}

- (void)handleCashoutToBank:(CTSRestCoreResponse*)response {
    NSError* error = response.error;
    JSONModelError* jsonError;
    CTSCashoutToBankRes* cashoutBankRes = nil;
    if (error == nil) {
        cashoutBankRes = [[CTSCashoutToBankRes alloc] initWithString:response.responseString
                                                     error:&jsonError];
    }
    [self cashoutToBankHelper:cashoutBankRes error:error];
}

-(void)handlePaymentResponse:(CTSPaymentTransactionRes *)paymentInfo error:(NSError *)error{
    
    BOOL hasSuccess =
    ((paymentInfo != nil) && ([paymentInfo.pgRespCode integerValue] == 0) &&
     (error == nil))
    ? YES
    : NO;
    if(hasSuccess){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadCitrusCashPaymentWebview:paymentInfo.redirectUrl];
        });
        
    }
    else{
        //TODO: add the helper call
        [self makeCitrusPayHelper:nil error:[CTSError convertToError:paymentInfo]];
        
    }
}


- (void)handleChargeNormalInnerWebview:(CTSRestCoreResponse*)response {}
- (void)handleChargeTokenInnerWebview:(CTSRestCoreResponse*)response {}
- (void)handleChargeLoadMoneyInnerWebview:(CTSRestCoreResponse*)response {}


- (void)handlePGHealthResponse:(CTSRestCoreResponse*)response {
    NSError* error = response.error;
    CTSPGHealthRes* pgHealthRes = nil;
    if (error == nil) {
        pgHealthRes = [[CTSPGHealthRes alloc] init];
        NSDictionary *responseDict =  [NSJSONSerialization JSONObjectWithData: [response.responseString dataUsingEncoding:NSUTF8StringEncoding]
                                                                    options: NSJSONReadingMutableContainers
                                                                      error: &error];
        
        pgHealthRes.responseDict = [NSMutableDictionary dictionaryWithDictionary:responseDict];

    }
    [self pgHealthHelper:pgHealthRes error:error];
}




#pragma mark - helper methods
- (void)makeUserPaymentHelper:(CTSPaymentTransactionRes*)payment
                        error:(NSError*)error {
  ASMakeUserPaymentCallBack callback = [self
      retrieveAndRemoveCallbackForReqId:PaymentUsingSignedInCardBankReqId];

  if (callback != nil) {
    callback(payment, error);
  } else {
    [delegate payment:self didMakeUserPayment:payment error:error];
  }
}

- (void)makeTokenizedPaymentHelper:(CTSPaymentTransactionRes*)payment
                             error:(NSError*)error {
  ASMakeTokenizedPaymentCallBack callback = [self
      retrieveAndRemoveCallbackForReqId:PaymentUsingtokenizedCardBankReqId];
  if (callback != nil) {
    callback(payment, error);
  } else {
    [delegate payment:self didMakeTokenizedPayment:payment error:error];
  }
}

- (void)makeGuestPaymentHelper:(CTSPaymentTransactionRes*)payment
                         error:(NSError*)error {
  ASMakeGuestPaymentCallBack callback =
      [self retrieveAndRemoveCallbackForReqId:PaymentAsGuestReqId];
  if (callback != nil) {
    callback(payment, error);
  } else {
    [delegate payment:self didMakePaymentUsingGuestFlow:payment error:error];
  }
}

-(void)makeCitrusPayInternalHelper:(CTSPaymentTransactionRes*)payment
                     error:(NSError*)error{

    ASMakeCitruspayCallBackInternal callback =
    [self retrieveAndRemoveCallbackForReqId:PaymentAsCitruspayInternalReqId];
    if (callback != nil) {
        callback(payment, error);
    } 

}
- (void)loadMoneyHelper:(CTSPaymentTransactionRes*)payment
                        error:(NSError*)error {
    ASLoadMoneyCallBack callback = [self
                                          retrieveAndRemoveCallbackForReqId:PaymentLoadMoneyCitrusPayReqId];
    
    if (callback != nil) {
        callback(payment, error);
    } else {
        [delegate payment:self didLoadMoney:payment error:error];
    }
}


-(void)makeCitrusPayHelper:(CTSCitrusCashRes*)paymentRes
                             error:(NSError*)error{
    
    ASCitruspayCallback callback =
    [self retrieveAndRemoveCallbackForReqId:PaymentAsCitruspayReqId];
    
    if (callback != nil) {
        callback(paymentRes, error);
    }
    else{
        [delegate payment:self
             didPaymentCitrusCash:paymentRes
                    error:error];
    }
    [self resetCitrusPay];
}



- (void)getMerchantPgSettingsHelper:(CTSPgSettings*)pgSettings
                              error:(NSError*)error {
  ASGetMerchantPgSettingsCallBack callback =
      [self retrieveAndRemoveCallbackForReqId:PaymentPgSettingsReqId];
  if (callback != nil) {
    callback(pgSettings, error);
  } else {
    [delegate payment:self didRequestMerchantPgSettings:pgSettings error:error];
  }
}


-(void)cashoutToBankHelper:(CTSCashoutToBankRes *)cashoutToBankRes error:(NSError *)error{
    ASCashoutToBankCallBack callback = [self retrieveAndRemoveCallbackForReqId:PaymentCashoutToBankReqId];
    if (callback != nil) {
        callback(cashoutToBankRes, error);
    } else {
        [delegate payment:self didCashoutToBank:cashoutToBankRes error:error ];
    }
    
}

-(void)getPrepaidBillHelper:(CTSPrepaidBill*)bill
                     error:(NSError*)error{
    
    ASGetPrepaidBill callback =
    [self retrieveAndRemoveCallbackForReqId:PaymentGetPrepaidBillReqId];
    
    if (callback != nil) {
        callback(bill, error);
    }
    else{
        [delegate payment:self
     didGetPrepaidBill:bill error:error];
    }
}

- (void)chargeNormalInnerWebviewHelper:(CTSCitrusCashRes*)response error:(NSError *)error {
    [self resetCitrusPay];
ASCitruspayCallback  callback  = [self retrieveAndRemoveCallbackForReqId:PaymentChargeInnerWebNormalReqId];
        if (callback != nil) {
        callback(response, error);
    }
    else{
        //TODO:DELEGATE CALLBACK
    }
}

- (void)chargeTokenInnerWebviewHelper:(CTSCitrusCashRes*)response error:(NSError *)error {
    [self resetCitrusPay];

    ASCitruspayCallback  callback  = [self retrieveAndRemoveCallbackForReqId:PaymentChargeInnerWeblTokenReqId];
    
    if (callback != nil) {
        callback(response, error);
    }
    else{
        //TODO:DELEGATE CALLBACK
    }

}
- (void)chargeLoadMoneyInnerWebviewHelper:(CTSCitrusCashRes*)response  error:(NSError *)error{
    NSLog(@" chargeLoadMoneyInnerWebviewHelper ");
    LogThread
    [self resetCitrusPay];


    ASCitruspayCallback  callback  = [self retrieveAndRemoveCallbackForReqId:PaymentChargeInnerWebLoadMoneyReqId];
    
    if (callback != nil) {
        callback(response, error);
    }
    else{
        //TODO:DELEGATE CALLBACK
    }

}


//
- (void)pgHealthHelper:(CTSPGHealthRes*)pgHealthRes error:(NSError*)error {
    ASGetPGHealth callback = [self retrieveAndRemoveCallbackForReqId:PGHealthReqId];
    if (callback != nil) {
        callback(pgHealthRes, error);
    }
}

-(void)resetCitrusPay{

    if( [citrusPayWebview isLoading]){
        [citrusPayWebview stopLoading];
    }
    [citrusPayWebview removeFromSuperview];
    citrusPayWebview.delegate = nil;
    citrusPayWebview = nil;
    citrusCashBackViewController = nil;
    cCashReturnUrl = nil;
}






#pragma mark -  CitrusPayWebView

- (void)webViewDidStartLoad:(UIWebView*)webView {
    NSLog(@"webViewDidStartLoad ");
}


-(void)loadCitrusCashPaymentWebview:(NSString *)url{

    citrusPayWebview = [[UIWebView alloc] init];
    citrusPayWebview.delegate = self;
    [citrusCashBackViewController.view addSubview:citrusPayWebview];
    [citrusPayWebview loadRequest:[[NSURLRequest alloc]
                               initWithURL:[NSURL URLWithString:url]]];
}


- (void)webViewDidFinishLoad:(UIWebView*)webView {
    NSLog(@"did finish loading");

    NSDictionary *responseDict = [CTSUtility getResponseIfTransactionIsComplete:webView];
    NSString *webviewUrl = [[[webView request] URL] absoluteString];
    NSLog(@"currentURL %@",webviewUrl);
    responseDict = [CTSUtility errorResponseIfReturnUrlDidntRespond:cCashReturnUrl webViewUrl:webviewUrl currentResponse:responseDict];
    
    if(responseDict){
        CTSCitrusCashRes *response = [[CTSCitrusCashRes alloc] init];
        response.responseDict = [NSMutableDictionary dictionaryWithDictionary:responseDict];
        NSError *error = [CTSUtility extractError:response.responseDict];
        [self makeCitrusPayHelper:response error:error];
    }
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    NSLog(@"request url %@",[request URL]);
    
    NSArray* cookies =
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[request URL]];
    NSLog(@"cookie array:%@", cookies);
    if([CTSUtility isVerifyPage:[[request URL] absoluteString]]){
            [self makeCitrusPayHelper:nil
                            error:[CTSError getErrorForCode:UserNotSignedIn]];
    
    }
    return YES;
}


- (void)makeUserPayment:(CTSPaymentDetailUpdate*)paymentInfo
            withContact:(CTSContactUpdate*)contactInfo
            withAddress:(CTSUserAddress*)userAddress
                 amount:(NSString*)amount
          withReturnUrl:(NSString*)returnUrl
          withSignature:(NSString*)signature
              withTxnId:(NSString*)merchantTxnId
  withCompletionHandler:(ASMakeUserPaymentCallBack)callback{}


/**
 *  called when client request to make a tokenized payment
 *
 *  @param paymentInfo Payment Information
 *  @param contactInfo contact Information
 *  @param amount      payment amount
 */
- (void)makeTokenizedPayment:(CTSPaymentDetailUpdate*)paymentInfo
                 withContact:(CTSContactUpdate*)contactInfo
                 withAddress:(CTSUserAddress*)userAddress
                      amount:(NSString*)amount
               withReturnUrl:(NSString*)returnUrl
               withSignature:(NSString*)signature
                   withTxnId:(NSString*)merchantTxnId
       withCompletionHandler:(ASMakeTokenizedPaymentCallBack)callback{}

- (void)makePaymentUsingGuestFlow:(CTSPaymentDetailUpdate*)paymentInfo
                      withContact:(CTSContactUpdate*)contactInfo
                           amount:(NSString*)amount
                      withAddress:(CTSUserAddress*)userAddress
                    withReturnUrl:(NSString*)returnUrl
                    withSignature:(NSString*)signature
                        withTxnId:(NSString*)merchantTxnId
            withCompletionHandler:(ASMakeGuestPaymentCallBack)callback{}


-(void)loadPaymentWebview:(NSString *)url reqId:(int)reqId returnUrl:(NSString *)returnUrl{
        //dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@" loadPaymentWebview ");
            LogThread
        if(paymentWebViewController != nil){
            [self removeObserver:self forKeyPath:@"paymentWebViewController.response"];
            [paymentWebViewController finishWebView];
        }
        paymentWebViewController = [[CTSPaymentWebViewController alloc] init];
        [self addObserver:self forKeyPath:@"paymentWebViewController.response" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        paymentWebViewController.redirectURL = url;
        paymentWebViewController.reqId = reqId;
        paymentWebViewController.returnUrl = returnUrl ;
        NSLog(@"citrusCashBackViewController.navigationController %@",citrusCashBackViewController.navigationController);
        [citrusCashBackViewController.navigationController pushViewController:paymentWebViewController animated:YES];
   // });
}


-(void)loadPaymentWebview:(PayLoadWebviewDto *)loadWebview{
        NSLog(@" loadPaymentWebview ");
        LogThread
        if(paymentWebViewController != nil){
            [self removeObserver:self forKeyPath:@"paymentWebViewController.response"];
            [paymentWebViewController finishWebView];
        }
        paymentWebViewController = [[CTSPaymentWebViewController alloc] init];
        [self addObserver:self forKeyPath:@"paymentWebViewController.response" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        paymentWebViewController.redirectURL = loadWebview.url;
        paymentWebViewController.reqId = loadWebview.reqId;
        paymentWebViewController.returnUrl = loadWebview.returnUrl ;
        NSLog(@"citrusCashBackViewController.navigationController %@",citrusCashBackViewController.navigationController);
        [citrusCashBackViewController.navigationController pushViewController:paymentWebViewController animated:YES];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    NSLog(@" observeValueForKeyPath ");
    LogThread
    for(NSString *keys in change){
        NSLog(@"Checking key %@, Value %@",keys,[change valueForKey:keys]);
    }
    
    CTSCitrusCashRes *response = [[CTSCitrusCashRes alloc] init];
    response.responseDict =  [NSMutableDictionary dictionaryWithDictionary:[change valueForKey:@"new"]];
    int toIntReqId = [CTSUtility extractReqId:response.responseDict];
    NSError *error = [CTSUtility extractError:response.responseDict];
    
    [paymentWebViewController.navigationController popViewControllerAnimated:YES];
    [self removeObserver:self forKeyPath:@"paymentWebViewController.response"];
    paymentWebViewController=nil;
    citrusCashBackViewController = nil;
    if(error){
        response = nil;
    }
    switch (toIntReqId) {
        case PaymentChargeInnerWebNormalReqId:
            [self chargeNormalInnerWebviewHelper:response error:error];
            break;
        case PaymentChargeInnerWeblTokenReqId:
            [self chargeTokenInnerWebviewHelper:response error:error];
            break;
        case PaymentChargeInnerWebLoadMoneyReqId:
            [self chargeLoadMoneyInnerWebviewHelper:response error:error];
            break;
        default:
            break;
    }
}


@end
