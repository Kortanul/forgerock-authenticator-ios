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
#import "FRAIdentityDatabase.h"
#import "FRAMechanismFactory.h"
#import "FRAOathMechanism.h"

@interface FRAIdentityDatabase ()

- (BOOL)isIdentityStored:(FRAIdentity*)identity;
- (void)onDatabaseChange;

@end

/*!
 * Provides methods for persisting model objects to the database layer.
 * Understands how to talk to the underlying SQLite database.
 */
@implementation FRAIdentityDatabase {

    NSMutableArray* identitiesList;
    NSMutableArray* mechanismsList;
    NSMutableArray* listeners;
    NSInteger nextIdentityId;
    NSInteger nextMechanismId;

}

- (instancetype)init {
    if (self = [super init]) {
        identitiesList = [[NSMutableArray alloc] init];
        mechanismsList = [[NSMutableArray alloc] init]; // TODO: Might be redundant
        listeners = [[NSMutableArray alloc] init];
        nextIdentityId = 0;
        nextMechanismId = 0;
    }
    return self;
}

- (NSArray*)identities {
    return [[NSArray alloc] initWithArray:identitiesList];
}

- (FRAOathMechanism*)mechanismWithId:(NSInteger)uid {
    for (FRAOathMechanism* mechanism in mechanismsList) {
        if (mechanism.uid == uid) {
            return mechanism;
        }
    }
    return nil;
}

- (FRAIdentity*)identityWithId:(NSInteger)uid {
    for (FRAIdentity* identity in identitiesList) {
        if (identity.uid == uid) {
            return identity;
        }
    }
    return nil;
}

- (FRAIdentity*)identityWithIssuer:(NSString*)issuer accountName:(NSString*)accountName {
    for (FRAIdentity* identity in identitiesList) {
        if ([identity.issuer isEqualToString:issuer] && [identity.accountName isEqualToString:accountName]) {
            return identity;
        }
    }
    return nil;
}

#pragma mark --
#pragma mark Idenitity Functions

- (BOOL)isIdentityStored:(FRAIdentity*)identity {
    for (FRAIdentity* identity in identitiesList) {
        if ([identity uid] == [identity uid]) {
            return YES;
        }
    }
    return NO;
}

- (void)addIdentity:(FRAIdentity*)identity {
    if ([self isIdentityStored:identity]) {
        // throw exception or update error parameter?
        return;
    }
    [identitiesList addObject:identity];
    if (identity.uid == -1) {
        identity.uid = nextIdentityId;
        nextIdentityId++;
    }
    [self onDatabaseChange];
}

- (void)removeIdentityWithId:(NSInteger)uid {
    FRAIdentity* identity = [self identityWithId:uid];
    if (identity) {
        NSArray* mechanisms = [identity mechanisms];
        [mechanismsList removeObjectsInArray:mechanisms];
        [identitiesList removeObject:identity];
    }
}

-(void) removeIdentity:(FRAIdentity *)identity {
    // Remove all attached Mechanisms
    for (FRAMechanism* mechanism in [identity mechanisms]) {
        [self removeMechanism:mechanism];
    }
    // Remove the identity from the top level list.
    [identitiesList removeObject:identity];
    [self onDatabaseChange];
}

#pragma mark --
#pragma mark Mechanism Functions

- (void)addMechanism:(FRAMechanism*)mechanism {
    FRAIdentity* identity = [mechanism parent];
    if (![self isIdentityStored:identity]) {
        [self addIdentity:identity];
    }
    
    [mechanismsList addObject:mechanism];
    if (mechanism.uid == -1) {
        mechanism.uid = nextMechanismId;
        nextMechanismId++;
    }
    [self onDatabaseChange];
}

- (void)updateMechanism:(FRAMechanism*)mechanism {
    if ([mechanism isKindOfClass:[FRAOathMechanism class]]) {
        FRAOathMechanism* oathMechanism = (FRAOathMechanism *)mechanism;
        // TODO: database save for mechanism.
    } // else if mechanism is type of Push Mechanism
    [self onDatabaseChange];
}

- (void)removeMechanism:(FRAMechanism*)mechanism {
    // Remove reference from parent Identity.
    FRAIdentity* identity = [mechanism parent];
    [identity removeMechanism:mechanism];
    
    // Remove any Notifications on the Mechanism
    for (FRANotification* notification in [mechanism notifications]) {
        [self removeNotification:notification];
    }
    
    // Automatically remove Identity if it it no longer has any mechanisms.
    if ([[identity mechanisms] count] == 0) {
        [self removeIdentityWithId:[identity uid]];
    }
    
    // Maintain Mechanisms list
    [mechanismsList removeObject:mechanism];
    
    [self onDatabaseChange];
}

#pragma mark --
#pragma mark Notification Functions

- (void) removeNotification:(FRANotification*) notification {
    
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
