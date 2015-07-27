//
//  SampleViewController.m
//  CitrusPayMobileSampleApp
//
//  Created by Mukesh Patil on 13/07/15.
//  Copyright (c) 2015 CitrusPay. All rights reserved.
//

#import "SampleViewController.h"
#import "TestParams.h"
#import "UIUtility.h"
#import "WebGatewayViewController.h"

#warning Enter your Keys & URLs here

// Keys
#define SignInId @"citrus-cube-mobile-app"
#define SignInSecretKey @"bd63aa06f797f73966f4bcaa4bba00fe"
#define SubscriptionId @"citrus-native-mobile-subscription"
#define SubscriptionSecretKey @"3e2288d3a1a3f59ef6f93373884d2ca1"

// URLs
#define VanityUrl @"nativeSDK"
#define ReturnUrl @"http://localhost:8888/redirectURL.php"
#define BillUrl @"http://localhost:8888/billGenerator.php"
#define BaseUrl @"https://sandboxadmin.citruspay.com"

@implementation SampleViewController
#define toErrorDescription(error) [error.userInfo objectForKey:NSLocalizedDescriptionKey]

#pragma mark - initializers
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializeLayers];
    self.title = @"CitrusPay iOS Native Payment SDK Kit";
    
//    [self deleteCard];
}

-(void)initializeLayers{
    authLayer = [[CTSAuthLayer alloc] initWithBaseURLAndDynamicVanityOauthKeysURLs:BaseUrl vanityUrl:VanityUrl signInId:SignInId signInSecretKey:SignInSecretKey subscriptionId:SubscriptionId subscriptionSecretKey:SubscriptionSecretKey returnUrl:ReturnUrl];
    proifleLayer = [[CTSProfileLayer alloc] init];
    paymentLayer = [[CTSPaymentLayer alloc] init];
    
    contactInfo = [[CTSContactUpdate alloc] init];
    contactInfo.firstName = TEST_FIRST_NAME;
    contactInfo.lastName = TEST_LAST_NAME;
    contactInfo.email = TEST_EMAIL;
    contactInfo.mobile = TEST_MOBILE;
    
    addressInfo = [[CTSUserAddress alloc] init];
    addressInfo.city = @"Mumbai";
    addressInfo.country = @"India";
    addressInfo.state = @"Maharashtra";
    addressInfo.street1 = @"Golden Road";
    addressInfo.street2 = @"Pink City";
    addressInfo.zip = @"401209";
    
    customParams = @{@"USERDATA2":@"MOB_RC|9988776655",
                     @"USERDATA10":@"test",
                     @"USERDATA4":@"MOB_RC|test@gmail.com",
                     @"USERDATA3":@"MOB_RC|4111XXXXXXXX1111",
                     };
}


#pragma mark - button handlers

-(IBAction)isUserSignedIn:(id)sender{
    if([authLayer isAnyoneSignedIn]){
        [UIUtility toastMessageOnScreen:@"user is signed in"];
    }
    else{
        [UIUtility toastMessageOnScreen:@"no one is logged in"];
    }
}

-(IBAction)linkUser:(id)sender{
    
    [authLayer requestLinkUser:TEST_EMAIL mobile:TEST_MOBILE completionHandler:^(CTSLinkUserRes *linkUserRes, NSError *error) {
        if (error) {
            [UIUtility toastMessageOnScreen:[error localizedDescription]];
        }
        else{
            [UIUtility toastMessageOnScreen:[NSString stringWithFormat:@"User is now Linked, %@",linkUserRes.message]];
        }
    }];
}

-(IBAction)setPassword:(id)sender{
    
    [authLayer requestSetPassword:TEST_PASSWORD userName:TEST_EMAIL completionHandler:^(NSError *error) {
        if (error) {
            [UIUtility toastMessageOnScreen:[error localizedDescription]];
        }
        else{
            [UIUtility toastMessageOnScreen:[NSString stringWithFormat:@"Password is now set"]];
        }
    }];
    
}

