/*
 * The contents of this file are subject to the terms of the Common Development and
 * Distribution License (the License). You may not use this file except in compliance with the
 * License.
 *
 * You can obtain a copy of the License at legal/CDDLv1.0.txt. See the License for the
 * specific language governing permission and limitations under the License.
 *
 * When distributing Covered Software, include this CDDL Header Notice in each file and include
 * the License file at legal/CDDLv1.0.txt. If applicable, add the following below the CDDL
 * Header, with the fields enclosed by brackets [] replaced by your own identifying
 * information: "Portions copyright [year] [name of copyright owner]".
 *
 * Copyright 2016 ForgeRock AS.
 */

#import "FRAError.h"
#import "FRAIdentity.h"
#import "FRAIdentityDatabase.h"
#import "FRAMechanismFactory.h"
#import "FRAMessageUtils.h"
#import "FRAMockURLProtocol.h"
#import "FRAPushMechanism.h"
#import "FRAPushMechanismFactory.h"
#import "FRAQRUtils.h"
#import "FRASerialization.h"

/*! QR code key for the secret. */
NSString *const SECRET_QR_KEY = @"s";
/*! QR code key for the authentication endpoint url. */
NSString *const AUTHENTICATION_ENDPOINT_URL_QR_KEY = @"a";
/*! QR code key for the regsitration endpoint url. */
NSString *const REGISTRATION_ENDPOINT_URL_QR_KEY = @"r";
/*! QR code key for the message. */
NSString *const MESSAGE_ID_QR_KEY = @"m";
/*! QR code key for the background colour of the mechanism. */
NSString *const BACKGROUND_COLOUR_QR_KEY = @"b";
/*! QR code key for the registration challange. */
NSString *const REGISTRATION_CHALLENGE_QR_KEY = @"c";
/*! QR code key for the registration challange. */
NSString *const REGISTRATION_LOAD_BALLANCE_KEY = @"l";
/*! QR code key for the mechanism image. */
NSString *const IMAGE_QR_KEY = @"image";
/*! QR code key for the issuer name. */
NSString *const ISSUER_QR_KEY = @"issuer";

static BOOL SUCCESS = YES;
static BOOL FAILURE = NO;

@interface FRAPushMechanismFactory ()

@property (strong, nonatomic) FRANotificationGateway *gateway;

@end

@implementation FRAPushMechanismFactory {
    FRANotificationGateway* _gateway;
}

#pragma mark -
#pragma mark Lifecyle

- (instancetype)initWithGateway:(FRANotificationGateway *)gateway{
    self = [super init];
    if (self) {
        self.gateway = gateway;
    }
    return self;
}

#pragma mark -
#pragma mark Factory Methods

