//
//  CTSError.m
//  CTS iOS Sdk
//
//  Created by Yadnesh Wankhede on 26/06/14.
//  Copyright (c) 2014 Citrus. All rights reserved.
//

#import "CTSError.h"

@implementation CTSError

+ (NSError*)getErrorForCode:(CTSErrorCode)code {
  NSString* errorDescription = @"CitrusDefaultError";

  switch (code) {
    case UserNotSignedIn:
      errorDescription = @"This proccess cannot be completed without signing "
          @"in, Please signin";
      break;
    case EmailNotValid:
      errorDescription =
          @"email adress format not valid,expected e.g. rob@gmail.com";
      break;
    case MobileNotValid:
      errorDescription = @"mobile number not valid, expected 10 digits";
      break;
    case CvvNotValid:
      errorDescription = @"cvv format not valid, expected 3 digits for non "
          @"amex and 4 for amex";
      break;
    case CardNumberNotValid:
      errorDescription = @"card number not valid";
      break;
    case ExpiryDateNotValid:
      errorDescription = @"wrong expiry date format,expected - \"mm/yyyy\" ";
      break;
    case ServerErrorWithCode:
      errorDescription = @"server sent error code";
          break;

    case InvalidParameter:
      errorDescription = @"invalid parameter passed to method";
          break;

    case OauthTokenExpired:
      errorDescription = @"Oauth Token expired, Please refresh it from server";
          break;

    case CantFetchSignupToken:
      errorDescription = @"Can not fetch Signup Oauth token from merchant";
          break;

      case TokenMissing:
          errorDescription = @"Token for payment is missing";
          break;

          case WrongBill:
          errorDescription = @"Bill not valid";
          break;
      case NoViewController:
          errorDescription = @"ReturnViewController not valid";
          break;
      case ReturnUrlNotValid:
          errorDescription = @"Return url not valid";
          break;
      case PrepaidBillFetchFailed:
          errorDescription = @"Couldn't fetch prepaid bill";
          break;
      case NoOrMoreInstruments:
          errorDescription = @"Zero or More than one payment instruments";
          break;
      case AmountNotValid:
          errorDescription = @"Amount not valid";
          break;
      case BankAccountNotValid:
          errorDescription = @"Bank Account is not valid";
          break;
          case ReturnUrlCallbackNotValid:
          errorDescription = @"CitrusPay Completed the Transaction, Merchant Server did Not Return Data from \"postiOSResponse()\"";
          
          break;
          case TransactionForcedClosed:
          errorDescription = @"Transaction was Forced to End";
          break;
          case NoCookieFound:
          errorDescription = @"Cookie not found, Please signin";
          break;
          case TransactionAlreadyInProgress:
          errorDescription = @"Transaction Already In Progress";
          
          break;
      case InsufficientBalance:
          errorDescription = @"Insufficient Balance Please add Money in Citrus Account";
          break;
      case DeleteCardNumberNotValid:
          errorDescription = @"Card number not valid, last four digits are expected";
          break;

      default:
      break;
  }
  NSDictionary* userInfo = @{NSLocalizedDescriptionKey : errorDescription};

  return
      [NSError errorWithDomain:CITRUS_ERROR_DOMAIN code:code userInfo:userInfo];
}

+ (NSError*)getServerErrorWithCode:(int)errorCode
                          withInfo:(NSDictionary*)information {
  NSMutableDictionary* userInfo =
      [[NSMutableDictionary alloc] initWithDictionary:information];

  [userInfo addEntriesFromDictionary:@{
    NSLocalizedDescriptionKey :
        [NSString stringWithFormat:@"Server threw an error,code %d", errorCode]
        }];

  return [NSError errorWithDomain:CITRUS_ERROR_DOMAIN
                             code:ServerErrorWithCode
                         userInfo:userInfo];
}


+(NSString *)getFakeJsonForCode:(CTSErrorCode)errorCode{
    NSString* fakeErrorJson = nil;
    
    switch (errorCode) {
        case InternetDown:
            fakeErrorJson = @"{\"description\":\"could not connect to server\",\"type\":\"server error\"}";
            break;

        default:
            fakeErrorJson = @"{\"description\":\"NA\",\"type\":\"NA\"}";

            break;
    }
    return fakeErrorJson;

}


+(NSError *)errorForStatusCode:(int)statusCode{
    NSString *errorDescription ;
    switch (statusCode) {
        case 200:
            errorDescription = @"Request Complete";
        case 400:
           errorDescription = @"Bad Request";
            break;
        case 401:
            errorDescription = @"Unauthorized Access";
            break;
        case 403:
            errorDescription = @"Access forbidden";
            break;
        case 503:
            errorDescription = @"Server Unavailable";
            break;
        case 504:
            errorDescription = @"Gateway Timeout";
            break;
        default:
            errorDescription = @"Oops Something went wrong";

            break;
    }
    
    NSDictionary* userInfo = @{NSLocalizedDescriptionKey : errorDescription};
    
    return
    [NSError errorWithDomain:CITRUS_ERROR_DOMAIN code:statusCode userInfo:userInfo];
}

+(NSError *)convertToError:(CTSPaymentTransactionRes *)ctsPaymentTxRes{
    NSDictionary* userInfo = @{NSLocalizedDescriptionKey : ctsPaymentTxRes.txMsg};

        return
    [NSError errorWithDomain:CITRUS_ERROR_DOMAIN code:(NSInteger)ctsPaymentTxRes.pgRespCode userInfo:userInfo];

}
+(NSError *)convertCTSResToErrorIfNeeded:(CTSResponse *)response{
    NSError *error = nil;
    if([response isError]){
        NSDictionary* userInfo = @{NSLocalizedDescriptionKey : response.responseMessage};
        error =     [NSError errorWithDomain:CITRUS_ERROR_DOMAIN code:(NSInteger)[response errorCode] userInfo:userInfo];
    }
    return error;
}




@end