-(IBAction)forgotPassword:(id)sender{
    [authLayer requestResetPassword:TEST_EMAIL completionHandler:^(NSError *error) {
        if (error) {
            [UIUtility toastMessageOnScreen:[error localizedDescription]];
        }
        else{
            [UIUtility toastMessageOnScreen:[NSString stringWithFormat:@"reset link sent to email address"]];
        }
    }];
}

-(IBAction)signin:(id)sender{
    
    [authLayer requestSigninWithUsername:TEST_EMAIL password:TEST_PASSWORD completionHandler:^(NSString *userName, NSString *token, NSError *error) {
        LogTrace(@"userName %@",userName);
        LogTrace(@"error %@",error);
        if (error) {
            [UIUtility toastMessageOnScreen:[error localizedDescription]];
        }
        else{
            [UIUtility toastMessageOnScreen:[NSString stringWithFormat:@"%@ is now logged in",userName]];
        }
    }];
}

-(IBAction)signOut:(id)sender{
    [authLayer signOut];
    [UIUtility toastMessageOnScreen:@"Only local tokens & Citrus cookies are cleared"];
}

// Save the cards.
-(IBAction)saveCards:(id)sender{
    CTSPaymentDetailUpdate *paymentInfo = [[CTSPaymentDetailUpdate alloc] init];
    // Credit card info for card payment type.
    CTSElectronicCardUpdate *creditCard = [[CTSElectronicCardUpdate alloc] initCreditCard];
    creditCard.number = TEST_CREDIT_CARD_NUMBER;
    creditCard.expiryDate = TEST_CREDIT_CARD_EXPIRY_DATE;
    creditCard.scheme = [CTSUtility fetchCardSchemeForCardNumber:creditCard.number];
    creditCard.ownerName = TEST_CREDIT_CARD_OWNER_NAME;
    //creditCard.name = TEST_CREDIT_CARD_BANK_NAME;
    creditCard.cvv = TEST_CREDIT_CARD_CVV;
    [paymentInfo addCard:creditCard];
    
    // Configure your request here.
    [proifleLayer updatePaymentInformation:paymentInfo withCompletionHandler:^(NSError *error) {
        if(error == nil){
            // Your code to handle success.
            [UIUtility toastMessageOnScreen:@" succesfully card saved "];
        }
        else {
            // Your code to handle error.
            [UIUtility toastMessageOnScreen:[NSString stringWithFormat:@" couldn't save card\n error: %@",toErrorDescription(error)]];
        }
    }];
}


// delete the card.
-(void)deleteCard{
    
    NSString *lastFourDigitsOfCard = @"8001";
    
    // Configure your request here.
    [proifleLayer requestDeleteCard:lastFourDigitsOfCard scheme:[CTSUtility fetchCardSchemeForCardNumber:TEST_CREDIT_CARD_NUMBER] withCompletionHandler:^(NSError *error) {
        if(error == nil){
            // Your code to handle success.
            [UIUtility toastMessageOnScreen:@" succesfully card deleted "];
        }
        else {
            // Your code to handle error.
            [UIUtility toastMessageOnScreen:[NSString stringWithFormat:@" couldn't delete card\n error: %@",toErrorDescription(error)]];
        }
    }];
}


// Get the bind user cards.
-(IBAction)getSavedCards:(id)sender{
    // Configure your request here.
    [proifleLayer requestPaymentInformationWithCompletionHandler:^(CTSProfilePaymentRes *paymentInfo, NSError *error) {
        if (error == nil) {
            // Your code to handle success.
            NSMutableString *toastString = [[NSMutableString alloc] init];
            if([paymentInfo.paymentOptions count]){
                [toastString appendString:[self convertToString:[paymentInfo.paymentOptions objectAtIndex:0]]];
            }
            else{
                toastString =(NSMutableString *) @" no saved cards, please save card first";
            }
            [UIUtility toastMessageOnScreen:toastString];
        } else {
            // Your code to handle error.
            [UIUtility toastMessageOnScreen:[NSString stringWithFormat:@" couldn't find saved cards \nerror: %@",[error localizedDescription]]];
        }
    }];
}

