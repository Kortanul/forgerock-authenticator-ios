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

#import "FMDatabase.h"
#import "FRADatabaseConfiguration.h"
#import "FRAError.h"
#import "FRAIdentity.h"
#import "FRAIdentityDatabase.h"
#import "FRAIdentityDatabaseSQLiteOperations.h"
#import "FRAIdentityModel.h"
#import "FRAMechanismFactory.h"
#import "FRAModelObjectProtected.h"
#import "FRANotification.h"
#import "FRAOathMechanism.h"
#import "FRAPushMechanism.h"

NSString * const FRAIdentityDatabaseChangedNotification = @"FRAIdentityDatabaseChangedNotification";
NSString * const FRAIdentityDatabaseChangedNotificationAddedItems = @"added";
NSString * const FRAIdentityDatabaseChangedNotificationRemovedItems = @"removed";
NSString * const FRAIdentityDatabaseChangedNotificationUpdatedItems = @"updated";

NSInteger const FRANotStored = -1;


/*!
 * Responsible for persisting model objects to the SQLite database, managing the storage IDs for persisted objects
 * and broadcasting FRAIdentityDatabaseChangedNotification event to the NSNotificationCenter defaultCenter so that
 * listeners can observe when the model is updated.
 * 
 * Actual SQL calls are delegated to FRAIdentityDatabaseSQLiteOperations.
 */
@implementation FRAIdentityDatabase {

    NSInteger nextIdentityId;
    NSInteger nextMechanismId;
    NSInteger nextNotificationId;
}

#pragma mark -
#pragma mark Lifecyle

// TODO: Remove
- (instancetype)init {
    return [self initWithSqlOperations:nil];
}

- (instancetype)initWithSqlOperations:(FRAIdentityDatabaseSQLiteOperations *)sqlOperations {
    if (self = [super init]) {
        nextIdentityId = 0;
        nextMechanismId = 0;
        nextNotificationId = 0;
        _sqlOperations = sqlOperations;
    }
    return self;
}

#pragma mark -
#pragma mark Identity Functions

- (BOOL)insertIdentity:(FRAIdentity *)identity error:(NSError *__autoreleasing *)error {
    NSMutableDictionary *stateChanges = [self dictionaryForStateChanges];
    if (![self doInsertIdentity:identity andCollectStateChanges:stateChanges withError:error]) {
        return NO;
    }
    [self postDatabaseChangeNotificationForStateChanges:stateChanges];
    return YES;
}

- (BOOL)doInsertIdentity:(FRAIdentity *)identity andCollectStateChanges:(NSMutableDictionary *)stateChanges withError:(NSError *__autoreleasing *)error {
    if ([identity isStored]) {
        NSString *reason = [[NSString alloc] initWithFormat:@"Identity %@/%@ was already persisted", identity.issuer, identity.accountName];
        [FRAError createError:error withReason:reason];
        return NO;
    }
    for (FRAMechanism *mechanism in [identity mechanisms]) {
        if (![self doInsertMechanism:mechanism andCollectStateChanges:stateChanges withError:error]) {
            return NO;
        }
    }
    if (![self.sqlOperations insertIdentity:identity error:error]) {
        return NO;
    }
    identity.uid = nextIdentityId;
    nextIdentityId++;
    [[stateChanges valueForKey:FRAIdentityDatabaseChangedNotificationAddedItems] addObject:identity];
    return YES;
}

- (BOOL)deleteIdentity:(FRAIdentity *)identity error:(NSError *__autoreleasing *)error {
    NSMutableDictionary *stateChanges = [self dictionaryForStateChanges];
    if (![self doDeleteIdentity:identity andCollectStateChanges:stateChanges withError:error]) {
        return NO;
    }
    [self postDatabaseChangeNotificationForStateChanges:stateChanges];
    return YES;
}

- (BOOL)doDeleteIdentity:(FRAIdentity *)identity andCollectStateChanges:(NSMutableDictionary *)stateChanges withError:(NSError *__autoreleasing *)error {
    if (![identity isStored]) {
        NSString *reason = [[NSString alloc] initWithFormat:@"Identity %@/%@ was not already persisted", identity.issuer, identity.accountName];
        [FRAError createError:error withReason:reason];
        return NO;
    }
    for (FRAMechanism *mechanism in [identity mechanisms]) {
        if (![self doDeleteMechanism:mechanism andCollectStateChanges:stateChanges withError:error]) {
            return NO;
        }
    }
    if (![self.sqlOperations deleteIdentity:identity error:error]) {
        return NO;
    }
    identity.uid = FRANotStored;
    [[stateChanges valueForKey:FRAIdentityDatabaseChangedNotificationRemovedItems] addObject:identity];
    return YES;
}

