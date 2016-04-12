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

#import "FRAFMDatabaseConnectionHelper.h"
#import "FRAIdentity.h"
#import "FRAIdentityDatabase.h"
#import "FRAIdentityDatabaseSQLiteOperations.h"
#import "FRAIdentityModel.h"
#import "FRAMechanism.h"
#import "FRAModelsFromDatabase.h"

/*!
 * Private interface.
 */
@interface FRAIdentityModel ()

/*!
 * The database to which this object graph is persisted.
 */
@property (strong, nonatomic) FRAIdentityDatabase *database;

@end


@implementation FRAIdentityModel {
    
    NSMutableArray<FRAIdentity*> *identitiesList;

}

#pragma mark -
#pragma mark Lifecyle

- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database sqlDatabase:(FRASqlDatabase *) sql {
    if (self = [super init]) {
        _database = database;
        @autoreleasepool {
            NSError *error;
            identitiesList = [[NSMutableArray alloc] initWithArray:[FRAModelsFromDatabase getAllIdentitiesFrom:sql including:database catchingErrorsWith:&error]];
        }
    }
    return self;
}

#pragma mark -
#pragma mark Identity Functions

- (NSArray *)identities {
    return [[NSArray alloc] initWithArray:identitiesList];
}

- (FRAIdentity *)identityWithId:(NSInteger)uid {
    for (FRAIdentity *identity in identitiesList) {
        if (identity.uid == uid) {
            return identity;
        }
    }
    return nil;
}

- (FRAIdentity *)identityWithIssuer:(NSString *)issuer accountName:(NSString *)accountName {
    for (FRAIdentity *identity in identitiesList) {
        if ([identity.issuer isEqualToString:issuer] && [identity.accountName isEqualToString:accountName]) {
            return identity;
        }
    }
    return nil;
}

- (BOOL)addIdentity:(FRAIdentity *)identity error:(NSError *__autoreleasing *)error {
    [identitiesList addObject:identity];
    return [self.database insertIdentity:identity error:error];
}

- (BOOL)removeIdentity:(FRAIdentity *)identity error:(NSError *__autoreleasing *)error {
    [identitiesList removeObject:identity];
    return [self.database deleteIdentity:identity error:error];
}

#pragma mark -
#pragma mark Mechanism Functions

- (FRAMechanism *)mechanismWithId:(NSInteger)uid {
    for (FRAIdentity *identity in identitiesList) {
        for (FRAMechanism *mechanism in [identity mechanisms]) {
            if (mechanism.uid == uid) {
                return mechanism;
            }
        }
    }
    return nil;
}

#pragma mark -
#pragma mark Notification Functions

- (NSInteger)pendingNotificationsCount {
    NSInteger count = 0;
    for (FRAIdentity *identity in self.identities) {
        count += [identity pendingNotificationsCount];
    }
    return count;
}

@end