// This API call fetches the payment options such as VISA, MASTER (in credit and debit  cards) and net banking options available to the merchant.
-(void)requestPaymentModes{
    [paymentLayer requestMerchantPgSettings:VanityUrl withCompletionHandler:^(CTSPgSettings *pgSettings, NSError *error) {
        if(error){
            //handle error
            LogTrace(@"[error localizedDescription] %@ ", [error localizedDescription]);
        }
        else {
            LogTrace(@" pgSettings %@ ", pgSettings);
            for (NSString* val in pgSettings.creditCard) {
                LogTrace(@"CC %@ ", val);
            }
            
            for (NSString* val in pgSettings.debitCard) {
                LogTrace(@"DC %@ ", val);
            }
            
            for (NSDictionary* arr in pgSettings.netBanking) {
                LogTrace(@"bankName %@ ", [arr valueForKey:@"bankName"]);
                LogTrace(@"issuerCode %@ ", [arr valueForKey:@"issuerCode"]);
            }
        }
    }];
}



// Card payment debit/credit
-(IBAction)cardPayment:(id)sender{
    // Update card for card payment.
    CTSElectronicCardUpdate *creditCard = [[CTSElectronicCardUpdate alloc] initCreditCard];
    creditCard.number = TEST_CREDIT_CARD_NUMBER;
    creditCard.expiryDate = TEST_CREDIT_CARD_EXPIRY_DATE;
    creditCard.scheme = [CTSUtility fetchCardSchemeForCardNumber:creditCard.number];
    creditCard.ownerName = TEST_CREDIT_CARD_OWNER_NAME;
    creditCard.cvv = TEST_CREDIT_CARD_CVV;
    
    CTSPaymentDetailUpdate *paymentInfo = [[CTSPaymentDetailUpdate alloc] init];
    [paymentInfo addCard:creditCard];
    
    // Get your bill here.
    CTSBill *bill = [SampleViewController getBillFromServer];
    
    [paymentLayer requestChargePayment:paymentInfo withContact:contactInfo withAddress:addressInfo bill:bill customParams:customParams withCompletionHandler:^(CTSPaymentTransactionRes *paymentInfo, NSError *error) {
        [self handlePaymentResponse:paymentInfo error:error];
    }];
    
}


// Netbanking
-(IBAction)netbankingPayment:(id)sender{
    CTSPaymentDetailUpdate *paymentInfo = [[CTSPaymentDetailUpdate alloc] init];
    // Update bank details for net banking payment.
    CTSNetBankingUpdate* netBank = [[CTSNetBankingUpdate alloc] init];
    netBank.code = @"CID002";
    [paymentInfo addNetBanking:netBank];
    
    // Get your bill here.
    CTSBill *bill = [SampleViewController getBillFromServer];
    
    [paymentLayer requestChargePayment:paymentInfo withContact:contactInfo withAddress:addressInfo bill:bill customParams:customParams withCompletionHandler:^(CTSPaymentTransactionRes *paymentInfo, NSError *error) {
        [self handlePaymentResponse:paymentInfo error:error];
    }];
}


// Tokenized card payment.
-(IBAction)tokenizedPayment:(id)sender{
    CTSPaymentDetailUpdate *tokenizedCardInfo = [[CTSPaymentDetailUpdate alloc] init];
    // Update card for tokenized payment.
    CTSElectronicCardUpdate *tokenizedCard = [[CTSElectronicCardUpdate alloc] initCreditCard];
    tokenizedCard.cvv= TEST_CREDIT_CARD_CVV;
    tokenizedCard.token= @"f00bbc754c00db104cfb9c6adb3fd31c";
    [tokenizedCardInfo addCard:tokenizedCard];
    
    // Get your bill here.
    CTSBill *bill = [SampleViewController getBillFromServer];
    
    [paymentLayer requestChargeTokenizedPayment:tokenizedCardInfo withContact:contactInfo withAddress:addressInfo bill:bill customParams:customParams withCompletionHandler:^(CTSPaymentTransactionRes *paymentInfo, NSError *error) {
        [self handlePaymentResponse:paymentInfo error:error];
    }];
}



