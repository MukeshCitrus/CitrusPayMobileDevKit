//
//  CTSAuthLayer.m
//  RestFulltester
//
//  Created by Yadnesh Wankhede on 23/05/14.
//  Copyright (c) 2014 Citrus. All rights reserved.
//

#import "CTSAuthLayer.h"
#import "RestLayerConstants.h"
#import "CTSAuthLayerConstants.h"
#import "CTSSignUpRes.h"
#import "UserLogging.h"
#import "CTSUtility.h"
#import "CTSError.h"
#import "CTSOauthManager.h"
#import "CTSSignupState.h"
#import "CTSProfileLayer.h"

#import <CommonCrypto/CommonDigest.h>
#ifndef MIN
#import <NSObjCRuntime.h>
#endif

// 010615 Dynamic Oauth keys init with base URL
static NSString * VanityUrl;
static NSString * SignInId;
static NSString * SignInSecretKey;
static NSString * SubscriptionId;
static NSString * SubscriptionSecretKey;
static NSString * ReturnUrl;
static NSString * BaseUrl;

@implementation CTSAuthLayer
@synthesize delegate;

#pragma mark - public methods

- (void)requestResetPassword:(NSString*)userNameArg
           completionHandler:(ASResetPasswordCallback)callBack;
{
    
  [self addCallback:callBack forRequestId:RequestForPasswordResetReqId];

  OauthStatus* oauthStatus = [CTSOauthManager fetchSignupTokenStatus];
  NSString* oauthToken = oauthStatus.oauthToken;

  if (oauthStatus.error != nil) {
    [self resetPasswordHelper:oauthStatus.error];
  }

  if (![CTSUtility validateEmail:userNameArg]) {
    [self resetPasswordHelper:[CTSError getErrorForCode:EmailNotValid]];
    return;
  }
    userNameArg = userNameArg.lowercaseString;
  CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
      initWithPath:MLC_REQUEST_CHANGE_PWD_REQ_PATH
         requestId:RequestForPasswordResetReqId
           headers:[CTSUtility readOauthTokenAsHeader:oauthToken]
        parameters:@{MLC_REQUEST_CHANGE_PWD_QUERY_USERNAME : userNameArg.lowercaseString}
              json:nil
        httpMethod:POST];

  [restCore requestAsyncServer:request];
}

- (void)requestInternalSignupMobile:(NSString*)mobile email:(NSString*)email {
  if (![CTSUtility validateEmail:email]) {
    [self signupHelperUsername:userNameSignup
                         oauth:[CTSOauthManager readOauthToken]
                         error:[CTSError getErrorForCode:EmailNotValid]];
    return;
  }
  if (![CTSUtility validateMobile:mobile]) {
    [self signupHelperUsername:userNameSignup
                         oauth:[CTSOauthManager readOauthToken]
                         error:[CTSError getErrorForCode:MobileNotValid]];
    return;
  }

    email = email.lowercaseString;

  CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
      initWithPath:MLC_SIGNUP_REQ_PATH
         requestId:SignupStageOneReqId
           headers:[CTSUtility readSignupTokenAsHeader]
        parameters:@{
          MLC_SIGNUP_QUERY_EMAIL : email.lowercaseString,
          MLC_SIGNUP_QUERY_MOBILE : mobile
        } json:nil
        httpMethod:POST];

  [restCore requestAsyncServer:request];
}



- (void)requestInternalBindUserName:(NSString *)email mobile:(NSString *)mobile {

    email = email.lowercaseString;

    
    
        CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
                                   initWithPath:MLC_BIND_USER_REQ_PATH
                                   requestId:BindUserRequestId
                                   headers:[CTSUtility readSignupTokenAsHeader]
                                   parameters:@{
                                                MLC_BIND_USER_QUERY_EMAIL : email,
                                                MLC_BIND_USER_QUERY_MOBILE : mobile
                                                } json:nil
                                   httpMethod:MLC_BIND_USER_REQ_TYPE];
    
    [restCore requestAsyncServer:request];
}





- (void)requestSignUpWithEmail:(NSString*)email
                        mobile:(NSString*)mobile
                      password:(NSString*)password
             completionHandler:(ASSignupCallBack)callBack {
  [self addCallback:callBack forRequestId:SignupOauthTokenReqId];

  if (![CTSUtility validateEmail:email]) {
    [self signupHelperUsername:userNameSignup
                         oauth:[CTSOauthManager readOauthToken]
                         error:[CTSError getErrorForCode:EmailNotValid]];
    return;
  }
  if (![CTSUtility validateMobile:mobile]) {
    [self signupHelperUsername:userNameSignup
                         oauth:[CTSOauthManager readOauthToken]
                         error:[CTSError getErrorForCode:MobileNotValid]];
    return;
  }

    email = email.lowercaseString;

  userNameSignup = email;
  mobileSignUp = mobile;
  if (password == nil) {
    passwordSignUp = [self generatePseudoRandomPassword];
  } else {
    passwordSignUp = password;
  }

  //  CTSSignupState* signupState = [[CTSSignupState alloc] initWithEmail:email
  //                                                               mobile:mobile
  //                                                             password:password];
  //
  //  long index = [self addDataToCacheAtAutoIndex:signupState];

  [self requestSignUpOauthToken];
}






- (void)requestSignUpOauthToken {
  ENTRY_LOG
  wasSignupCalled = YES;

  CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
      initWithPath:MLC_OAUTH_TOKEN_SIGNUP_REQ_PATH
         requestId:SignupOauthTokenReqId
           headers:nil
        parameters:MLC_OAUTH_TOKEN_SIGNUP_QUERY_MAPPING
              json:nil
        httpMethod:POST];

  [restCore requestAsyncServer:request];

  EXIT_LOG
}

- (void)requestSignUpOauthTokenCompletionHandler:(ASAsyncSignUpOauthTokenCallBack)callback {
    ENTRY_LOG
    
    [self addCallback:callback forRequestId:SignupOauthAsynTokenReqId];
    
    
    CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
                                   initWithPath:MLC_OAUTH_TOKEN_SIGNUP_REQ_PATH
                                   requestId:SignupOauthAsynTokenReqId
                                   headers:nil
                                   parameters:MLC_OAUTH_TOKEN_SIGNUP_QUERY_MAPPING
                                   json:nil
                                   httpMethod:POST];
    
    [restCore requestAsyncServer:request];
    
    EXIT_LOG
}


-(void)requestSignupUser:(CTSUserDetails *)user password:(NSString *)pasword mobileVerified:(BOOL)isMarkMobileVerifed emailVerified:(BOOL)isMarkEmailVerified completionHandler:(ASSignupNewCallBack)callback{
    //verify the user object
    [self addCallback:callback forRequestId:SignupNewReqId];
    
    if(!pasword){
        pasword = @"";
    }
    
    
    
    
    if ( [CTSUtility validateEmail:user.email] == NO) {
        [self newSignupHelper:[CTSError getErrorForCode:EmailNotValid]];
        return;
    }
    
    user.mobileNo = [CTSUtility mobileNumberToTenDigitIfValid:user.mobileNo];
    if (user.mobileNo == nil) {
        [self newSignupHelper:[CTSError getErrorForCode:MobileNotValid]];
        return;
    }
    
    
    [self requestSignUpOauthTokenCompletionHandler:^(NSError *error) {
        if(error == nil){
            NSDictionary *parameters = @{MLC_MLC_SIGNUP_NEW_QUERY_EMAIL:user.email,
                                         MLC_MLC_SIGNUP_NEW_QUERY_MOBILE:user.mobileNo,
                                         MLC_MLC_SIGNUP_NEW_QUERY_FIRSTNAME:user.firstName,
                                         MLC_MLC_SIGNUP_NEW_QUERY_LASTNAME:user.lastName,
                                         MLC_MLC_SIGNUP_NEW_QUERY_SOURCE_TYPE:SignInId,
                                         MLC_MLC_SIGNUP_NEW_QUERY_PASSWORD:pasword,
                                         MLC_MLC_SIGNUP_NEW_QUERY_MOBILE_VERIFIED:[CTSUtility toStringBool:isMarkMobileVerifed],
                                         MLC_MLC_SIGNUP_NEW_QUERY_EMAIL_VERIFIED:[CTSUtility toStringBool:isMarkEmailVerified]
                                         };
            
            CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
                                           initWithPath:MLC_SIGNUP_NEW_PATH
                                           requestId:SignupNewReqId
                                           headers:[CTSUtility readSignupTokenAsHeader]
                                           parameters:parameters
                                           json:nil
                                           httpMethod:POST];
            [restCore requestAsyncServer:request];
            
        }
        else {
            [self newSignupHelper:error];
        }
    }];
}


