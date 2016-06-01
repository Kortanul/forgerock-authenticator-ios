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
 *
 * Portions Copyright 2014 Nathaniel McCallum, Red Hat
 */


#import "FRAMechanismFactory.h"
#import "FRAOathMechanism.h"
#import "FRAIdentity.h"
#import "FRAIdentityDatabase.h"
#import "FRAIdentityModel.h"
#import "FRAMechanism.h"
#import "FRAUriMechanismReader.h"


#include "base32.h"
#include <CommonCrypto/CommonHMAC.h>
#include <sys/time.h>

@implementation FRAUriMechanismReader {

    FRAIdentityDatabase *_database;
    NSMutableDictionary *_mechanisms;
    FRAIdentityModel *_identityModel;
}

#pragma mark -
#pragma mark Lifecyle

- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel {
    if (self = [super init]) {
        _database = database;
        _identityModel = identityModel;
        _mechanisms = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void) addMechanismFactory:(id<FRAMechanismFactory>)factory {
    [_mechanisms setObject:factory forKey:[factory getSupportedProtocol]];
}

#pragma mark -
#pragma mark Factory Functions

- (FRAMechanism *)getMechanism:(NSURL *)url {
    
    NSString* scheme = [url scheme];
    
    id<FRAMechanismFactory> mechanismFactory = [_mechanisms objectForKey:scheme];
    return [mechanismFactory buildMechanism:url database:_database identityModel:_identityModel];
}

- (FRAMechanism *)parseFromURL:(NSURL *)url {
    FRAMechanism *mechanism = [self getMechanism:url];
    return mechanism;
}

- (FRAMechanism *)parseFromString:(NSString *)string {
    return [self parseFromURL:[[NSURL alloc]initWithString:string]];
}

@end