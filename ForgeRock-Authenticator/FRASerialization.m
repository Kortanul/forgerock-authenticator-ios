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


#import "FRASerialization.h"

NSString * const OATH_MECHANISM_SECRET = @"secret";
NSString * const OATH_MECHANISM_ALGORITHM = @"algorithm";
NSString * const OATH_MECHANISM_DIGITS = @"digits";
NSString * const OATH_MECHANISM_PERIOD = @"period";
NSString * const OATH_MECHANISM_COUNTER = @"counter";

NSString * const PUSH_MECHANISM_VERSION = @"version";
NSString * const PUSH_MECHANISM_SECRET = @"secret";
NSString * const PUSH_MECHANISM_AUTH_END_POINT = @"authEndPoint";

NSString * const NOTIFICATION_MESSAGE_ID = @"message_id";
NSString * const NOTIFICATION_PUSH_CHALLENGE = @"push_challenge";
NSString * const NOTIFICATION_TIME_TO_LIVE = @"time_to_live";
NSString * const NOTIFICATION_LOAD_BALANCER_COOKIE = @"load_balancer_cookie";

@implementation FRASerialization

#pragma mark -
#pragma mark Serialise/Deserialise Functions

+ (BOOL)serializeMap:(NSDictionary *)dictionary intoString:(NSString *__autoreleasing *)jsonString error:(NSError *__autoreleasing *)error {
    if (dictionary == nil) {
        return YES;
    }
    NSData *jsonBytes = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:error];
    if (jsonBytes == nil) {
        return NO;
    }
    *jsonString = [FRASerialization serializeBytes:jsonBytes];
    return YES;
}

+ (BOOL)deserializeJSON:(NSString *)dictionaryJson intoDictionary:(NSDictionary *__autoreleasing *)dictionary error:(NSError *__autoreleasing *)error {
    if (dictionaryJson == nil) {
        return YES;
    }
    NSData *jsonBytes = [FRASerialization deserializeBytes:dictionaryJson];
    NSDictionary* map = [NSJSONSerialization JSONObjectWithData: jsonBytes options: NSJSONReadingMutableContainers error: error];
    if (map == nil) {
        return NO;
    }
    *dictionary = map;
    return YES;
}

+ (NSString *)serializeBytes:(NSData *)data {
    if (data == nil) {
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (NSString *)serializeSecret:(NSData *)data {
    if (data == nil) {
        return nil;
    }
    const unsigned char *dataBuffer = (const unsigned char *)[data bytes];

    if (!dataBuffer) {
        return [NSString string];
    }

    NSUInteger dataLength = [data length];
    NSMutableString *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];

    for (int i = 0; i < dataLength; ++i) {
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    }

    return [NSString stringWithString:hexString];
}

+ (NSData *)deserializeSecret:(NSString *)hexOfSecret {
    char characterBuffer[3];
    characterBuffer[2] = '\0';

    unsigned char *bytes = malloc([hexOfSecret length]/2);
    unsigned char *byteTraversal = bytes;
    for (int i = 0; i < [hexOfSecret length]; i += 2) {
        characterBuffer[0] = [hexOfSecret characterAtIndex:i];
        characterBuffer[1] = [hexOfSecret characterAtIndex:i+1];
        char *byte2 = NULL;
        *byteTraversal++ = strtol(characterBuffer, &byte2, 16);
    }

    return [NSData dataWithBytesNoCopy:bytes length:[hexOfSecret length]/2 freeWhenDone:YES];
}

+ (NSData *)deserializeBytes:(NSString *)data {
    if (data == nil || [data isKindOfClass:[NSNull class]]) {
        return nil;
    }
    return [data dataUsingEncoding:NSUTF8StringEncoding];
}

#pragma mark -
#pragma mark Data Sanity Functions

+ (id)nonNilString:(NSString *)string {
    if (string == nil) {
        return [NSNull null];
    }
    return string;
}

+ (NSString *)nullToEmpty:(NSString *)string {
    if (string == nil || [string isKindOfClass:[NSNull class]]) {
        return @"";
    }
    return string;
}

+ (id)nonNilDate:(NSDate *)date {
    if (date != nil) {
        NSTimeInterval interval = [date timeIntervalSince1970];
        NSNumber *seconds = [NSNumber numberWithDouble:interval];
        return [seconds stringValue];
    } else {
        return [NSNull null];
    }
}

@end