-(void)requestVerification:(NSString *)mobile code:(NSString *)otp completionHandler:(ASOtpVerificationCallback)callback{
    [self addCallback:callback forRequestId:OTPVerificationRequestId];
    
    
   // username = [CTSUtility mobileNumberToTenDigitIfValid:username];
    if (!mobile) {
        [self otpVerificationHelper:NO error:[CTSError getErrorForCode:MobileNotValid]];
        return;
    }
    
    NSDictionary* parameters = @{
                                 MLC_OTP_VER_QUERY_OTP : otp,
                                 MLC_OTP_VER_QUERY_MOBILE : mobile
                                 };
    
    CTSRestCoreRequest* request =
    [[CTSRestCoreRequest alloc] initWithPath:MLC_OTP_VER_PATH
                                   requestId:OTPVerificationRequestId
                                     headers:nil
                                  parameters:parameters
                                        json:nil
                                  httpMethod:POST];
    
    [restCore requestAsyncServer:request];
    
    
}


-(void)requestVerificationCodeRegenerate:(NSString *)mobile completionHandler:(ASOtpRegenerationCallback)callback{
    [self addCallback:callback forRequestId:OTPRegenerationRequestId];
   // mobile = [CTSUtility mobileNumberToTenDigitIfValid:mobile];
    
    if (!mobile) {
        [self otpRegenerationHelper:nil error:[CTSError getErrorForCode:MobileNotValid]];
        return;
    }
    
    NSDictionary* parameters = @{
                                 MLC_OTP_REGENERATE_QUERY_MOBILE : mobile
                                 };
    
    CTSRestCoreRequest* request =
    [[CTSRestCoreRequest alloc] initWithPath:MLC_OTP_REGENERATE_PATH
                                   requestId:OTPRegenerationRequestId
                                     headers:nil
                                  parameters:parameters
                                        json:nil
                                  httpMethod:MLC_OTP_REGENERATE_TYPE];
    
    [restCore requestAsyncServer:request];
    
}



-(void)requestGenerateOTPFor:(NSString *)entity completionHandler:(ASGenerateOtpCallBack)callback{
    [self addCallback:callback forRequestId:GenerateOTPReqId];
    
    NSString *otpType = @"mobile";
    
    if([CTSUtility isEmail:entity]){
        otpType = @"email";
    }
    
    
    if ( [CTSUtility isEmail:entity] == YES  && [CTSUtility validateEmail:entity] == NO) {
        [self otpGenerateHelper:nil error:[CTSError getErrorForCode:EmailNotValid]];
        return;
    }
    
    if([otpType isEqualToString:@"mobile"]){
        entity = [CTSUtility mobileNumberToTenDigitIfValid:entity];
        if (  [CTSUtility isEmail:entity] == NO  &&  entity == nil) {
            [self otpGenerateHelper:nil
                              error:[CTSError getErrorForCode:MobileNotValid]];
            return;
        }
    }
    
    NSDictionary* parameters = @{
                                 MLC_OTP_SIGNIN_QUERY_SOURCE:SignInId,
                                 MLC_OTP_SIGNIN_QUERY_OTP_TYPE:otpType,
                                 MLC_OTP_SIGNIN_PATH_IDENTITY:entity
                                 };
    
    
    
    CTSRestCoreRequest* request =
    [[CTSRestCoreRequest alloc] initWithPath:MLC_OTP_SIGNIN_PATH
                                   requestId:GenerateOTPReqId
                                     headers:MLC_OAUTH_TOKEN_SIGNUP_QUERY_MAPPING
                                  parameters:nil
                                        json:[CTSUtility toJson:parameters]
                                  httpMethod:POST];
    
    [restCore requestAsyncServer:request];
    
    
}


- (void)requestSigninWithUsername:(NSString*)userNameArg
                         password:(NSString*)password
                completionHandler:(ASSigninCallBack)callBack {
  /**
   *  flow sigin in
   check oauth expiry time if oauth token is expired call for refresh token and
   send refresh token
   if refresh token has error then proceed for normal signup

   */

  [self addCallback:callBack forRequestId:SigninOauthTokenReqId];



    userNameArg = userNameArg.lowercaseString;
    userNameSignIn = userNameArg;
    passwordSignin = password;

    
    
  NSDictionary* parameters = @{
    MLC_OAUTH_TOKEN_QUERY_CLIENT_ID : MLC_OAUTH_TOKEN_SIGNIN_CLIENT_ID,
    MLC_OAUTH_TOKEN_QUERY_CLIENT_SECRET : MLC_OAUTH_TOKEN_SIGNIN_CLIENT_SECRET,
    MLC_OAUTH_TOKEN_QUERY_GRANT_TYPE : MLC_SIGNIN_GRANT_TYPE,
    MLC_OAUTH_TOKEN_SIGNIN_QUERY_PASSWORD : password,
    MLC_OAUTH_TOKEN_SIGNIN_QUERY_USERNAME : userNameArg
  };

  CTSRestCoreRequest* request =
      [[CTSRestCoreRequest alloc] initWithPath:MLC_OAUTH_TOKEN_SIGNUP_REQ_PATH
                                     requestId:SigninOauthTokenReqId
                                       headers:nil
                                    parameters:parameters
                                          json:nil
                                    httpMethod:POST];

  [restCore requestAsyncServer:request];
}


- (void)requestSigninWithUsername:(NSString*)userNameArg
                         otp:(NSString*)otp
                completionHandler:(ASOtpSigninCallBack)callBack {
    /**
     *  flow sigin in
     check oauth expiry time if oauth token is expired call for refresh token and
     send refresh token
     if refresh token has error then proceed for normal signup
     
     */
    
    [self addCallback:callBack forRequestId:OtpSignInReqId];
    
    
    userNameArg = userNameArg.lowercaseString;
    userNameSignIn = userNameArg;
    passwordSignin = otp;
    
    
    
    NSDictionary* parameters = @{
                                 MLC_OAUTH_TOKEN_QUERY_CLIENT_ID : MLC_OAUTH_TOKEN_SIGNIN_CLIENT_ID,
                                 MLC_OAUTH_TOKEN_QUERY_CLIENT_SECRET : MLC_OAUTH_TOKEN_SIGNIN_CLIENT_SECRET,
                                 MLC_OAUTH_TOKEN_QUERY_GRANT_TYPE : MLC_SIGNIN_GRANT_TYPE_OTP,
                                 MLC_OAUTH_TOKEN_SIGNIN_QUERY_PASSWORD : otp,
                                 MLC_OAUTH_TOKEN_SIGNIN_QUERY_USERNAME : userNameArg
                                 };
    
    CTSRestCoreRequest* request =
    [[CTSRestCoreRequest alloc] initWithPath:MLC_OAUTH_TOKEN_SIGNUP_REQ_PATH
                                   requestId:OtpSignInReqId
                                     headers:nil
                                  parameters:parameters
                                        json:nil
                                  httpMethod:POST];
    
    [restCore requestAsyncServer:request];
}








