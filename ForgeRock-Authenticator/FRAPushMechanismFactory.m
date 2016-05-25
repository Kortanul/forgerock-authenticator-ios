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

#import "FRAPushMechanismFactory.h"
#import "FRAMechanismFactory.h"
#import "FRAPushMechanism.h"
#import "FRAIdentityDatabase.h"
#import "FRAIdentity.h"
#import "FRAMessageUtils.h"
#import "FRAMockURLProtocol.h"
#import "FRAQRUtils.h"

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
NSString *const REGISTRATION_CHALLANGE_QR_KEY = @"c";
/*! QR code key for the mechanism image. */
NSString *const IMAGE_QR_KEY = @"image";
/*! QR code key for the issuer name. */
NSString *const ISSUER_QR_KEY = @"issuer";

@implementation FRAPushMechanismFactory {
    FRANotificationGateway* _gateway;
}

#pragma mark -
#pragma mark Lifecyle

- (instancetype)initWithGateway:(FRANotificationGateway *)gateway{
    self = [super init];
    if (self) {
        _gateway = gateway;
    }
    return self;
}

#pragma mark -
#pragma mark Fractory Methods

- (FRAMechanism *) buildMechanism:(NSURL *)uri database:(FRAIdentityDatabase *)database model:(FRAIdentityModel *)model {
    
    NSDictionary * query = [self readQRCode:uri];
    
    NSString *secret = [query objectForKey:SECRET_QR_KEY];
    NSString *regEndpoint = [FRAQRUtils decodeURL:[query objectForKey:REGISTRATION_ENDPOINT_URL_QR_KEY]];
    NSString *authEndpoint = [FRAQRUtils decodeURL:[query objectForKey:AUTHENTICATION_ENDPOINT_URL_QR_KEY]];
    NSString *messageId = [query objectForKey:MESSAGE_ID_QR_KEY];
    NSString *backgroundColor = [query objectForKey:BACKGROUND_COLOUR_QR_KEY];
    NSString *challange = [query objectForKey:REGISTRATION_CHALLANGE_QR_KEY];
    NSString *image = [FRAQRUtils decodeURL:[query objectForKey:IMAGE_QR_KEY]];
    NSString *issuer = [query objectForKey:ISSUER_QR_KEY];
    NSString *_label = [query objectForKey:@"_label"];
    
    if (nil == secret || nil == regEndpoint || nil == authEndpoint || nil == messageId || nil == challange || nil == issuer) {
        return nil; // TODO: throw a sensible exception/Error
    }
    
    FRAPushMechanism* mechanism = [FRAPushMechanism pushMechanismWithDatabase:database authEndpoint:authEndpoint secret:secret];
    
    FRAIdentity *identity = [self getIdentity:uri database:database label:_label issuer:issuer imagePath:image backgroundColor:backgroundColor];
    FRAIdentity *search = [model identityWithIssuer:[identity issuer] accountName:[identity accountName]];
    if (search == nil) {
        // TODO: Error Handling
        @autoreleasepool {
            NSError* error;
            [model addIdentity:identity error:&error];
        }

    } else {
        identity = search;
        if ([self checkForDuplicate]) {
            // TODO: populate NSError
            return nil;
        }
    }
    
    // TODO: Error Handling
    @autoreleasepool {
        NSError* error;
        [identity addMechanism:mechanism error:&error];
    }
    
    [self registerMechanismWithEndpoint:regEndpoint secret:secret challange:challange messageId:messageId mechanismUid:mechanism.mechanismUID identity:identity mechanism:mechanism];

    return mechanism;
}

- (NSDictionary *) readQRCode:(NSURL *)uri {

    NSString* scheme = [uri scheme];
    if (scheme == nil || ![scheme isEqualToString:@"pushauth"]) {
        return nil;
    }
    NSString* _type = [uri host];
    if (_type == nil || ![_type isEqualToString:@"push"]) {
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

- (bool) checkForDuplicate {
    return false;
}

/*!
 * Resolves the Identity from the URL that has been provided.
 * @return an initialised but not persisted Identity.
 */
- (FRAIdentity *)getIdentity:(NSURL*)url database:(FRAIdentityDatabase *)database label:(NSString *)label issuer:(NSString *)issuer imagePath:(NSString *)imagePath backgroundColor:(NSString*) backgroundColor {
    
    // TODO: Get image from uri and save it as a resource
    NSURL* _image = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"forgerock-logo" ofType:@"png"]];
    
    return [FRAIdentity identityWithDatabase:database accountName:label issuer:issuer image:_image backgroundColor:backgroundColor];
}

- (BOOL) supports:(NSURL *)uri {
    NSString* scheme = [uri scheme];
    if (scheme == nil || ![scheme isEqualToString:@"pushauth"]) {
        return false;
    }
    return true;
}

- (NSString *) getSupportedProtocol {
    return @"pushauth";
}

- (void) registerMechanismWithEndpoint:(NSString *)regEndpoint secret:(NSString *)secret challange:(NSString *)c messageId:(NSString *)messageId mechanismUid:(NSString *)uid identity:(FRAIdentity *)identity mechanism:(FRAMechanism *)mechanism{
    
    NSString* deviceId = _gateway.deviceToken;
    
    [FRAMessageUtils respondWithEndpoint:regEndpoint
                            base64Secret:secret
                               messageId:messageId
                                    data:@{@"response":[FRAMessageUtils generateChallengeResponse:c secret:secret],
                                           @"mechanismUid":uid,
                                           @"deviceId":deviceId,
                                           @"deviceType":@"ios",
                                           @"communicationType":@"apns"
                                           }
                                 handler:^(NSInteger statusCode, NSError *error) {
                                     if (200 != statusCode) {
                                         // TODO: inform user about failure
                                         // TODO: Handle Error
                                         @autoreleasepool {
                                             NSError* error;
                                             [identity removeMechanism:mechanism error:&error];
                                         }
                                     }
                                 }];
}

@end