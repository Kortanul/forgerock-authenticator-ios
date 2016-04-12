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
 *
 * Portions Copyright 2014 Nathaniel McCallum, Red Hat
 */


#import <sys/time.h>

/*!
 * Represents a currently active OTP code.
 */
@interface FRAOathCode : NSObject

/*!
 * Initializer.
 *
 * @param value The one-time-password code for current counter value.
 * @param start The start-time for this one-time-password code.
 * @param end The end-time for this one-time-password code.
 * @return instantiated instance or nil if a problem occurred.
 */
- (instancetype)initWithValue:(NSString *)value startTime:(uint64_t)start endTime:(uint64_t)end;

/*!
 * The one-time-password value used for authentication.
 */
@property (strong, nonatomic) NSString *value;

/*!
 * The elapsed time for the current code normalized to a value between 0.0 and 1.0.
 */
- (float)progress;

/*!
 * Check whether this code has expired (progress == 1.0).
 */
- (BOOL)hasExpired;

@end
