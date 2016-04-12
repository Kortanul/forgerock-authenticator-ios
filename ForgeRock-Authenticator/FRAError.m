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

int const FRAFileError = 1000;
int const FRAApplicationError = 2000;

+ (BOOL)createErrorForLastFailure:(FMDatabase *) database withError:(NSError *__autoreleasing *)error {
    NSString* description;
    int code;
    if (database == nil) {
        description = @"nil";
        code = -1;
    } else {
        description = database.lastErrorMessage != nil ? database.lastErrorMessage : @"nil";
        code = database.lastErrorCode;
    }
    
    NSLog(@"Database error: Reporting?:%@ Last:%@ Code:%d",
          error == nil ? @"NO" : @"YES",
          description,
          code);
    
    NSDictionary *errorDictionary = @{ NSLocalizedDescriptionKey : description };
    return [self createError:error withCode:code andUserInfo:errorDictionary];
}

+ (BOOL)createErrorForFilePath:(NSString *)path withReason:(NSString *)reason withError:(NSError *__autoreleasing *)error {
    NSLog(@"File error: Reporting?:%@ Reason:%@ Path:%@",
          error == nil ? @"NO" : @"YES",
          path,
          reason);
    
    NSDictionary *errorDictionary = @{ NSLocalizedDescriptionKey : reason, NSFilePathErrorKey : path };
    return [self createError:error withCode:FRAFileError andUserInfo:errorDictionary];
}

+ (BOOL)createError:(NSError *__autoreleasing *)error withReason:(NSString *)reason {
    NSDictionary *errorDictionary = @{ NSLocalizedDescriptionKey : reason };
    return [self createError:error withCode:FRAApplicationError andUserInfo:errorDictionary];
}

+ (NSException *)createIllegalStateException:(NSString *)reason {
    return [NSException exceptionWithName:@"IllegalStateException" reason:reason userInfo:nil];
}

+ (BOOL)createError:(NSError *__autoreleasing *)error withCode:(int)code andUserInfo:(NSDictionary *)errorDictionary {
    if (error == nil) {
        return NO;
    }
    *error = [[NSError alloc] initWithDomain:FRAErrorDomain code:code userInfo:errorDictionary];
    return YES;
}

@end