-(void)requestBindSignin:(NSString *)userName completionHandler:(ASBindSignIn)callback{
    [self addCallback:callback forRequestId:BindSigninAsyncReqId];
    
    userName = userName.lowercaseString;
    
    if ( [CTSUtility isEmail:userName] == YES  && [CTSUtility validateEmail:userName] == NO) {
        [self bindSigninAsyncHelperError:[CTSError getErrorForCode:EmailNotValid]];
        return;
    }
    else if( [CTSUtility isEmail:userName] == NO){
        userName = [CTSUtility mobileNumberToTenDigitIfValid:userName];
        if ( userName == nil) {
            [self bindSigninAsyncHelperError:[CTSError getErrorForCode:MobileNotValid]];
            return;
        }
    }
    
    NSDictionary* parameters = @{
                                 MLC_OAUTH_TOKEN_QUERY_CLIENT_ID : MLC_CLIENT_ID,
                                 MLC_OAUTH_TOKEN_QUERY_CLIENT_SECRET : MLC_OAUTH_TOKEN_SIGNIN_CLIENT_SECRET,
                                 MLC_OAUTH_TOKEN_QUERY_GRANT_TYPE : MLC_BIND_SIGNIN_GRANT_TYPE,
                                 MLC_OAUTH_TOKEN_SIGNIN_QUERY_USERNAME : userName
                                 };
    
    CTSRestCoreRequest* request =
    [[CTSRestCoreRequest alloc] initWithPath:MLC_OAUTH_TOKEN_SIGNUP_REQ_PATH
                                   requestId:BindSigninAsyncReqId
                                     headers:nil
                                  parameters:parameters
                                        json:nil
                                  httpMethod:POST];
    
    [restCore requestAsyncServer:request];
    
    
}


-(void)requestBindSigninUsername:(NSString *)email{
    
    email = email.lowercaseString;

    
    NSDictionary* parameters = @{
                                 MLC_OAUTH_TOKEN_QUERY_CLIENT_ID : MLC_CLIENT_ID,
                                 MLC_OAUTH_TOKEN_QUERY_CLIENT_SECRET : MLC_OAUTH_TOKEN_SIGNIN_CLIENT_SECRET,
                                 MLC_OAUTH_TOKEN_QUERY_GRANT_TYPE : MLC_BIND_SIGNIN_GRANT_TYPE,
                                 MLC_OAUTH_TOKEN_SIGNIN_QUERY_USERNAME : email
                                 };
    
    CTSRestCoreRequest* request =
    [[CTSRestCoreRequest alloc] initWithPath:MLC_OAUTH_TOKEN_SIGNUP_REQ_PATH
                                   requestId:BindSigninRequestId
                                     headers:nil
                                  parameters:parameters
                                        json:nil
                                  httpMethod:POST];
    
    [restCore requestAsyncServer:request];


}


-(void)requestSetPassword:(NSString *)password userName:(NSString *)userName completionHandler:(ASSetPassword)callback{

    userName = userName.lowercaseString;

    
    [self addCallback:callback forRequestId:SetPasswordReqId];
    
    [self requestChangePasswordUserName:userName oldPassword:[self generateBigIntegerString:userName] newPassword:password completionHandler:^(NSError *error) {
        [self setPasswordHelper:error];
    }];
    
    
}


- (void)usePassword:(NSString*)password
     hashedUsername:(NSString*)hashedUsername {
  ENTRY_LOG

  NSString* oauthToken = [CTSOauthManager readOauthTokenWithExpiryCheck];
  if (oauthToken == nil) {
    [self signupHelperUsername:userNameSignup
                         oauth:[CTSOauthManager readOauthToken]
                         error:[CTSError getErrorForCode:OauthTokenExpired]];
  }

  CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
      initWithPath:MLC_CHANGE_PASSWORD_REQ_PATH
         requestId:SignupChangePasswordReqId
           headers:[CTSUtility readOauthTokenAsHeader:oauthToken]
        parameters:@{
          MLC_CHANGE_PASSWORD_QUERY_OLD_PWD : hashedUsername,
          MLC_CHANGE_PASSWORD_QUERY_NEW_PWD : password
        } json:nil
        httpMethod:PUT];

  [restCore requestAsyncServer:request];
  EXIT_LOG
}

- (void)requestChangePasswordUserName:(NSString*)userName
                          oldPassword:(NSString*)oldPassword
                          newPassword:(NSString*)newPassword
                    completionHandler:(ASChangePassword)callback {
  ENTRY_LOG
  [self addCallback:callback forRequestId:ChangePasswordReqId];

  OauthStatus* oauthStatus = [CTSOauthManager fetchSigninTokenStatus];
  if (oauthStatus.error != nil) {
    [self changePasswordHelper:oauthStatus.error];
  }

    userName = userName.lowercaseString;

    
  CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
      initWithPath:MLC_CHANGE_PASSWORD_REQ_PATH
         requestId:ChangePasswordReqId
           headers:[CTSUtility readOauthTokenAsHeader:oauthStatus.oauthToken]
        parameters:@{
          MLC_CHANGE_PASSWORD_QUERY_OLD_PWD : oldPassword,
          MLC_CHANGE_PASSWORD_QUERY_NEW_PWD : newPassword
        } json:nil
        httpMethod:PUT];

  [restCore requestAsyncServer:request];
  EXIT_LOG
}

- (void)requestIsUserCitrusMemberUsername:(NSString*)email
                        completionHandler:
                            (ASIsUserCitrusMemberCallback)callback {
  [self addCallback:callback forRequestId:IsUserCitrusMemberReqId];
  if (![CTSUtility validateEmail:email]) {
    [self isUserCitrusMemberHelper:NO
                             error:[CTSError getErrorForCode:EmailNotValid]];
    return;
  }

  OauthStatus* oauthStatus = [CTSOauthManager fetchSignupTokenStatus];

  if (oauthStatus.error != nil) {
    [self isUserCitrusMemberHelper:NO error:oauthStatus.error];
  }
    
    email = email.lowercaseString;


  CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
      initWithPath:MLC_IS_MEMBER_REQ_PATH
         requestId:IsUserCitrusMemberReqId
           headers:[CTSUtility readOauthTokenAsHeader:oauthStatus.oauthToken]
        parameters:@{
          MLC_IS_MEMBER_QUERY_EMAIL : email
        } json:nil
        httpMethod:MLC_IS_MEMBER_REQ_TYPE];

  [restCore requestAsyncServer:request];
}



- (void)requestBindUsername:(NSString*)email
                     mobile:(NSString *)mobile
          completionHandler:
(ASBindUserCallback)callback{
    [self addCallback:callback forRequestId:BindUserRequestId];
    
    if (![CTSUtility validateEmail:email]) {
        [self bindUserHelperUsername:email
                                 error:[CTSError getErrorForCode:EmailNotValid]];
        return;
    }

    if (![CTSUtility validateMobile:mobile]) {
        [self bindUserHelperUsername:email
                               error:[CTSError getErrorForCode:MobileNotValid]];
        return;
    }
    
    email = email.lowercaseString;

    userNameBind = email;
    mobileBind = mobile;

    
    //get signup oauth token
    [self requestBindOauthToken];

    
    //call for bind
    //call for signin

}


