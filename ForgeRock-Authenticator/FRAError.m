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
#import "FMDatabase.h"

@implementation FRAError

static NSString * const FRAErrorDomain = @"ForgeRockErrorDomain";

+ (NSError *)createErrorForLastFailure:(FMDatabase *) database {
    NSString* description = ([database.lastErrorMessage length] > 0) ? database.lastErrorMessage : @"nil";
    int code = (database) ? database.lastErrorCode : -1;
    
    NSLog(@"Database error: Last:%@ Code:%d", description, code);

    return [self createErrorWithCode:code userInfo:@{ NSLocalizedDescriptionKey : description }];
}

+ (NSError *)createErrorForFilePath:(NSString *)path reason:(NSString *)reason {
    NSLog(@"File error: Reason:%@ Path:%@", path, reason);
    
    return [self createErrorWithCode:FRAFileError userInfo:@{ NSLocalizedDescriptionKey : reason, NSFilePathErrorKey : path }];
}

+ (NSError *)createError:(NSString *)reason {
    return [self createError:reason code:FRAApplicationError];
}

+ (NSError *)createError:(NSString *)reason code:(enum FRAErrorCodes)code {
    return [self createErrorWithCode:code userInfo:@{ NSLocalizedDescriptionKey : reason }];
}

+ (NSError *)createError:(NSString *)reason code:(enum FRAErrorCodes)code userInfo:(NSDictionary *)userInfo {
    NSMutableDictionary *info = [userInfo mutableCopy];
    [info setObject:reason forKey:NSLocalizedDescriptionKey];
    return [self createErrorWithCode:code userInfo:info];
}

+ (NSException *)createIllegalStateException:(NSString *)reason {
    return [NSException exceptionWithName:@"IllegalStateException" reason:reason userInfo:nil];
}

+ (NSError *)createErrorWithCode:(int)code userInfo:(NSDictionary *)errorDictionary {
    return [[NSError alloc] initWithDomain:FRAErrorDomain code:code userInfo:errorDictionary];
}

@end