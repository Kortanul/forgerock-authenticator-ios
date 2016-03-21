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

#import <Foundation/Foundation.h>
#import <sys/time.h>

/*!
 * Represents a currently active OTP code.
 */
@interface FRAOathCode : NSObject

/*!
 * Initializer for HMAC-based One-Time-Password.
 *
 * @param code the one-time-password code for current counter value.
 * @param startTime the start-time for this one-time-password code.
 * @param endTime the end-time for this one-time-password code.
 * @return instantiated instance or nil if a problem occurred.
 */
- (id)initWithCode:(NSString*)code startTime:(time_t)start endTime:(time_t)end;

/*!
 * Initializer for Time-based One-Time-Password.
 *
 * @param code the one-time-password code for current time period.
 * @param startTime the start-time for this one-time-password code.
 * @param endTime the end-time for this one-time-password code.
 * @param nextTokenCode the TOTP code for the next time period.
 * @return instantiated instance or nil if a problem occurred.
 */
- (id)initWithCode:(NSString*)code startTime:(time_t)start endTime:(time_t)end nextTokenCode:(FRAOathCode*)next;

/*!
 * The current code. If the current code is an elapsed TOTP, then the next code is returned.
 */
- (NSString*)currentCode;
/*!
 * The elapsed time for the current code normalized to a value between 0.0 and 1.0.
 * If the current code is an elapsed TOTP, then the progress of the next code is returned.
 */
- (float)currentProgress;
/*!
 * The total elapsed time for the linked-list of codes, for which this is the head, normalized to a value between 0.0 and 1.0.
 */
- (float)totalProgress;
/*!
 * The number of linked-list of codes for which this is the head.
 */
- (NSUInteger)totalCodes;

@end