- (void)requestBindOauthToken {
    ENTRY_LOG
    
    CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
                                   initWithPath:MLC_OAUTH_TOKEN_SIGNUP_REQ_PATH
                                   requestId:BindOauthTokenRequestId
                                   headers:nil
                                   parameters:MLC_OAUTH_TOKEN_SIGNUP_QUERY_MAPPING
                                   json:nil
                                   httpMethod:POST];
    
    [restCore requestAsyncServer:request];
    
    EXIT_LOG
}





- (BOOL)signOut {
  [CTSOauthManager resetOauthData];
  [CTSOauthManager resetBindSiginOauthData];
  [CTSOauthManager resetSignupToken];
  [CTSUtility deleteSigninCookie];
  return YES;
}




- (BOOL)isAnyoneSignedIn {
  NSString* signInOauthToken = [CTSOauthManager readOauthTokenWithExpiryCheck];
  if (signInOauthToken == nil)
    return NO;
  else
    return YES;
}


-(void)requestCitrusPaySignin:(NSString *)userName  password:(NSString*)password
            completionHandler:(ASCitrusSigninCallBack)callBack{

    [self addCallback:callBack forRequestId:CitruPaySigniInReqId];
    userName = userName.lowercaseString;

    
    
//validate username
    CTSRestCoreRequest* request = [[CTSRestCoreRequest alloc]
                                   initWithPath:MLC_CITRUS_PAY_AUTH_COOKIE_PATH
                                   requestId:CitruPaySigniInReqId
                                   headers:nil
                                   parameters:@{
                                                MLC_CITRUS_PAY_AUTH_COOKIE_EMAIL:userName,
                                                MLC_CITRUS_PAY_AUTH_COOKIE_PASSWORD:password,
                                                MLC_CITRUS_PAY_AUTH_COOKIE_RMCOOKIE:@"true"
                                            }
                                   json:nil
                                   httpMethod:POST];
    
    [restCore requestAsyncServerDelegation:request];
    

}


-(void)requestLink:(CTSUserDetails *)user completionHandler:(ASLinkCallback )callback{
    //accept mobile and email.
    //    Get Member Info (present in cube and tiny own sdk)
    //    if Mobile Present
    //        > Ask For Send M-OTP(not yet present) > (user will receive the otp) > RESPONSE : SIGN_IN_WITH_OTP
    //        if Mobile not Present and email present
    //            > Ask For Send E-OTP > (user will receive the eotp) > RESPONSE: SIGN_IN_WITH_EOTP
    //            Both Absent
    //            >  RESPONSE: FRESH_SIGNUP >
    
    
    
    //
    //Inputs:
    //
    //    email (mandatory)
    //    firstName (optional)
    //    lastName (optional)
    //    mobileNo (mandatory)
    //
    //
    //Output:
    //
    //
    
    
    
    [self addCallback:callback forRequestId:LinkReqId];
    
    //validations
    
    
    if (![CTSUtility validateEmail:user.email]) {
        [self linkHelper:nil error:[CTSError getErrorForCode:EmailNotValid]];
        return;
    }
    
    
    user.mobileNo = [CTSUtility mobileNumberToTenDigitIfValid:user.mobileNo];
    if (![CTSUtility validateMobile:user.mobileNo]) {
        [self linkHelper:nil
                       error:[CTSError getErrorForCode:MobileNotValid]];
        return;
    }

    
    
    
    CTSProfileLayer *profileLayer = [[CTSProfileLayer alloc ] init];
    [profileLayer requestMemberInfoMobile:user.mobileNo email:user.email withCompletionHandler:^(CTSNewContactProfile *profile, NSError *error) {
        if(error){
            //reply with failure
            NSLog(@"++++++++++++++++++++ Member Info Fetch Failed ");
            [self linkHelper:nil error:error];
            
        }else{
            NSLog(@"++++++++++++++++++++ Member Info Fetched ");
            
            if(profile.responseData.profileByMobile){
                NSLog(@"++++++++++++++++++++ Mobile Found ");
                
                //if Mob present    : (SDK invokes RequesMOtp) > User can now signin with motp or pwd
                
                [self requestGenerateOTPFor:profile.responseData.profileByMobile.mobile completionHandler:^(CTSResponse *response, NSError *error) {
                    NSLog(@"++++++++++++++++++++ Asked to send the M otp ");
                    
                    if(error){
                        NSLog(@"++++++++++++++++++++ ERROR in  M otp ");
                        
                        [self linkHelper:nil error:error];
                    }else{
                        //do link for wallet access
                        [self requestBindSignin:user.mobileNo completionHandler:^(NSError *error) {
                            [self linkHelper:[[CTSLinkRes alloc] initWith:LinkUserStatusMotpSigIn entity:profile.responseData.profileByMobile.mobile] error:nil];
                        }];
                    }
                }];
            }
            else if(profile.responseData.profileByEmail){
                //if Mob absent, Only Email present    : (SDK invokes RequesEOtp) > User can now signin with eotp or pwd
                NSLog(@"++++++++++++++++++++ Email Found ");
                
                [self requestGenerateOTPFor:profile.responseData.profileByEmail.email completionHandler:^(CTSResponse *response,NSError *error) {
                    NSLog(@"++++++++++++++++++++ Asked to send the E otp ");
                    
                    if(error){
                        NSLog(@"++++++++++++++++++++ ERROR in  E otp ");
                        [self linkHelper:nil error:error];
                        
                    }else{
                        //do link for wallet access
                        [self requestBindSignin:user.email completionHandler:^(NSError *error) {
                            [self linkHelper:[[CTSLinkRes alloc] initWith:LinkUserStatusEotpSignIn entity:profile.responseData.profileByEmail.email] error:nil];
                        }];

                    }
                }];
            }
            else{
                //if Email Mobile Absent  : (SDK SignsUp the user) > User receives the Verification code > now app should proceed to verification call from SDK
                NSLog(@"++++++++++++++++++++ Mobile Email Both Absent ");
                
                [self requestSignupUser:user password:nil mobileVerified:NO emailVerified:NO completionHandler:^(NSError *error) {
                    NSLog(@"++++++++++++++++++++ Asked to Signup ");
                    if(error){
                        [self linkHelper:nil error:error];
                    }
                    else{
                        //do link for wallet access
                        [self requestBindSignin:user.email completionHandler:^(NSError *error) {
                            [self linkHelper:[[CTSLinkRes alloc] initWith:LinkUserStatusSignup entity:user.mobileNo] error:nil];
                        }];
                    }
                }];
            }
        }
    }];
}



-(void)requestLinkUser:(NSString *)email mobile:(NSString *)mobile completionHandler:(ASLinkUserCallBack)callBack;
{
    
    
    [self addCallback:callBack forRequestId:LinkUserReqId];
//call bind
    //yes > set user password
    //password already set
    
    
    
    
    
    //implementtaion
    //verify the email and mobile
    isInLink = YES;
    
    if (![CTSUtility validateEmail:email]) {
        [self linkUserHelper:nil error:[CTSError getErrorForCode:EmailNotValid]];
        return;
    }
    
    if (![CTSUtility validateMobile:mobile]) {
        [self linkUserHelper:nil
                               error:[CTSError getErrorForCode:MobileNotValid]];
        return;
    }
    
    email = email.lowercaseString;

    //
    __block NSString *blockEmail = email;
    
    [self requestBindUsername:email mobile:mobile completionHandler:^(NSString *userName, NSError *error) {
        if(error){
        // return error
            [self linkUserHelper:nil error:error];
        
        }
        else if(userName){
            //TODO: check error
            
            [self
             requestSigninWithUsername:blockEmail
             password:[self generateBigIntegerString:blockEmail]
             completionHandler:^(NSString *userName, NSString *token, NSError *error) {
                 if(error && [self isBadCredentials:error]){
                     [self linkUserHelper:[[CTSLinkUserRes alloc] initPasswordAlreadySet] error:nil];

                 }
                 else {
                     [self linkUserHelper:[[CTSLinkUserRes alloc] initPasswordAlreadyNotSet] error:nil];
                     
                }
             }];
            
        }
    }];
   
}

