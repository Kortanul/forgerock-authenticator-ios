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


- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database authEndpoint:(NSString *)a secret:s image:(NSString *)image bgColour:(NSString *)b issuer:(NSString *)issuer{
    self = [super initWithDatabase:database];
    if (self) {
        _version = 1;
        _authEndpoint = a;
        _secret = s;
        _image = image;
        _bgColour = b;
        _issuer = issuer;
    }
    return self;
}

- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database {
    
    self = [super initWithDatabase:database];
    if (self) {
        _version = 1;
    }
    return self;
}

+ (instancetype)pushMechanismWithDatabase:(FRAIdentityDatabase *)database {
    return [[FRAPushMechanism alloc] initWithDatabase:database];
}

+ (instancetype)pushMechanismWithDatabase:(FRAIdentityDatabase *)database authEndpoint:(NSString *)a secret:s image:(NSString *)image bgColour:(NSString *)b issuer:(NSString *)issuer {
    return [[FRAPushMechanism alloc] initWithDatabase:database authEndpoint:a secret:s image:image bgColour:b issuer:issuer];
}

@end
