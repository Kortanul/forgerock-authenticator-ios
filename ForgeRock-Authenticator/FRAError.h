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

@class FMDatabase;

@interface FRAError : NSObject

/*!
 * Create an error based on the last detected error from the FMDatabase.
 * @param database The FMDatabase instance to query for its error.
 * @param error The error pointer to populate.
 * @return BOOL Indicates if the error was created.
 */
+ (BOOL)createErrorForLastFailure:(FMDatabase *)database withError:(NSError *__autoreleasing *)error;

/*!
 * Create an error based on a file system error for a given path.
 * @param path The file system path the error occured against.
 * @param error The error pointer to populate.
 * @return BOOL Indicates if the error was created.
 */
+ (BOOL)createErrorForFilePath:(NSString *)path withReason:(NSString *)reason withError:(NSError *__autoreleasing *)error;

/*!
 * Create a general application error with a defined reason.
 * @param reason The cause of the error.
 * @param error The error pointer to populate.
 * @return BOOL Indicates if the error was created.
 */
+ (BOOL)createError:(NSError *__autoreleasing *)error withReason:(NSString *)reason;

/*!
 * Create a runtime exception for indicating an illegal state.
 * @param reason The cause of the exception.
 * @return NSException The exception which can be thrown by the caller.
 */
+ (NSException *)createIllegalStateException:(NSString *)reason;

@end