// This is when we want to store bank account for cashout into users profile. At the max there can be only one account saved at a time, so if you want store new account just call this method with new details (previous one will get overridden).
-(IBAction)saveCashoutBankAccount{
    CTSCashoutBankAccount *bankAccount = [[CTSCashoutBankAccount alloc] init];
    bankAccount.owner = @"Yadnesh Wankhede";
    bankAccount.branch = @"HSBC0000123";
    bankAccount.number = @"123456789987654";
    
    [proifleLayer requestUpdateCashoutBankAccount:bankAccount withCompletionHandler:^(NSError *error) {
        if (error) {
            [UIUtility toastMessageOnScreen:[error localizedDescription]];
        }
        else{
            [UIUtility toastMessageOnScreen:@"Succesfully stored bank account"];
        }
    }];
    
}

// To get/fetch the cash-out account that’s was saved earlier.
-(IBAction)fetchCashoutBankAccount{
    [proifleLayer requestCashoutBankAccountCompletionHandler:^(CTSCashoutBankAccountResp *bankAccount, NSError *error) {
        if(error){
            [UIUtility toastMessageOnScreen:[error localizedDescription]];
        }
        else {
            [UIUtility toastMessageOnScreen:[NSString stringWithFormat:@"%@\n number: %@\n ifsc: %@",bankAccount.cashoutAccount.owner,bankAccount.cashoutAccount.number,bankAccount.cashoutAccount.branch]];
        }
    }];
}

// This is when user wants to withdraw money from his/her prepaid account into the bank account, so this needs bank account info to be sent to this method.
-(IBAction)cashOutToBank{
    CTSCashoutBankAccount *bankAccount = [[CTSCashoutBankAccount alloc] init];
    bankAccount.owner = @"Yadnesh Wankhede";
    bankAccount.branch = @"HSBC0000123";
    bankAccount.number = @"123456789987654";
    
    [paymentLayer requestCashoutToBank:bankAccount amount:@"5" completionHandler:^(CTSCashoutToBankRes *cashoutRes, NSError *error) {
        if(error){
            [UIUtility toastMessageOnScreen:[error localizedDescription]];
        }
        else {
            [UIUtility toastMessageOnScreen:[NSString stringWithFormat:@"id:%@\n cutsomer:%@\n merchant:%@\n type:%@\n date:%@\n amount:%@\n status:%@\n reason:%@\n balance:%@\n ref:%@\n",cashoutRes.id, cashoutRes.cutsomer, cashoutRes.merchant, cashoutRes.type, cashoutRes.date, cashoutRes.amount, cashoutRes.status, cashoutRes.reason, cashoutRes.balance, cashoutRes.ref]];
        }
    }];
}

-(IBAction)getBalance:(id)sender{
    [proifleLayer requetGetBalance:^(CTSAmount *amount, NSError *error) {
        LogTrace(@" value %@ ",amount.value);
        LogTrace(@" currency %@ ",amount.currency);
        if (error) {
            [UIUtility toastMessageOnScreen:[error localizedDescription]];
        }
        else{
            [UIUtility toastMessageOnScreen:[NSString stringWithFormat:@"Balance is %@ %@",amount.value,amount.currency]];
        }
    }];
}


