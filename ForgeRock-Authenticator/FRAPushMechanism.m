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

#import "FRAPushMechanism.h"

@implementation FRAPushMechanism

#pragma mark -
#pragma mark Lifecyle


// Testing only?
- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel {
    return [self initWithDatabase:database identityModel:identityModel authEndpoint:nil secret:nil version:1 mechanismIdentifier:[NSUUID UUID].UUIDString];
}

- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel authEndpoint:(NSString *)authEndPoint secret:(NSString *)secret {
    return [self initWithDatabase:database identityModel:identityModel authEndpoint:authEndPoint secret:secret version:1 mechanismIdentifier:[NSUUID UUID].UUIDString];
}

- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel authEndpoint:(NSString *)authEndPoint secret:(NSString *)secret version:(NSInteger)version mechanismIdentifier:(NSString *)mechanismIdentifier{
    self = [super initWithDatabase:database identityModel:identityModel];
    if (self) {
        _version = version;
        _authEndpoint = authEndPoint;
        _secret = secret;
        _mechanismUID = mechanismIdentifier;
    }
    return self;
}


// Testing only?
+ (instancetype)pushMechanismWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel {
    return [[FRAPushMechanism alloc] initWithDatabase:database identityModel:identityModel];
}


+ (instancetype)pushMechanismWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel authEndpoint:(NSString *)authEndPoint secret:(NSString *)secret version:(NSInteger)version  mechanismIdentifier:(NSString *)mechanismIdentifier{
    return [[FRAPushMechanism alloc] initWithDatabase:database identityModel:identityModel authEndpoint:authEndPoint secret:secret version:version mechanismIdentifier:mechanismIdentifier];
}

+ (instancetype)pushMechanismWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel authEndpoint:(NSString *)authEndPoint secret:(NSString *)secret {
    return [[FRAPushMechanism alloc] initWithDatabase:database identityModel:identityModel authEndpoint:authEndPoint secret:secret];
}

+ (NSString *)mechanismType {
    return @"push";
}

@end
