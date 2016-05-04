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
@implementation FRANotification {
    NSDateFormatter *formatter;
}

static double const ONE_MINUTE_IN_SECONDS = 60.0;
static double const ONE_HOUR_IN_SECONDS = 3600.0;
static double const ONE_DAY_IN_SECONDS = 86400.0;
static double const TWO_DAYS_IN_SECONDS = 172800.0;
static double const ONE_WEEK_IN_SECONDS = 604800.0;
static NSString * const STRING_DATE_FORMAT = @"dd/MM/yyyy";

- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database messageId:(NSString *)messageId challange:(NSString *)challenge timeRecieved:(NSDate *)timeRecieved ttl:(NSTimeInterval *)ttl {
    self = [super initWithDatabase:database];
    if (self) {
        _pending = YES;
        _approved = NO;
        
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:STRING_DATE_FORMAT];
        _messageId = messageId;
        _challenge = challenge;
        _ttl = ttl;
    }
    return self;
}

- (NSString *)age {
    NSTimeInterval age = [[NSDate date] timeIntervalSinceDate:self.timeReceived];
    if (age < ONE_MINUTE_IN_SECONDS) {
        return [NSString stringWithFormat:@"%ld seconds ago", (long)age];
    } else if (age < ONE_HOUR_IN_SECONDS) {
        return [NSString stringWithFormat:@"%ld minutes ago", (long)(age / ONE_MINUTE_IN_SECONDS)];
    } else if (age < ONE_DAY_IN_SECONDS) {
        return [NSString stringWithFormat:@"%ld hours ago", (long)(age / ONE_HOUR_IN_SECONDS)];
    } else if (age < TWO_DAYS_IN_SECONDS) {
        return @"Yesterday";
    } else if (age < ONE_WEEK_IN_SECONDS) {
        return [NSString stringWithFormat:@"%ld days ago", (long)(age / ONE_DAY_IN_SECONDS)];
    } else {
        return [formatter stringFromDate:self.timeReceived];
    }
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