-(IBAction)loadUsingCard:(id)sender{
    
    CTSPaymentDetailUpdate *creditCardInfo = [[CTSPaymentDetailUpdate alloc] init];
    // Update card for card payment.
    CTSElectronicCardUpdate *creditCard = [[CTSElectronicCardUpdate alloc] initDebitCard];
    creditCard.number = TEST_CREDIT_CARD_NUMBER;
    creditCard.expiryDate = TEST_CREDIT_CARD_EXPIRY_DATE;
    creditCard.scheme = [CTSUtility fetchCardSchemeForCardNumber:creditCard.number];
    creditCard.ownerName = TEST_CREDIT_CARD_OWNER_NAME;
    creditCard.cvv = TEST_CREDIT_CARD_CVV;
    
    [creditCardInfo addCard:creditCard];
    
    [paymentLayer requestLoadMoneyInCitrusPay:creditCardInfo withContact:contactInfo withAddress:addressInfo amount:@"1" returnUrl:ReturnUrl customParams:nil withCompletionHandler:^(CTSPaymentTransactionRes *paymentInfo, NSError *error) {
        [self handlePaymentResponse:paymentInfo error:error];
    }];
}


-(IBAction)loadUsingCardToken:(id)sender{
    
    CTSPaymentDetailUpdate *tokenizedCardInfo = [[CTSPaymentDetailUpdate alloc] init];
    // Update card for tokenized payment.
    CTSElectronicCardUpdate *tokenizedCard = [[CTSElectronicCardUpdate alloc] initCreditCard];
    tokenizedCard.cvv= TEST_CREDIT_CARD_CVV;
    tokenizedCard.token= TEST_TOKENIZED_CARD_TOKEN;
    [tokenizedCardInfo addCard:tokenizedCard];
    
    
    [paymentLayer requestLoadMoneyInCitrusPay:tokenizedCardInfo withContact:contactInfo withAddress:addressInfo amount:@"1" returnUrl:ReturnUrl customParams:nil withCompletionHandler:^(CTSPaymentTransactionRes *paymentInfo, NSError *error) {
        [self handlePaymentResponse:paymentInfo error:error];
    }];
    
    
}

-(IBAction)loadUsingNetbank:(id)sender{
    
    CTSPaymentDetailUpdate *paymentInfo = [[CTSPaymentDetailUpdate alloc] init];
    // Update bank details for net banking payment.
    CTSNetBankingUpdate* netBank = [[CTSNetBankingUpdate alloc] init];
    netBank.code = @"CID002";TEST_NETBAK_CODE;
    [paymentInfo addNetBanking:netBank];
    
    [paymentLayer requestLoadMoneyInCitrusPay:paymentInfo withContact:contactInfo withAddress:addressInfo amount:@"10" returnUrl:ReturnUrl customParams:nil withCompletionHandler:^(CTSPaymentTransactionRes *paymentInfo, NSError *error) {
        [self handlePaymentResponse:paymentInfo error:error];
    }];
    
    
}

-(IBAction)payUsingCitrusCash:(id)sender{
    
    CTSBill *bill = [SampleViewController getBillFromServer];
    [paymentLayer requestChargeCitrusCashWithContact:contactInfo withAddress:addressInfo  bill:bill customParams:nil returnViewController:self withCompletionHandler:^(CTSCitrusCashRes *paymentInfo, NSError *error) {
        NSLog(@"paymentInfo %@",paymentInfo);
        NSLog(@"error %@",error);
        //[self handlePaymentResponse:paymentInfo error:error];
        if(error){
            [UIUtility toastMessageOnScreen:[error localizedDescription]];
        }
        else{
            [UIUtility toastMessageOnScreen:[NSString stringWithFormat:@" transaction complete\n txStatus: %@",[paymentInfo.responseDict valueForKey:@"TxStatus"] ]];
            
        }
    }];
}

// fetch PG Health of Banks in percentage.
// You can decide your percentage limit for poor/good/excellent pg health show off text?
-(IBAction)fetchPGHealth{
    [paymentLayer requestGetPGHealthWithCompletionHandler:^(CTSPGHealthRes* pgHealthRes, NSError* error) {
        if(error){
            [UIUtility toastMessageOnScreen:[error localizedDescription]];
        }
        else {
            LogTrace(@"responseDict %@ ", pgHealthRes.responseDict);
            [UIUtility toastMessageOnScreen:[NSString stringWithFormat:@"CID001:%@",[pgHealthRes.responseDict valueForKey:@"CID001"]]];
        }
    }];
}