- (NSString *)utf8StringFromData:(NSData *)data {
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (FRAMechanism *) buildMechanism:(NSURL *)uri database:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel handler:(void (^)(BOOL, NSError *))handler error:(NSError *__autoreleasing *)error {
    
    if (![self isValid:self.gateway.deviceToken]) {
        *error = [FRAError createError:NSLocalizedString(@"Cannot register while notifications are disabled or the device is offline", nil) code:FRAMissingDeviceId];
        return nil;
    }
    
    NSDictionary * query = [self readQRCode:uri];
    
    NSString *secret = [query objectForKey:SECRET_QR_KEY];
    NSString *regEndpoint = [self utf8StringFromData:[FRAQRUtils decodeURL:[query objectForKey:REGISTRATION_ENDPOINT_URL_QR_KEY]]];
    NSString *authEndpoint = [self utf8StringFromData:[FRAQRUtils decodeURL:[query objectForKey:AUTHENTICATION_ENDPOINT_URL_QR_KEY]]];
    NSString *messageId = [query objectForKey:MESSAGE_ID_QR_KEY];
    NSString *backgroundColor = [query objectForKey:BACKGROUND_COLOUR_QR_KEY];
    NSString *challenge = [FRAQRUtils replaceCharactersForURLDecoding:[query objectForKey:REGISTRATION_CHALLENGE_QR_KEY]];
    NSString *loadBalancer = [self utf8StringFromData:[FRAQRUtils decodeURL:[query objectForKey:REGISTRATION_LOAD_BALLANCE_KEY]]];
    NSString *image = [self utf8StringFromData:[FRAQRUtils decodeURL:[query objectForKey:IMAGE_QR_KEY]]];
    NSString *issuer = [self utf8StringFromData:[FRAQRUtils decodeURL:[query objectForKey:ISSUER_QR_KEY]]];
    NSString *_label = [query objectForKey:@"_label"];
    
    if (![self isValidSecret:secret] || ![self isValid:regEndpoint] || ![self isValid:authEndpoint] || ![self isValid:messageId] || ![self isValid:challenge] || ![self isValid:issuer]) {
        *error = [FRAError createError:NSLocalizedString(@"Invalid QR code", nil) code:FRAInvalidQRCode];
        return nil;
    }

    FRAPushMechanism* mechanism = [FRAPushMechanism pushMechanismWithDatabase:database identityModel:identityModel authEndpoint:authEndpoint secret:secret];
    FRAIdentity *identity = [self identityWithIssuer:issuer accountName:_label identityModel:identityModel backgroundColor:backgroundColor image:image database:database error:error];

    if (![identity addMechanism:mechanism error:error]) {
        return nil;
    }
    
    [self registerMechanismWithEndpoint:regEndpoint secret:secret challenge:challenge messageId:messageId mechanismUid:mechanism.mechanismUID identity:identity mechanism:mechanism identityModel:identityModel loadBalancerCookieData:loadBalancer handler:handler];

    return mechanism;
}

- (BOOL)isValidSecret:(NSString *)secret {
    return [self isValid:secret] && [FRAQRUtils isBase64:[FRAQRUtils replaceCharactersForURLDecoding:secret]];
}

- (BOOL)isValid:(NSString *)info {
    return info.length > 0;
}

- (NSDictionary *) readQRCode:(NSURL *)uri {
    
    NSString* scheme = [uri scheme];
    if (scheme == nil || ![scheme isEqualToString:@"pushauth"]) {
        return nil;
    }
    NSString* _type = [uri host];
    if (_type == nil || ![_type isEqualToString:[FRAPushMechanism mechanismType]]) {
        return nil;
    }
    // Get the path and strip it of its leading '/'
    NSString* path = [uri path];
    if (path == nil) {
        return nil;
    }
    while ([path hasPrefix:@"/"]) {
        path = [path substringFromIndex:1];
    }
    if ([path length] == 0) {
        return nil;
    }
    // Get issuer and label
    NSArray* array = [path componentsSeparatedByString:@":"];
    if (array == nil || [array count] == 0) {
        return nil;
    }
    NSString* _issuer;
    NSString* _label;
    if ([array count] > 1) {
        _issuer = [FRAQRUtils decode:[array objectAtIndex:0]];
        _label = [FRAQRUtils decode:[array objectAtIndex:1]];
    } else {
        _issuer = @"";
        _label = [FRAQRUtils decode:[array objectAtIndex:0]];
    }
    
    // Parse query
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
    array = [[uri query] componentsSeparatedByString:@"&"];
    for (NSString *kv in array) {
        // Value can contain '=' symbols, so look for first symbol.
        NSRange index = [kv rangeOfString:@"="];
        if (index.location == NSNotFound) {
            continue;
        }
        NSString *name = [kv substringToIndex:index.location];
        NSString *value = [kv substringFromIndex:index.location + index.length];
        [query setValue:value forKey:name];
    }
    
    [query setValue:_issuer forKey:@"_issuer"];
    [query setValue:_label forKey:@"_label"];
    
    return query;
}

- (FRAIdentity *)identityWithIssuer:(NSString *)issuer accountName:(NSString *)accountName identityModel:(FRAIdentityModel *)identityModel backgroundColor:(NSString *)backgroundColor image:(NSString *)image database:(FRAIdentityDatabase *)database error:(NSError *__autoreleasing *)error {
    FRAIdentity *identity = [identityModel identityWithIssuer:issuer accountName:accountName];
    if (!identity) {
        identity = [FRAIdentity identityWithDatabase:database identityModel:identityModel accountName:accountName issuer:issuer image:[NSURL URLWithString:image] backgroundColor:backgroundColor];
        if (![identityModel addIdentity:identity error:error]) {
            return nil;
        }
    }
    
    return identity;
}

- (BOOL)supports:(NSURL *)uri {
    NSString *scheme = [uri scheme];
    if (scheme == nil || ![scheme isEqualToString:@"pushauth"]) {
        return NO;
    }
    return YES;
}

- (NSString *)getSupportedProtocol {
    return @"pushauth";
}

- (void)registerMechanismWithEndpoint:(NSString *)regEndpoint secret:(NSString *)secret challenge:(NSString *)c messageId:(NSString *)messageId mechanismUid:(NSString *)uid identity:(FRAIdentity *)identity mechanism:(FRAMechanism *)mechanism identityModel:(FRAIdentityModel *)identityModel loadBalancerCookieData:(NSString *)loadBalancerCookieData handler:(void(^)(BOOL, NSError *))handler {
    
    [FRAMessageUtils respondWithEndpoint:regEndpoint
                            base64Secret:secret
                               messageId:messageId
                  loadBalancerCookieData:loadBalancerCookieData
                                    data:@{@"response":[FRAMessageUtils generateChallengeResponse:c secret:secret],
                                           @"mechanismUid":uid,
                                           @"deviceId":self.gateway.deviceToken,
                                           @"deviceType":@"ios",
                                           @"communicationType":@"apns"
                                           }
                                 handler:^(NSInteger statusCode, NSError *error) {
                                     if (200 != statusCode) {
                                         error = [FRAError createError:@"Failed to contact server for registration" code:FRANetworkFailure underlyingError:error];
                                         [identity removeMechanism:mechanism error:&error];
                                         [self invokeRegistrationHandler:handler result:FAILURE error:error];
                                     } else {
                                         [self invokeRegistrationHandler:handler result:SUCCESS error:nil];
                                     }
                                 }];
}

- (void)invokeRegistrationHandler:(void(^)(BOOL, NSError *))handler result:(BOOL)result error:(NSError *) error {
    if (handler) {
        handler(result, error);
    }
}

@end