-(NSString *)requestSignInOauthToken{
    return [CTSOauthManager readOauthToken];
}



#pragma mark - pseudo password generator methods
- (NSString*)generatePseudoRandomPassword {
  // Build the password using C strings - for speed
  int length = 7;
  char* cPassword = calloc(length + 1, sizeof(char));
  char* ptr = cPassword;

  cPassword[length - 1] = '\0';

  char* lettersAlphabet = "abcdefghijklmnopqrstuvwxyz";
  ptr = appendRandom(ptr, lettersAlphabet, 2);

  char* capitalsAlphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  ptr = appendRandom(ptr, capitalsAlphabet, 2);

  char* digitsAlphabet = "0123456789";
  ptr = appendRandom(ptr, digitsAlphabet, 2);

  char* symbolsAlphabet = "!@#$%*[];?()";
  ptr = appendRandom(ptr, symbolsAlphabet, 1);

  // Shuffle the string!
  for (int i = 0; i < length; i++) {
    int r = arc4random() % length;
    char temp = cPassword[i];
    cPassword[i] = cPassword[r];
    cPassword[r] = temp;
  }
  return [NSString stringWithCString:cPassword encoding:NSUTF8StringEncoding];
}

char* appendRandom(char* str, char* alphabet, int amount) {
  for (int i = 0; i < amount; i++) {
    int r = arc4random() % strlen(alphabet);
    *str = alphabet[r];
    str++;
  }

  return str;
}

- (void)generator:(int)seed {
  seedState = seed;
}

- (int)nextInt:(int)max {
  seedState = 7 * seedState % 3001;
  return (seedState - 1) % max;
}
- (char)nextLetter {
  int n = [self nextInt:52];
  return (char)(n + ((n < 26) ? 'A' : 'a' - 26));
}
static NSData* digest(NSData* data,
                      unsigned char* (*cc_digest)(const void*,
                                                  CC_LONG,
                                                  unsigned char*),
                      CC_LONG digestLength) {
  unsigned char md[digestLength];
  (void)cc_digest([data bytes], (unsigned int)[data length], md);
  return [NSData dataWithBytes:md length:digestLength];
}

- (NSData*)md5:(NSString*)email {
  NSData* data = [email dataUsingEncoding:NSASCIIStringEncoding];
  return digest(data, CC_MD5, CC_MD5_DIGEST_LENGTH);
}

- (NSArray*)copyOfRange:(NSArray*)original from:(int)from to:(int)to {
  int newLength = to - from;
  NSArray* destination;
  if (newLength < 0) {
  } else {
    // int copy[newLength];
    destination = [original subarrayWithRange:NSMakeRange(from, newLength)];
  }
  return destination;
}
- (int)genrateSeed:(NSString*)data {
  NSMutableArray* array = [[NSMutableArray alloc] init];
  NSData* hashed = [self md5:data];
  NSUInteger len = [hashed length];
  Byte* byteData = (Byte*)malloc(len);
  [hashed getBytes:byteData length:len];

  int result1[16];
  for (int i = 0; i < 16; i++) {
    Byte b = byteData[i];  // 0xDC;
    result1[i] = (b & 0x80) > 0 ? b - 0xFF - 1 : b;
    [array addObject:[NSNumber numberWithInt:result1[i]]];
  }

  NSArray* val = [self copyOfRange:array
                              from:(unsigned int)[array count] - 3
                                to:(unsigned int)[array count]];
  NSData* arrayData = [NSKeyedArchiver archivedDataWithRootObject:val];
  NSLog(@"%@", arrayData);
  int x = 0;
  for (int i = 0; i < [val count]; i++) {
    int z = [[val objectAtIndex:(val.count - 1 - i)] intValue];
    if (z < 0) {
      z = z + 256;
    }
    z = z << (8 * i);
    x = x + z;
    NSLog(@"%d", x);
  }
  return x;
}
- (NSString*)generateBigIntegerString:(NSString*)email {
    LogTrace(@"email %@",email);
  int ran = [self genrateSeed:email];

  [self generator:ran];
  NSMutableString* large_CSV_String = [[NSMutableString alloc] init];
  for (int i = 0; i < 8; i++) {
    // Add something from the key?? Your format here.
    [large_CSV_String appendFormat:@"%c", [self nextLetter]];
  }
  NSLog(@"random password:%@", large_CSV_String);
  return large_CSV_String;
}


#pragma mark - main class methods
enum {
    SignupOauthTokenReqId,
    SigninOauthTokenReqId,
    SignupStageOneReqId,
    SignupChangePasswordReqId,
    ChangePasswordReqId,
    RequestForPasswordResetReqId,
    IsUserCitrusMemberReqId,
    BindOauthTokenRequestId,
    BindUserRequestId,
    BindSigninRequestId,
    CitruPaySigniInReqId,
    LinkUserReqId,
    SetPasswordReqId,
    SignupOauthAsynTokenReqId,
    SignupNewReqId,
    OTPVerificationRequestId,
    OTPRegenerationRequestId,
    GenerateOTPReqId,
    LinkReqId,
    BindSigninAsyncReqId,
    OtpSignInReqId
};
- (instancetype)init {
    NSDictionary* dict = @{
                           toNSString(SignupOauthTokenReqId) : toSelector(handleReqSignupOauthToken
                                                                          :),
                           toNSString(SigninOauthTokenReqId) : toSelector(handleReqSigninOauthToken
                                                                          :),
                           toNSString(SignupStageOneReqId) : toSelector(handleReqSignupStageOneComplete
                                                                        :),
                           toNSString(SignupChangePasswordReqId) : toSelector(handleReqUsePassword
                                                                              :),
                           toNSString(RequestForPasswordResetReqId) :
                               toSelector(handleReqRequestForPasswordReset
                                          :),
                           toNSString(ChangePasswordReqId) : toSelector(handleReqChangePassword
                                                                        :),
                           toNSString(IsUserCitrusMemberReqId) : toSelector(handleIsUserCitrusMember
                                                                            :),
                           toNSString(BindOauthTokenRequestId) : toSelector(handleBindOauthToken
                                                                            :),
                           toNSString(BindUserRequestId) : toSelector(handleBindUser
                                                                      :),
                           
                           toNSString(BindSigninRequestId) : toSelector(handleBindSignIn
                                                                        :),
                           toNSString(CitruPaySigniInReqId) : toSelector(handleCitrusPaySignin
                                                                         :),
                           
                           toNSString(SignupOauthAsynTokenReqId) : toSelector(handleSignupAsyncOauthToken
                                                                              :),
                           
                           toNSString(SignupNewReqId) : toSelector(handleNewSignup
                                                                   :),
                           toNSString(OTPVerificationRequestId) : toSelector(handleOTPVerfication
                                                                             :),
                           toNSString(OTPRegenerationRequestId):toSelector(handleOTPRegeneration:)
                           ,
                           toNSString(GenerateOTPReqId):toSelector(handleOTPGeneration:),
                           
                           toNSString(BindSigninAsyncReqId):toSelector(handleBindSignInAsync
                                                                       :),
                           toNSString(OtpSignInReqId):toSelector(handleOtpSignIn
                                                                       :)

                           };
    
    self =
    [super initWithRequestSelectorMapping:dict baseUrl:CITRUS_AUTH_BASE_URL];
    
    return self;
}