#pragma mark -
#pragma mark Mechanism Functions

- (BOOL)insertMechanism:(FRAMechanism *)mechanism error:(NSError *__autoreleasing *)error {
    NSMutableDictionary *stateChanges = [self dictionaryForStateChanges];
    if (![self doInsertMechanism:mechanism andCollectStateChanges:stateChanges withError:error]) {
        return NO;
    }
    [self postDatabaseChangeNotificationForStateChanges:stateChanges];
    return YES;
}

- (BOOL)doInsertMechanism:(FRAMechanism *)mechanism andCollectStateChanges:(NSMutableDictionary *)stateChanges withError:(NSError *__autoreleasing *)error {
    if ([mechanism isStored]) {
        [FRAError createError:error withReason:@"Mechanism was already persisted"];
        return NO;
    }
    for (FRANotification *notification in [mechanism notifications]) {
        if (![self doInsertNotification:notification andCollectStateChanges:stateChanges withError:error]) {
            return NO;
        }
    }
    if (![self.sqlOperations insertMechanism:mechanism error:error]) {
        return NO;
    }
    mechanism.uid = nextMechanismId;
    nextMechanismId++;
    [[stateChanges valueForKey:FRAIdentityDatabaseChangedNotificationAddedItems] addObject:mechanism];
    return YES;
}

- (BOOL)deleteMechanism:(FRAMechanism *)mechanism error:(NSError *__autoreleasing *)error {
    NSMutableDictionary *stateChanges = [self dictionaryForStateChanges];
    if (![self doDeleteMechanism:mechanism andCollectStateChanges:stateChanges withError:error]) {
        return NO;
    }
    [self postDatabaseChangeNotificationForStateChanges:stateChanges];
    return YES;
}

- (BOOL)doDeleteMechanism:(FRAMechanism *)mechanism andCollectStateChanges:(NSMutableDictionary *)stateChanges withError:(NSError *__autoreleasing *)error {
    if (![mechanism isStored]) {
        [FRAError createError:error withReason:@"Mechanism was not already persisted"];
        return NO;
    }
    for (FRANotification *notification in [mechanism notifications]) {
        if (![self doDeleteNotification:notification andCollectStateChanges:stateChanges withError:error]) {
            return NO;
        }
    }
    if (![self.sqlOperations deleteMechanism:mechanism error:error]) {
        return NO;
    }
    mechanism.uid = FRANotStored;
    [[stateChanges valueForKey:FRAIdentityDatabaseChangedNotificationRemovedItems] addObject:mechanism];
    return YES;
}

- (BOOL)updateMechanism:(FRAMechanism *)mechanism error:(NSError *__autoreleasing *)error {
    NSMutableDictionary *stateChanges = [self dictionaryForStateChanges];
    if (![self doUpdateMechanism:mechanism andCollectStateChanges:stateChanges withError:error]) {
        return NO;
    }
    [self postDatabaseChangeNotificationForStateChanges:stateChanges];
    return YES;
}

- (BOOL)doUpdateMechanism:(FRAMechanism *)mechanism andCollectStateChanges:(NSMutableDictionary *)stateChanges withError:(NSError *__autoreleasing *)error {
    if (![mechanism isStored]) {
        [FRAError createError:error withReason:@"Mechanism was not already persisted"];
        return NO;
    }
    if ([mechanism isKindOfClass:[FRAOathMechanism class]]) {
        FRAOathMechanism *oathMechanism = (FRAOathMechanism *)mechanism;
        if (![self.sqlOperations updateMechanism:oathMechanism error:error]) {
            return NO;
        }
        [[stateChanges valueForKey:FRAIdentityDatabaseChangedNotificationUpdatedItems] addObject:mechanism];
    } else if ([mechanism isKindOfClass:[FRAPushMechanism class]]) {
        FRAPushMechanism *pushMechanism = (FRAPushMechanism *)mechanism;
        if (![self.sqlOperations updateMechanism:pushMechanism error:error]) {
            return NO;
        }
        [[stateChanges valueForKey:FRAIdentityDatabaseChangedNotificationUpdatedItems] addObject:mechanism];
    } else {
        @throw [FRAError createIllegalStateException:@"Unknown Mechanism"];
    }
    return YES;
}

