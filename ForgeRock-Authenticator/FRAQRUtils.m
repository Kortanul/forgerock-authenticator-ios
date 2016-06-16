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


#import "FRAQRUtils.h"


@implementation FRAQRUtils

+ (NSString *) replaceCharactersForURLDecoding:(NSString *)content {
    NSString * fixed = [content stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
    return [fixed stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
}

+ (NSData *) decodeURL:(NSString *) content {
    NSString * fixed = [FRAQRUtils replaceCharactersForURLDecoding:content];
    [self pad:fixed];
    
    return [FRAQRUtils decodeBase64:fixed];
}

+ (NSData *) decodeBase64:(NSString *) base64String {
    if (!base64String) {
        return nil;
    }
    
    base64String = [self pad:base64String];
    return [[NSData alloc] initWithBase64EncodedString:base64String options:0];
}

+ (NSString *) decode:(NSString *) str {
    if (str == nil) {
        return nil;
    }
    const char *tmp = [str UTF8String];
    NSMutableString *ret = [[NSMutableString alloc] init];
    for (NSUInteger i = 0; i < str.length; i++) {
        if (tmp[i] != '%' || !ishex(tmp[i + 1]) || !ishex(tmp[i + 2])) {
            [ret appendFormat:@"%c", tmp[i]];
            continue;
        }
        
        uint8_t c = 0;
        c |= fromhex(tmp[++i]) << 4;
        c |= fromhex(tmp[++i]);
        
        [ret appendFormat:@"%c", c];
    }
    
    return ret;
}

+ (NSString *)pad:(NSString *)str {
    int paddSize = (4 - ([str length] % 4)) % 4;
    
    if(paddSize != 0) {
        for(int i = 0; i < paddSize; ++i) {
            str = [str stringByAppendingString:@"="];
        }
    }

    return str;
}

static BOOL ishex(char c) {
    if (c >= '0' && c <= '9') {
        return YES;
    }
    if (c >= 'A' && c <= 'F') {
        return YES;
    }
    if (c >= 'a' && c <= 'f') {
        return YES;
    }
    return NO;
}

static uint8_t fromhex(char c) {
    if (c >= '0' && c <= '9') {
        return c - '0';
    }
    if (c >= 'A' && c <= 'F') {
        return c - 'A' + 10;
    }
    if (c >= 'a' && c <= 'f') {
        return c - 'a' + 10;
    }
    return 0;
}

@end