// 010615 Dynamic Oauth keys init with base URL
- (instancetype)initWithBaseURLAndDynamicVanityOauthKeysURLs:(NSString *)url vanityUrl:(NSString *)vanityUrl signInId:(NSString *)signInId signInSecretKey:(NSString *)signInSecretKey subscriptionId:(NSString *)subscriptionId subscriptionSecretKey:(NSString *)subscriptionSecretKey returnUrl:(NSString *)returnUrl{
    
    NSDictionary* dict = @{
                           toNSString(SignupOauthTokenReqId) : toSelector(handleReqSignupOauthToken
                                                                          :),
                           toNSString(SigninOauthTokenReqId) : toSelector(handleReqSigninOauthToken
                                                                          :),
                           toNSString(SignupStageOneReqId) : toSelector(handleReqSignupStageOneComplete
                                                                        :),
                           toNSString(SignupChangePasswordReqId) : toSelector(handleReqUsePassword
                                                                              :),
                           toNSString(RequestForPasswordResetReqId) :
                               toSelector(handleReqRequestForPasswordReset
                                          :),
                           toNSString(ChangePasswordReqId) : toSelector(handleReqChangePassword
                                                                        :),
                           toNSString(IsUserCitrusMemberReqId) : toSelector(handleIsUserCitrusMember
                                                                            :),
                           toNSString(BindOauthTokenRequestId) : toSelector(handleBindOauthToken
                                                                            :),
                           toNSString(BindUserRequestId) : toSelector(handleBindUser
                                                                      :),
                           
                           toNSString(BindSigninRequestId) : toSelector(handleBindSignIn
                                                                        :),
                           toNSString(CitruPaySigniInReqId) : toSelector(handleCitrusPaySignin
                                                                         :),
                           
                           toNSString(SignupOauthAsynTokenReqId) : toSelector(handleSignupAsyncOauthToken
                                                                              :),
                           
                           toNSString(SignupNewReqId) : toSelector(handleNewSignup
                                                                   :),
                           toNSString(OTPVerificationRequestId) : toSelector(handleOTPVerfication
                                                                             :),
                           toNSString(OTPRegenerationRequestId):toSelector(handleOTPRegeneration:)
                           ,
                           toNSString(GenerateOTPReqId):toSelector(handleOTPGeneration:),
                           
                           toNSString(BindSigninAsyncReqId):toSelector(handleBindSignInAsync
                                                                       :),
                           toNSString(OtpSignInReqId):toSelector(handleOtpSignIn
                                                                 :)
                           
                           };

    if(url){
        BaseUrl = url;
        LogDebug(@"BaseUrl:%@",url);
    }else{
        LogDebug(@"Enter valid BaseUrl");
    }
    
    self = [super initWithRequestSelectorMapping:dict
                                         baseUrl:url];
    
    //
    if (vanityUrl){
        VanityUrl = vanityUrl;
        LogDebug(@"VanityUrl:%@",VanityUrl);
    }else{
        LogDebug(@"Enter valid VanityUrl");
    }
    
    //
    if (signInId){
        SignInId = signInId;
        LogDebug(@"SignInId:%@",SignInId);
    }else{
        LogDebug(@"Enter valid SignInId");
    }
    
    if (signInSecretKey){
        SignInSecretKey = signInSecretKey;
        LogDebug(@"SignInSecretKey:%@",SignInSecretKey);
    }else{
        LogDebug(@"Enter valid SignInSecretKey");
    }
    
    //
    if (subscriptionId){
        SubscriptionId = subscriptionId;
        LogDebug(@"SubscriptionId:%@",SubscriptionId);
    }else{
        LogDebug(@"Enter valid SubscriptionId");
    }
    
    if (subscriptionSecretKey){
        SubscriptionSecretKey = subscriptionSecretKey;
        LogDebug(@"SubscriptionSecretKey:%@",SubscriptionSecretKey);
    }else{
        LogDebug(@"Enter valid SubscriptionSecretKey");
    }
    
    //
    if (returnUrl){
        ReturnUrl = returnUrl;
        LogDebug(@"ReturnUrl:%@",ReturnUrl);
    }else{
        LogDebug(@"Enter valid ReturnUrl");
    }
    
    return self;
}


// 010615 Dynamic Oauth keys init with base URL

+ (NSString*)getDynamicSignInId{
    return SignInId;
}

+ (NSString*)getDynamicSignInSecretKey{
    return SignInSecretKey;
}

+ (NSString*)getDynamicSubscriptionId{
    return SubscriptionId;
}

+ (NSString*)getDynamicSubscriptionSecretKey{
    return SubscriptionSecretKey;
}

+ (NSString*)getBaseURL{
    return BaseUrl;
}

+ (NSString*)getVanityUrl{
    return VanityUrl;
}

+ (NSString*)getReturnUrl{
    return ReturnUrl;
}

#pragma mark - handlers

-(void)handleBindOauthToken:(CTSRestCoreResponse *)response{
    NSError* error = response.error;
    JSONModelError* jsonError;
    // signup flow
    if (error == nil) {
        CTSOauthTokenRes* resultObject =
        [[CTSOauthTokenRes alloc] initWithString:response.responseString
                                           error:&jsonError];
        [CTSOauthManager saveSignupToken:resultObject.accessToken];
        [self requestInternalBindUserName:userNameBind mobile:mobileBind];
    } else {
        [self bindUserHelperUsername:userNameBind error:error];
        return;
    }

    //if success
    //save singup oauth token
    //call for bind
    //else
    //call bind helper with error
    
    
    
    
}


-(void)handleBindUser:(CTSRestCoreResponse*)response{
    
    NSError* error = response.error;
    // signup flow
    if (error == nil) {
        [self requestBindSigninUsername:userNameBind ];
    } else {
        [self bindUserHelperUsername:userNameBind error:error];
        return;
    }

    //if success call
    //call for sing in
    //else
    //call bind helper
    
    
    
}

-(void)handleBindSignIn:(CTSRestCoreResponse *)response{

    //if no error
    //save singin token
    
    //call helper for binduser
    
    NSError* error = response.error;
    JSONModelError* jsonError;
    // signup flow
    if (error == nil) {
        CTSOauthTokenRes* resultObject =
        [[CTSOauthTokenRes alloc] initWithString:response.responseString
                                           error:&jsonError];
        [CTSOauthManager saveBindSignInOauth:resultObject];
         }
    [self bindUserHelperUsername:userNameBind error:error];
    
}

-(void)handleBindSignInAsync:(CTSRestCoreResponse *)response{
    NSError* errorSignIn = response.error;
    JSONModelError* jsonError;
 
    if(errorSignIn == nil){
        CTSOauthTokenRes* resultObject =
        [[CTSOauthTokenRes alloc] initWithString:response.responseString
                                           error:&jsonError];
        [CTSOauthManager saveBindSignInOauth:resultObject];
    }
    if(errorSignIn == nil){
        CTSProfileLayer *profileLayer = [[CTSProfileLayer alloc] init];
        [profileLayer requestActivatePrepaidAccount:^(BOOL isActivated, NSError *error) {
            [self bindSigninAsyncHelperError:errorSignIn];
        }];
    }
    else{
        [self bindSigninAsyncHelperError:errorSignIn];
    }
}





- (void)handleReqSignupOauthToken:(CTSRestCoreResponse*)response {
  NSError* error = response.error;
  JSONModelError* jsonError;
  // signup flow
  if (error == nil) {
    CTSOauthTokenRes* resultObject =
        [[CTSOauthTokenRes alloc] initWithString:response.responseString
                                           error:&jsonError];
    [CTSOauthManager saveSignupToken:resultObject.accessToken];

    [self requestInternalSignupMobile:mobileSignUp email:userNameSignup];
  } else {
    [self signupHelperUsername:userNameSignup
                         oauth:[CTSOauthManager readOauthToken]
                         error:error];
    return;
  }
}






