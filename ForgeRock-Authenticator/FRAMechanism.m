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
#import "FRAMechanism.h"
#import "FRAModelObjectProtected.h"
#import "FRANotification.h"


@implementation FRAMechanism {
    NSMutableArray *notificationList;
}

#pragma mark -
#pragma mark Lifecyle

- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database {
    self = [super initWithDatabase:database];
    if (self) {
        _parent = nil;
        notificationList = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark -
#pragma mark Notification Functions

- (NSArray *)notifications {
    return [[NSArray alloc] initWithArray:notificationList];
}

- (NSInteger)pendingNotificationsCount {
    NSInteger count = 0;
    for (FRANotification *notification in self.notifications) {
        if (notification.isPending) {
            count += 1;
        }
    }
    return count;
}

- (void)addNotification:(FRANotification *)notification {
    [notification setParent:self];
    [notificationList addObject:notification];
    if ([self isStored]) {
        [self.database insertNotification:notification];
    }
}

- (void)removeNotification:(FRANotification *)notification {
    [notificationList removeObject:notification];
    [notification setParent:nil];
    if ([self isStored]) {
        [self.database deleteNotification:notification];
    }
}

- (FRANotification *)notificationWithMessageId:(NSString *)messageId {
    for (FRANotification *notification in self.notifications) {
        if ([notification.messageId isEqualToString:messageId]) {
            return notification;
        }
    }
    return nil;
}

@end
