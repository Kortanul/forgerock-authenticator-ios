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

#import "FRAError.h"
#import "FRAIdentity.h"
#import "FRAIdentityModel.h"
#import "FRAMechanism.h"
#import "FRAModelObjectProtected.h"
#import "FRAIdentityDatabase.h"

@implementation FRAIdentity {
    
    NSMutableArray *mechanismList;

}

#pragma mark -
#pragma mark Lifecyle

- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel accountName:(NSString *)accountName issuer:(NSString *)issuer image:(NSURL *)image backgroundColor:(NSString *) color {
    if (self = [super initWithDatabase:database identityModel:identityModel]) {
        _accountName = accountName;
        _issuer = issuer;
        _image = image;
        mechanismList = [[NSMutableArray alloc] init];
        _backgroundColor = color;
    }
    return self;
}

+ (instancetype)identityWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel accountName:(NSString *)accountName issuer:(NSString *)issuer image:(NSURL *)image backgroundColor:(NSString *)color {
    return [[FRAIdentity alloc] initWithDatabase:database identityModel:identityModel accountName:accountName issuer:issuer image:image backgroundColor:color];
}

#pragma mark -
#pragma mark Mechanism Functions

- (NSArray *)mechanisms {
    return [[NSArray alloc] initWithArray:mechanismList];
}

- (FRAMechanism *)mechanismOfClass:(Class)aClass {
    for (FRAMechanism *mechanism in mechanismList) {
        if ([mechanism isKindOfClass:aClass]) {
            return mechanism;
        }
    }
    return nil;
}

- (BOOL)addMechanism:(FRAMechanism *)mechanism error:(NSError *__autoreleasing *)error {
    FRAMechanism *duplicateMechanism = [self getDuplicate:mechanism];
    if (duplicateMechanism) {
        if (error) {
            *error = [FRAError createError:[NSString stringWithFormat:@"This will replace an existing login mechanism for your %@ account. This operation cannot be undone. You should only proceed if you were expecting to update a mechanism.", _issuer]
                                      code:FRADuplicateMechanism
                                  userInfo:@{ @"identity":self, @"mechanism":duplicateMechanism }];
        }
        return NO;
    }
    
    [mechanism setParent:self];
    [mechanismList addObject:mechanism];
    BOOL result = YES;
    if ([self isStored]) {
        result = [self.database insertMechanism:mechanism error:error];
    }
    return result;
}

- (BOOL)removeMechanism:(FRAMechanism *)mechanism error:(NSError *__autoreleasing *)error {
    BOOL result = YES;
    
    if (![mechanismList containsObject:mechanism]) {
        if (error) {
            *error = [FRAError createError:@"Invalid operation" code:FRAInvalidOperation];
        }
        return NO;
    }
    
    if (mechanismList.count == 1) {
        result = [_identityModel removeIdentity:self error:error];
    } else {
        if ([self isStored]) {
            result = [self.database deleteMechanism:mechanism error:error];
        }
    }
    [mechanismList removeObject:mechanism];
    [mechanism setParent:nil];
    
    return result;
}

#pragma mark -
#pragma mark Notification Functions

- (NSInteger)pendingNotificationsCount {
    NSInteger count = 0;
    for (FRAMechanism *mechanism in self.mechanisms) {
        count += [mechanism pendingNotificationsCount];
    }
    return count;
}

#pragma mark -
#pragma mark Private Functions

/*!
 * Identify if a mechanism of the same type already exists on the identity.
 * @param mechanism The mechanism used to search for a duplicate.
 * @return The duplicate mechanism.
 */
- (FRAMechanism *)getDuplicate:(FRAMechanism *)mechanism {
    if (mechanismList) {
        for (FRAMechanism *identityMechanism in mechanismList) {
            if ([identityMechanism.type isEqualToString:mechanism.type]) {
                return identityMechanism;
            }
        }
    }
    return nil;
}

@end