- (void)handleReqChangePassword:(CTSRestCoreResponse*)response {
  [self changePasswordHelper:response.error];
}

//OLD IMPLEMENTATION BEFORE PREPAID FLOW
//- (void)handleReqSigninOauthToken:(CTSRestCoreResponse*)response {
//  NSError* error = response.error;
//  JSONModelError* jsonError;
//  // signup flow
//  if (error == nil) {
//    CTSOauthTokenRes* resultObject =
//        [[CTSOauthTokenRes alloc] initWithString:response.responseString
//                                           error:&jsonError];
//    [resultObject logProperties];
//    [CTSOauthManager saveOauthData:resultObject];
//    if (wasSignupCalled == YES) {
//      // in case of sign up flow
//
//      [self usePassword:passwordSignUp
//          hashedUsername:[self generateBigIntegerString:userNameSignup]];
//      wasSignupCalled = NO;
//    } else {
//      // in case of sign in flow
//
//      [self signinHelperUsername:userNameSignIn
//                           oauth:[CTSOauthManager readOauthToken]
//                           error:error];
//    }
//  } else {
//    if (wasSignupCalled == YES) {
//      // in case of sign up flow
//      [self signupHelperUsername:userNameSignup
//                           oauth:[CTSOauthManager readOauthToken]
//                           error:error];
//    } else {
//      // in case of sign in flow
//
//      [self signinHelperUsername:userNameSignIn
//                           oauth:[CTSOauthManager readOauthToken]
//                           error:error];
//    }
//  }
//}




- (void)handleReqSigninOauthToken:(CTSRestCoreResponse*)response {
    NSError* error = response.error;
    JSONModelError* jsonError;
    // signup flow
    if (error == nil) {
        CTSOauthTokenRes* resultObject =
        [[CTSOauthTokenRes alloc] initWithString:response.responseString
                                           error:&jsonError];
        [CTSOauthManager saveOauthData:resultObject];
        if (wasSignupCalled == YES) {
            // in case of sign up flow_ not being used for prepaid
            
            [self usePassword:passwordSignUp
               hashedUsername:[self generateBigIntegerString:userNameSignup]];
            wasSignupCalled = NO;
        } else {
            [self proceedForTokensCall];

//            if(!isInLink){
//                [self proceedForTokensCall];
//            }
//            else {
//                [self signinHelperUsername:userNameSignIn
//                                     oauth:[CTSOauthManager readOauthToken]
//                                     error:error];
//            }
        }
    } else {
        if (wasSignupCalled == YES) {
            // in case of sign up flow
            [self signupHelperUsername:userNameSignup
                                 oauth:[CTSOauthManager readOauthToken]
                                 error:error];
        } else {
            // in case of sign in flow
            
            [self signinHelperUsername:userNameSignIn
                                 oauth:[CTSOauthManager readOauthToken]
                                 error:error];
        }
    }
}



-(void)handleOtpSignIn:(CTSRestCoreResponse*)response{
    __block NSError* errorSignIn = response.error;
    JSONModelError* jsonError;
    // signup flow
    if (errorSignIn == nil) {
        CTSOauthTokenRes* resultObject =
        [[CTSOauthTokenRes alloc] initWithString:response.responseString
                                           error:&jsonError];
        [CTSOauthManager saveOauthData:resultObject];
    }
    if(errorSignIn == nil){
        CTSProfileLayer *profileLayer = [[CTSProfileLayer alloc] init];
        [profileLayer requestActivatePrepaidAccount:^(BOOL isActivated, NSError *error) {
            [self otpSignInHelperError:errorSignIn];
        }];
    }
    else{
        [self otpSignInHelperError:errorSignIn];
    }
}


-(void)proceedForTokensCall{
    
    CTSProfileLayer *profileLayer = [[CTSProfileLayer alloc] init];
    [profileLayer requestActivatePrepaidAccount:^(BOOL isActivated, NSError *error) {
        //if get balance is succesfull
        //get coockie
        LogTrace(@" GetBalance Successful ");
        LogTrace(@"isActivated %d",isActivated);
        LogTrace(@"error %@",error);
        
        if(YES){
            
            [self requestCitrusPaySignin:userNameSignIn password:passwordSignin completionHandler:^(NSError *error) {
                
                LogTrace(@" requestCitrusPaySignin ");
                
                [self signinHelperUsername:userNameSignIn
                                     oauth:[CTSOauthManager readOauthToken]
                                     error:error];
            }];
        }
        else{
            LogTrace(@" GetBalance Failed ");
            
            
            
            [self signinHelperUsername:userNameSignIn
                                 oauth:[CTSOauthManager readOauthToken]
                                 error:error];
            
        }
    }];
}



- (void)handleReqSignupStageOneComplete:(CTSRestCoreResponse*)response {
  NSError* error = response.error;

  // change password
  //[self usePassword:TEST_PASSWORD for:SET_FIRSTTIME_PASSWORD];

  // get singn in oauth token for password use use hashed email
  // use it for sending the change password so that the password is set(for
  // old password use username)

  // always use this acess token

  if (error == nil) {
    // signup flow - now sign in

    [self
        requestSigninWithUsername:userNameSignup
                         password:[self generateBigIntegerString:userNameSignup]
                completionHandler:nil];

    //    [self requestSigninWithUsername:userNameSignup
    //                           password:passwordSignUp
    //                  completionHandler:nil];

  } else {
    [self signupHelperUsername:userNameSignup
                         oauth:[CTSOauthManager readOauthToken]
                         error:error];
  }
}

- (void)handleReqUsePassword:(CTSRestCoreResponse*)response {
  LogTrace(@"password changed ");

  [self signupHelperUsername:userNameSignup
                       oauth:[CTSOauthManager readOauthToken]
                       error:response.error];
}

- (void)handleReqRequestForPasswordReset:(CTSRestCoreResponse*)response {
  LogTrace(@"password change requested");
  [self resetPasswordHelper:response.error];
}

- (void)handleIsUserCitrusMember:(CTSRestCoreResponse*)response {
  if (response.error == nil) {
    [self isUserCitrusMemberHelper:[CTSUtility toBool:response.responseString]
                             error:nil];

  } else {
    [self isUserCitrusMemberHelper:NO error:response.error];
  }
}


-(void)handleCitrusPaySignin:(CTSRestCoreResponse *)response{
    [self citrusPaySigninHelper:(NSError *)response.data];
}

-(void)handleSignupAsyncOauthToken:(CTSRestCoreResponse *)response{
    NSError* error = response.error;
    JSONModelError* jsonError;
    // signup flow
    if (error == nil) {
        CTSOauthTokenRes* resultObject =
        [[CTSOauthTokenRes alloc] initWithString:response.responseString
                                           error:&jsonError];
        [CTSOauthManager saveSignupToken:resultObject.accessToken];
        
    }
    
    
    [self signupAsyncOauthTokenHelperError:error];

}

-(void)handleNewSignup:(CTSRestCoreResponse *)response{
    [self newSignupHelper:(NSError *)response.error];
}

-(void)handleOTPVerfication:(CTSRestCoreResponse*)response {
    NSError* error = response.error;
    if(error == nil){
        [self otpVerificationHelper:[CTSUtility convertToBool:response.responseString] error:nil];
    }
    else{
        [self otpVerificationHelper:NO error:error];
    }
    
}

