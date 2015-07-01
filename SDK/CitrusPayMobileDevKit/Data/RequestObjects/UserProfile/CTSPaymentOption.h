//
//  CTSPaymentOption.h
//  RestFulltester
//
//  Created by Yadnesh Wankhede on 20/06/14.
//  Copyright (c) 2014 Citrus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTSElectronicCardUpdate.h"
#import "CTSNetBankingUpdate.h"
#import "CTSTokenizedPayment.h"
#import "JSONModel.h"
#import "CTSUtility.h"
#import "CTSPaymentMode.h"
#import "CTSPaymentToken.h"
#import "CTSPaymentLayerConstants.h"


typedef enum {
    MemberCard,
    MemberNetbank,
    TokenizedCard,
    TokenizedNetbank,
    CitrusPay,
    UndefinedPayment
} CTSPaymentType;

@interface CTSPaymentOption : JSONModel
//@property(nonatomic, strong) NSString* type, *cardName, *ownerName, *number,
//    *bankName, *expiryDate, *scheme;

@property(nonatomic, strong) NSString<Optional>* type;
@property(nonatomic, strong) NSString<Optional>* name;
@property(nonatomic, strong) NSString<Optional>* owner;
@property(nonatomic, strong) NSString<Optional>* bank;
@property(nonatomic, strong) NSString<Optional>* number;
@property(nonatomic, strong) NSString<Optional>* expiryDate;
@property(nonatomic, strong) NSString<Optional>* scheme;
@property(nonatomic, strong) NSString<Optional>* token;
@property(nonatomic, strong) NSString<Optional>* mmid;
@property(nonatomic, strong) NSString<Optional>* impsRegisteredMobile;
@property(nonatomic, strong) NSString<Optional>* cvv;
@property(nonatomic, strong) NSString<Optional>* code;

-(instancetype)initCitrusPayWithEmail:(NSString *)email;
- (instancetype)initWithNetBanking:(CTSNetBankingUpdate*)bankDetails;
- (instancetype)initWithCard:(CTSElectronicCardUpdate*)eCard;
- (instancetype)initWithTokenized:(CTSTokenizedPayment*)tokenizedPayment;
- (CTSErrorCode)validate;
-(CTSPaymentType)fetchPaymentType;
-(CTSPaymentToken*)fetchPaymentToken;
@end
@protocol CTSPaymentOption;
