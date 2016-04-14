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

#import "FRAIdentity.h"
#import "FRAMechanism.h"

@implementation FRAIdentity {
    NSMutableArray* mechanismList;
}

- (instancetype)initWithAccountName:(NSString*)accountName issuedBy:(NSString*)issuer withImage:(NSURL*)image {
    if (self = [super init]) {
        _uid = -1;
        _accountName = accountName;
        _issuer = issuer;
        _image = image;
        mechanismList = [[NSMutableArray alloc] init];
    }
    return self;
}

+ (instancetype)identityWithAccountName:(NSString*)accountName issuedBy:(NSString*)issuer withImage:(NSURL*)image {
    return [[FRAIdentity alloc] initWithAccountName:accountName issuedBy:issuer withImage:image];
}

- (NSArray*) mechanisms {
    return [[NSArray alloc] initWithArray:mechanismList];
}

- (void) addMechanism:(FRAMechanism *)mechansim {
    [mechansim setParent:self];
    [mechanismList addObject:mechansim];
}

- (void) removeMechanism:(FRAMechanism *)mechansim {
    [mechanismList removeObject:mechansim];
    [mechansim setParent:nil];
}

@end