-(void)handleOTPRegeneration:(CTSRestCoreResponse*)response{
    NSError* error = response.error;
    JSONModelError* jsonError;
    CTSResponse *genResponse;
    if(!error){
        genResponse =[[CTSResponse alloc] initWithString:response.responseString error:&jsonError];
        
        if(jsonError  == nil){
            error = [CTSError convertCTSResToErrorIfNeeded:genResponse];
        }
        else {
            error = jsonError;
        }
        if(error){
            genResponse = nil;
        }
    }

    [self otpRegenerationHelper:genResponse error:error];
}

-(void)handleOTPGeneration:(CTSRestCoreResponse*)response{
    NSError* error = response.error;
    JSONModelError* jsonError;
    CTSResponse *genResponse;
    if(!error){
        genResponse =[[CTSResponse alloc] initWithString:response.responseString error:&jsonError];
        if(jsonError  == nil){
        error = [CTSError convertCTSResToErrorIfNeeded:genResponse];
        }
        else {
            error = jsonError;
        }
        if(error){
            genResponse = nil;
        }
    }
    
    
    
    
    [self otpGenerateHelper:genResponse error:error];
}


#pragma mark - helper methods
- (void)signinHelperUsername:(NSString*)username
                       oauth:(NSString*)token
                       error:(NSError*)error {
  ASSigninCallBack callBack =
      [self retrieveAndRemoveCallbackForReqId:SigninOauthTokenReqId];

    userNameSignIn = @"";
    passwordSignin = @"";

    
  if (error != nil && isInLink == NO) {
    //[CTSOauthManager resetOauthData];
  }

  if (callBack != nil) {
    callBack(username, token, error);
  } else {
    [delegate auth:self
        didSigninUsername:username
               oauthToken:token
                    error:error];
  }
}

- (void)signupHelperUsername:(NSString*)username
                       oauth:(NSString*)token
                       error:(NSError*)error {
  ASSigninCallBack callBack =
      [self retrieveAndRemoveCallbackForReqId:SignupOauthTokenReqId];

  wasSignupCalled = NO;

  if (error != nil && isInLink == NO) {
    [CTSOauthManager resetOauthData];
  }

  if (callBack != nil) {
    callBack(username, token, error);
  } else {
    [delegate auth:self
        didSignupUsername:username
               oauthToken:token
                    error:error];
  }

  [self resetSignupCredentials];
}

- (void)changePasswordHelper:(NSError*)error {
  ASChangePassword callback =
      [self retrieveAndRemoveCallbackForReqId:ChangePasswordReqId];

  if (callback != nil) {
    callback(error);
  } else {
    [delegate auth:self didChangePasswordError:error];
  }
}


- (void)setPasswordHelper:(NSError*)error {
    ASSetPassword callback =
    [self retrieveAndRemoveCallbackForReqId:SetPasswordReqId];
        if (callback != nil) {
        callback(error);
    } else {
        [delegate auth:self didSetPasswordError:error];
    }
}

- (void)isUserCitrusMemberHelper:(BOOL)isMember error:(NSError*)error {
  ASIsUserCitrusMemberCallback callback =
      [self retrieveAndRemoveCallbackForReqId:IsUserCitrusMemberReqId];
  if (callback != nil) {
    callback(isMember, error);
  } else {
    [delegate auth:self didCheckIsUserCitrusMember:isMember error:error];
  }
}

- (void)resetPasswordHelper:(NSError*)error {
  ASResetPasswordCallback callback =
      [self retrieveAndRemoveCallbackForReqId:RequestForPasswordResetReqId];
  if (callback != nil) {
    callback(error);
  } else {
    [delegate auth:self didRequestForResetPassword:error];
  }
}


- (void)bindUserHelperUsername:(NSString *)userName error:(NSError*)error {
    ASBindUserCallback callback =
    [self retrieveAndRemoveCallbackForReqId:BindUserRequestId];
    if (callback != nil) {
        callback(userName,error);
    } else {
        [delegate auth:self didBindUser:userName error:error];
    }
    [self resetBindData];
}


-(void)bindSigninAsyncHelperError:(NSError *)error{
    ASBindSignIn callback = [self retrieveAndRemoveCallbackForReqId:BindSigninAsyncReqId];
    callback(error);

}


-(void)citrusPaySigninHelper:(NSError *)error{
    ASCitrusSigninCallBack callback =
    [self retrieveAndRemoveCallbackForReqId:CitruPaySigniInReqId];
    if (callback != nil) {
        callback(error);
    } else {
        [delegate auth:self didCitrusSigninInerror:error];
    }

}



-(void)linkUserHelper:(CTSLinkUserRes *)linkUserRes error:(NSError *)error{
    
    [self resetLinkData];
    
    ASLinkUserCallBack callback = [self retrieveAndRemoveCallbackForReqId:LinkUserReqId];
    if(callback != nil){
        callback(linkUserRes,error);
    }
    else{
        [delegate auth:self didLinkUser:linkUserRes error:error];
    
    }
}

-(void)signupAsyncOauthTokenHelperError:(NSError *)error{
    ASAsyncSignUpOauthTokenCallBack callback = [self retrieveAndRemoveCallbackForReqId:SignupOauthAsynTokenReqId];
    callback(error);
}

-(void)newSignupHelper:(NSError *)error{
    ASSignupNewCallBack callback = [self retrieveAndRemoveCallbackForReqId:SignupNewReqId];
    
    if(callback != nil){
        callback(error);
    }
    else{
        [delegate auth:self didSignup:error];
    }


}

-(void)otpVerificationHelper:(BOOL)isVerified error:(NSError *)error{
    ASOtpVerificationCallback callback = [self retrieveAndRemoveCallbackForReqId:OTPVerificationRequestId];
    if(callback != nil){
        callback(isVerified,error);
    }
    else{
        [delegate auth:self didVerifyOTP:isVerified error:error];
    }
    
}


-(void)otpRegenerationHelper:(CTSResponse *)response error:(NSError *)error{
    ASOtpRegenerationCallback callback = [self retrieveAndRemoveCallbackForReqId:OTPRegenerationRequestId];
    if(callback != nil){
        callback(response,error);
    }
    else{
        [delegate auth:self didRegenerateOTPWitherror:error];
    }
}


-(void)otpGenerateHelper:(CTSResponse *)response error:(NSError *)error{
    ASGenerateOtpCallBack callback = [self retrieveAndRemoveCallbackForReqId:GenerateOTPReqId];
    if(callback != nil){
        callback(response,error);
    }
    else{
        [delegate auth:self didGenerateOTPWithError:error];
    }

}

-(void)linkHelper:(CTSLinkRes *)response error:(NSError *)error{
    ASLinkCallback callback = [self retrieveAndRemoveCallbackForReqId:LinkReqId];
    if(callback != nil){
        callback(response,error);
    }
    else{
        [delegate auth:self didLink:response error:error];
    }
}


-(void)otpSignInHelperError:(NSError *)error{
    ASOtpSigninCallBack callback = [self retrieveAndRemoveCallbackForReqId:OtpSignInReqId];
    if(callback != nil){
        callback(error);
    }else {
        [delegate auth:self didSignInWithOtpError:error];
    }


}


#pragma mark - housekeeping methods
-(BOOL)isBadCredentials:(NSError *)error{
    
    if([CTSUtility string:[error localizedDescription] containsString:@"Bad credentials"]){
    
        return YES;
    }
    return NO;

}
-(void)resetLinkData{
    isInLink = NO;
}

- (void)resetBindData {
    userNameBind = @"";
    mobileBind = @"";
}

-(void)resetSignIn{
   userNameSignIn = @"";
   passwordSignin = @"";
}

- (void)resetSignupCredentials {
  userNameSignup = @"";
  mobileSignUp = @"";
  passwordSignUp = @"";
}


@end