#pragma mark - Payment Helpers
-(void)handlePaymentResponse:(CTSPaymentTransactionRes *)paymentInfo error:(NSError *)error{
    
    BOOL hasSuccess =
    ((paymentInfo != nil) && ([paymentInfo.pgRespCode integerValue] == 0) &&
     (error == nil))
    ? YES
    : NO;
    if(hasSuccess){
        // Your code to handle success.
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIUtility dismissLoadingAlertView:YES];
            if (hasSuccess && error.code != ServerErrorWithCode) {
                [UIUtility didPresentLoadingAlertView:@"Connecting to the PG" withActivity:YES];
                [self loadRedirectUrl:paymentInfo.redirectUrl];
            }else{
                [UIUtility didPresentErrorAlertView:error];
            }
        });
        
    }
    else{
        // Your code to handle error.
        NSString *errorToast;
        if(error== nil){
            errorToast = [NSString stringWithFormat:@" payment failed : %@",paymentInfo.txMsg] ;
        }else{
            errorToast = [NSString stringWithFormat:@" payment failed : %@",toErrorDescription(error)] ;
        }
        [UIUtility toastMessageOnScreen:errorToast];
    }
}

- (void)loadRedirectUrl:(NSString*)redirectURL {
    WebGatewayViewController* webGatewayViewController = [[WebGatewayViewController alloc] init];
    webGatewayViewController.redirectURL = redirectURL;
    [UIUtility dismissLoadingAlertView:YES];
    [self.navigationController pushViewController:webGatewayViewController animated:YES];
}


/*
 You can modify this according to your needs.
 This is sample implementation.
 */
+ (CTSBill*)getBillFromServer{
    // Configure your request here.
    NSMutableURLRequest* urlReq = [[NSMutableURLRequest alloc] initWithURL:
                                   [NSURL URLWithString:BillUrl]];
    [urlReq setHTTPMethod:@"POST"];
    NSError* error = nil;
    NSData* signatureData = [NSURLConnection sendSynchronousRequest:urlReq
                                                  returningResponse:nil
                                                              error:&error];
    NSString* billJson = [[NSString alloc] initWithData:signatureData
                                               encoding:NSUTF8StringEncoding];
    JSONModelError *jsonError;
    CTSBill* sampleBill = [[CTSBill alloc] initWithString:billJson
                                                    error:&jsonError];
    NSLog(@"billJson %@",billJson);
    NSLog(@"signature %@ ", sampleBill);
    return sampleBill;
    
}

// String parser
-(NSString *)convertToString:(CTSPaymentOption *)option{
    
    NSMutableString *msgString = [[NSMutableString alloc] init];
    
    if(option.name){
        [msgString appendFormat:@"\n  name: %@",option.name];
    }
    if(option.owner){
        [msgString appendFormat:@"\n  owner: %@",option.owner];
    }
    if(option.bank){
        [msgString appendFormat:@"\n  bank: %@",option.bank];
    }
    if(option.number){
        [msgString appendFormat:@"\n  number: %@",option.number];
    }
    if(option.expiryDate){
        [msgString appendFormat:@"\n  expiryDate: %@",option.expiryDate];
    }
    if(option.scheme){
        [msgString appendFormat:@"\n  scheme: %@",option.scheme];
    }
    if(option.token){
        [msgString appendFormat:@"\n  token: %@",option.token];
    }
    if(option.mmid){
        [msgString appendFormat:@"\n  mmid: %@",option.mmid];
    }
    if(option.impsRegisteredMobile){
        [msgString appendFormat:@"\n  impsRegisteredMobile: %@",option.impsRegisteredMobile];
    }
    if(option.code){
        [msgString appendFormat:@"\n  code: %@",option.code];
    }
    return msgString;
}

@end