#pragma mark -
#pragma mark Notification Functions

- (BOOL)insertNotification:(FRANotification *)notification error:(NSError *__autoreleasing *)error {
    NSMutableDictionary *stateChanges = [self dictionaryForStateChanges];
    if (![self doInsertNotification:notification andCollectStateChanges:stateChanges withError:error]) {
        return NO;
    }
    [self postDatabaseChangeNotificationForStateChanges:stateChanges];
    return YES;
}

- (BOOL)doInsertNotification:(FRANotification *)notification andCollectStateChanges:(NSMutableDictionary *)stateChanges withError:(NSError *__autoreleasing *)error {
    if ([notification isStored]) {
        NSString *reason = [[NSString alloc] initWithFormat:@"Notification %@ was already persisted", notification.messageId];
        [FRAError createError:error withReason:reason];
        return NO;
    }
    if (![self.sqlOperations insertNotification:notification error:error]) {
        return NO;
    }
    notification.uid = nextNotificationId;
    nextNotificationId++;
    [[stateChanges valueForKey:FRAIdentityDatabaseChangedNotificationAddedItems] addObject:notification];
    return YES;
}

- (BOOL)deleteNotification:(FRANotification *)notification error:(NSError *__autoreleasing *)error {
    NSMutableDictionary *stateChanges = [self dictionaryForStateChanges];
    if (![self doDeleteNotification:notification andCollectStateChanges:stateChanges withError:error]) {
        return NO;
    }
    [self postDatabaseChangeNotificationForStateChanges:stateChanges];
    return YES;
}

- (BOOL)doDeleteNotification:(FRANotification *)notification andCollectStateChanges:(NSMutableDictionary *)stateChanges withError:(NSError *__autoreleasing *)error {
    if (![notification isStored]) {
        NSString* reason = [[NSString alloc] initWithFormat:@"Notification %@ was not already persisted", notification.messageId];
        [FRAError createError:error withReason:reason];
        return NO;
    }
    if (![self.sqlOperations deleteNotification:notification error:error]) {
        return NO;
    }
    notification.uid = FRANotStored;
    [[stateChanges valueForKey:FRAIdentityDatabaseChangedNotificationRemovedItems] addObject:notification];
    return YES;
}

- (BOOL)updateNotification:(FRANotification *)notification error:(NSError *__autoreleasing *)error {
    NSMutableDictionary *stateChanges = [self dictionaryForStateChanges];
    if (![self doUpdateNotification:notification andCollectStateChanges:stateChanges withError:error]) {
        return NO;
    }
    [self postDatabaseChangeNotificationForStateChanges:stateChanges];
    return YES;
}

- (BOOL)doUpdateNotification:(FRANotification *)notification andCollectStateChanges:(NSMutableDictionary *)stateChanges withError:(NSError *__autoreleasing *)error {
    if (![notification isStored]) {
        NSString *reason = [[NSString alloc] initWithFormat:@"Notification %@ was not already persisted", notification.messageId];
        [FRAError createError:error withReason:reason];
        return NO;
    }
    if (![self.sqlOperations updateNotification:notification error:error]) {
        return NO;
    }
    [[stateChanges valueForKey:FRAIdentityDatabaseChangedNotificationUpdatedItems] addObject:notification];
    return YES;
}

#pragma mark -
#pragma mark Listener Functions (private)

- (void)postDatabaseChangeNotificationForStateChanges:(NSDictionary *)stateChanges {
    [[NSNotificationCenter defaultCenter] postNotificationName:FRAIdentityDatabaseChangedNotification object:self userInfo:stateChanges];
}

- (NSMutableDictionary *)dictionaryForStateChanges {
    NSMutableDictionary *stateChanges = [[NSMutableDictionary alloc] init];
    [stateChanges setValue:[NSMutableSet set] forKey:FRAIdentityDatabaseChangedNotificationAddedItems];
    [stateChanges setValue:[NSMutableSet set] forKey:FRAIdentityDatabaseChangedNotificationRemovedItems];
    [stateChanges setValue:[NSMutableSet set] forKey:FRAIdentityDatabaseChangedNotificationUpdatedItems];
    return stateChanges;
}

@end
