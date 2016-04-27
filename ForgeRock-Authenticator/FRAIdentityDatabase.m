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

- (void)insertIdentity:(FRAIdentity *)identity {
    NSMutableDictionary *stateChanges = [self dictionaryForStateChanges];
    [self doInsertIdentity:identity andCollectStateChanges:stateChanges];
    [self postDatabaseChangeNotificationForStateChanges:stateChanges];
}

- (void)doInsertIdentity:(FRAIdentity *)identity andCollectStateChanges:(NSMutableDictionary *)stateChanges {
    if ([identity isStored]) {
        // TODO: Throw exception as programmer error has occured?
        return;
    }
    for (FRAMechanism *mechanism in [identity mechanisms]) {
        [self doInsertMechanism:mechanism andCollectStateChanges:stateChanges];
    }
    [self.sqlOperations insertIdentity:identity];
    identity.uid = nextIdentityId;
    nextIdentityId++;
    [[stateChanges valueForKey:FRAIdentityDatabaseChangedNotificationAddedItems] addObject:identity];
}

- (void)deleteIdentity:(FRAIdentity *)identity {
    NSMutableDictionary *stateChanges = [self dictionaryForStateChanges];
    [self doDeleteIdentity:identity andCollectStateChanges:stateChanges];
    [self postDatabaseChangeNotificationForStateChanges:stateChanges];
}

- (void)doDeleteIdentity:(FRAIdentity *)identity andCollectStateChanges:(NSMutableDictionary *)stateChanges {
    if (![identity isStored]) {
        // TODO: Throw exception as programmer error has occured?
        return;
    }
    for (FRAMechanism *mechanism in [identity mechanisms]) {
        [self doDeleteMechanism:mechanism andCollectStateChanges:stateChanges];
    }
    [self.sqlOperations deleteIdentity:identity];
    identity.uid = FRANotStored;
    [[stateChanges valueForKey:FRAIdentityDatabaseChangedNotificationRemovedItems] addObject:identity];
}

#pragma mark -
#pragma mark Mechanism Functions

- (void)insertMechanism:(FRAMechanism *)mechanism {
    NSMutableDictionary *stateChanges = [self dictionaryForStateChanges];
    [self doInsertMechanism:mechanism andCollectStateChanges:stateChanges];
    [self postDatabaseChangeNotificationForStateChanges:stateChanges];
}

- (void)doInsertMechanism:(FRAMechanism *)mechanism andCollectStateChanges:(NSMutableDictionary *)stateChanges {
    if ([mechanism isStored]) {
        // TODO: Throw exception as programmer error has occured?
        return;
    }
    for (FRANotification *notification in [mechanism notifications]) {
        [self doInsertNotification:notification andCollectStateChanges:stateChanges];
    }
    [self.sqlOperations insertMechanism:mechanism];
    mechanism.uid = nextMechanismId;
    nextMechanismId++;
    [[stateChanges valueForKey:FRAIdentityDatabaseChangedNotificationAddedItems] addObject:mechanism];
}

- (void)deleteMechanism:(FRAMechanism *)mechanism {
    NSMutableDictionary *stateChanges = [self dictionaryForStateChanges];
    [self doDeleteMechanism:mechanism andCollectStateChanges:stateChanges];
    [self postDatabaseChangeNotificationForStateChanges:stateChanges];
}

- (void)doDeleteMechanism:(FRAMechanism *)mechanism andCollectStateChanges:(NSMutableDictionary *)stateChanges {
    if (![mechanism isStored]) {
        // TODO: Throw exception as programmer error has occured?
        return;
    }
    for (FRANotification *notification in [mechanism notifications]) {
        [self doDeleteNotification:notification andCollectStateChanges:stateChanges];
    }
    [self.sqlOperations deleteMechanism:mechanism];
    mechanism.uid = FRANotStored;
    [[stateChanges valueForKey:FRAIdentityDatabaseChangedNotificationRemovedItems] addObject:mechanism];
}

- (void)updateMechanism:(FRAMechanism *)mechanism {
    NSMutableDictionary *stateChanges = [self dictionaryForStateChanges];
    [self doUpdateMechanism:mechanism andCollectStateChanges:stateChanges];
    [self postDatabaseChangeNotificationForStateChanges:stateChanges];
}

- (void)doUpdateMechanism:(FRAMechanism *)mechanism andCollectStateChanges:(NSMutableDictionary *)stateChanges {
    if (![mechanism isStored]) {
        // TODO: Throw exception as programmer error has occured?
        return;
    }
    if ([mechanism isKindOfClass:[FRAOathMechanism class]]) {
        FRAOathMechanism *oathMechanism = (FRAOathMechanism *)mechanism;
        // TODO: Update mechanism in SQLite DB
        [self.sqlOperations updateMechanism:oathMechanism];
        [[stateChanges valueForKey:FRAIdentityDatabaseChangedNotificationUpdatedItems] addObject:mechanism];
    } else if ([mechanism isKindOfClass:[FRAPushMechanism class]]) {
        FRAPushMechanism *pushMechanism = (FRAPushMechanism *)mechanism;
        // TODO: Update mechanism in SQLite DB
        [self.sqlOperations updateMechanism:pushMechanism];
        [[stateChanges valueForKey:FRAIdentityDatabaseChangedNotificationUpdatedItems] addObject:mechanism];
    } else {
        // TODO: Throw exception as programmer error has occured?
        return;
    }
}

#pragma mark -
#pragma mark Notification Functions

- (void)insertNotification:(FRANotification *)notification {
    NSMutableDictionary *stateChanges = [self dictionaryForStateChanges];
    [self doInsertNotification:notification andCollectStateChanges:stateChanges];
    [self postDatabaseChangeNotificationForStateChanges:stateChanges];
}

- (void)doInsertNotification:(FRANotification *)notification andCollectStateChanges:(NSMutableDictionary *)stateChanges {
    if ([notification isStored]) {
        // TODO: Throw exception as programmer error has occured?
        return;
    }
    [self.sqlOperations insertNotification:notification];
    notification.uid = nextNotificationId;
    nextNotificationId++;
    [[stateChanges valueForKey:FRAIdentityDatabaseChangedNotificationAddedItems] addObject:notification];
}

- (void)deleteNotification:(FRANotification *)notification {
    NSMutableDictionary *stateChanges = [self dictionaryForStateChanges];
    [self doDeleteNotification:notification andCollectStateChanges:stateChanges];
    [self postDatabaseChangeNotificationForStateChanges:stateChanges];
}

- (void)doDeleteNotification:(FRANotification *)notification andCollectStateChanges:(NSMutableDictionary *)stateChanges {
    if (![notification isStored]) {
        // TODO: Throw exception as programmer error has occured?
        return;
    }
    [self.sqlOperations deleteNotification:notification];
    notification.uid = FRANotStored;
    [[stateChanges valueForKey:FRAIdentityDatabaseChangedNotificationRemovedItems] addObject:notification];
}

- (void)updateNotification:(FRANotification *)notification {
    NSMutableDictionary *stateChanges = [self dictionaryForStateChanges];
    [self doUpdateNotification:notification andCollectStateChanges:stateChanges];
    [self postDatabaseChangeNotificationForStateChanges:stateChanges];
}

- (void)doUpdateNotification:(FRANotification *)notification andCollectStateChanges:(NSMutableDictionary *)stateChanges {
    if (![notification isStored]) {
        // TODO: Throw exception as programmer error has occured?
        return;
    }
    [self.sqlOperations updateNotification:notification];
    [[stateChanges valueForKey:FRAIdentityDatabaseChangedNotificationUpdatedItems] addObject:notification];
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
