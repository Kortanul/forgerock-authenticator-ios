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

typedef NS_ENUM(NSInteger, FRAErrorCodes) {
    FRAFileError = 1000,
    FRAApplicationError = 2000,
    FRADuplicateMechanism,
    FRAInvalidOperation,
    FRAMissingDeviceId,
    FRAInvalidQRCode,
    FRANetworkFailure
};

@interface FRAError : NSObject

/*!
 * Creates an error based on the last detected error from the FMDatabase.
 * @param database The FMDatabase instance to query for its error.
 * @return The error created.
 */
+ (NSError *)createErrorForLastFailure:(FMDatabase *)database;

/*!
 * Creates an error based on a file system error for a given path.
 * @param path The file system path the error occured against.
 * @return The error created.
 */
+ (NSError *)createErrorForFilePath:(NSString *)path reason:(NSString *)reason;

/*!
 * Creates a general application error with a defined reason.
 * @param reason The cause of the error.
 * @return The error created.
 */
+ (NSError *)createError:(NSString *)reason;

/*!
 * Creates a specific application error with a defined reason and a code.
 * @param reason The cause of the error.
 * @param code The error code.
 * @return The error created.
 */
+ (NSError *)createError:(NSString *)reason code:(enum FRAErrorCodes)code;

/*!
 * Creates a specific application error with a defined reason, a code and any additional info.
 * @param reason The cause of the error.
 * @param code The error code.
 * @param userInfo Any additional info.
 * @return The error created.
 */
+ (NSError *)createError:(NSString *)reason code:(enum FRAErrorCodes)code userInfo:(NSDictionary *)userInfo;

/*!
 * Creates a specific application error with a defined reason, a code and the underlying error.
 * @param reason The cause of the error.
 * @param code The error code.
 * @param underlyingError The underlying error.
 * @return The error created.
 */
+ (NSError *)createError:(NSString *)reason code:(enum FRAErrorCodes)code underlyingError:(NSError *)underlyingError;

/*!
 * Creates a runtime exception for indicating an illegal state.
 * @param reason The cause of the exception.
 * @return NSException The exception which can be thrown by the caller.
 */
+ (NSException *)createIllegalStateException:(NSString *)reason;

@end