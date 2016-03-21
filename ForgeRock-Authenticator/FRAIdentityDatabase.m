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

#import "FRAIdentityDatabase.h"
#import "FRAIdentity.h"
#import "FRAOathMechanism.h"

@interface FRAIdentityDatabase ()

- (BOOL)isIdentityStored:(FRAIdentity*)identity;
- (void)onDatabaseChange;

@end

@implementation FRAIdentityDatabase {

    NSMutableArray* identitiesList;
    NSMutableArray* mechanismsList;
    NSMutableArray* listeners;
    NSInteger nextRowid;

}

static FRAIdentityDatabase* singleton = nil;

+ (FRAIdentityDatabase*)singleton {
    @synchronized(self) {
        if (singleton == nil) {
            singleton = [[FRAIdentityDatabase alloc] init];
            
            FRAOathMechanism* mechanism = [[FRAOathMechanism alloc] initWithString:@"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0"];
            [singleton addMechanism:mechanism];

        }
    }
    return singleton;
}

- (id)init {
    if (self = [super init]) {
        identitiesList = [[NSMutableArray alloc] init];
        mechanismsList = [[NSMutableArray alloc] init];
        listeners = [[NSMutableArray alloc] init];
        nextRowid = 1; // Start at 1 rather than 0 so that it's easy to see if a mechanism has already been stored (temp hack)
    }
    return self;
}

- (NSArray*)identities {
    return [identitiesList copy];
}

- (FRAOathMechanism*)mechanismWithId:(NSInteger)uid {
    for (FRAOathMechanism* mechanism in mechanismsList) {
        if (mechanism.uid == uid) {
            return mechanism;
        }
    }
    return nil;
}

- (NSArray*)mechanismsWithOwner:(FRAIdentity*)owner {
    NSMutableArray* results = [[NSMutableArray alloc] init];
    for (FRAOathMechanism* mechanism in mechanismsList) {
        if ([mechanism.owner.issuer isEqual:owner.issuer] && [mechanism.owner.accountName isEqual:owner.accountName]) {
            [results addObject:mechanism];
        }
    }
    return results;
}

- (FRAIdentity*)identityWithIssuer:(NSString*)issuer accountName:(NSString*)accountName {
    for (FRAIdentity* identity in identitiesList) {
        if ([identity.issuer isEqualToString:issuer] && [identity.accountName isEqualToString:accountName]) {
            return identity;
        }
    }
    return nil;
}

- (void)addIdentity:(FRAIdentity*)identity {
    if ([self isIdentityStored:identity]) {
        // throw exception or update error parameter?
        return;
    }
    [identitiesList addObject:identity];
    [self onDatabaseChange];
}

- (BOOL)isIdentityStored:(FRAIdentity*)identity {
    FRAIdentity* existing = [self identityWithIssuer:identity.issuer accountName:identity.accountName];
    if (existing) {
        return YES;
    } else {
        return NO;
    }
}

- (void)addMechanism:(FRAOathMechanism*)mechanism {
    if (![self isIdentityStored:mechanism.owner]) {
        [self addIdentity:mechanism.owner];
    }
    // TODO: Check for duplicate mechanism
    [mechanismsList addObject:mechanism];
    if (!mechanism.uid) {
        mechanism.uid = nextRowid;
        nextRowid++;
    }
    [self onDatabaseChange];
}

- (void)updateMechanism:(FRAOathMechanism*)mechanism {
    [self removeMechanismWithId:mechanism.uid];
    [self addMechanism:mechanism];
    [self onDatabaseChange];
}

- (void)removeMechanismWithId:(NSInteger)uid {
    FRAOathMechanism* mechanism = [self mechanismWithId:uid];
    [mechanismsList removeObject:mechanism];
    NSArray* siblingMechanisms = [self mechanismsWithOwner:mechanism.owner];
    if (siblingMechanisms.count == 0) {
        [identitiesList removeObject:mechanism.owner];
    }
}

- (void)addListener:(id<FRADatabaseListener>)listener {
    [listeners addObject:listener];
}

- (void)onDatabaseChange {
    for (id<FRADatabaseListener> listener in listeners) {
        [listener onUpdate];
    }
}

@end
