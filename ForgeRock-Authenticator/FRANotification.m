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

#import <Foundation/Foundation.h>

#import "FRAIdentityDatabase.h"
#import "FRAModelObjectProtected.h"
#import "FRANotification.h"

/*!
 * All notifications are expected to be able to transition from the initial state
 * of pending, to the final state of approved or denied.
 */
@implementation FRANotification

#pragma mark -
#pragma mark Lifecyle

- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database {
    
    self = [super initWithDatabase:database];
    if (self) {
        _pending = YES;
        _approved = NO;
    }
    return self;
}

+ (instancetype)initWithDatabase:(FRAIdentityDatabase *)database {
    return [[FRANotification alloc] initWithDatabase:database];
}

#pragma mark -
#pragma mark Notification Functions

- (NSString *)age {
    return @"TODO: age";
}

- (void)approve {
    _approved = YES;
    _pending = NO;
    if ([self isStored]) {
        [self.database updateNotification:self];
    }
}

- (void)deny {
    _approved = NO;
    _pending = NO;
    if ([self isStored]) {
        [self.database updateNotification:self];
    }
}

@end
