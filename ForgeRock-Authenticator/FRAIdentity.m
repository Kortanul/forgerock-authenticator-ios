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
#import "FRAModelObjectProtected.h"
#import "FRAIdentityDatabase.h"

@implementation FRAIdentity {
    
    NSMutableArray *mechanismList;

}

#pragma mark -
#pragma mark Lifecyle

- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database accountName:(NSString *)accountName issuer:(NSString *)issuer image:(NSURL *)image {
    if (self = [super initWithDatabase:database]) {
        _accountName = accountName;
        _issuer = issuer;
        _image = image;
        mechanismList = [[NSMutableArray alloc] init];
    }
    return self;
}

+ (instancetype)identityWithDatabase:(FRAIdentityDatabase *)database accountName:(NSString *)accountName issuer:(NSString *)issuer image:(NSURL *)image {
    return [[FRAIdentity alloc] initWithDatabase:database accountName:accountName issuer:issuer image:image];
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

- (void)addMechanism:(FRAMechanism *)mechanism {
    [mechanism setParent:self];
    [mechanismList addObject:mechanism];
    if ([self isStored]) {
        [self.database insertMechanism:mechanism];
    }
}

- (void)removeMechanism:(FRAMechanism *)mechanism {
    [mechanismList removeObject:mechanism];
    [mechanism setParent:nil];
    if ([self isStored]) {
        [self.database deleteMechanism:mechanism];
    }
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

@end
