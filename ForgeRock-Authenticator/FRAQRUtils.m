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

static NSString * const VALID_BASE64_CHARACTERS = @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

@implementation FRAQRUtils

+ (NSString *)replaceCharactersForURLDecoding:(NSString *)content {
    NSString * fixed = [content stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
    return [fixed stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
}

+ (NSData *)decodeURL:(NSString *) content {
    NSString * fixed = [FRAQRUtils replaceCharactersForURLDecoding:content];
    [self pad:fixed];
    
    return [FRAQRUtils decodeBase64:fixed];
}

+ (NSData *)decodeBase64:(NSString *) base64String {
    if (!base64String) {
        return nil;
    }
    
    base64String = [self pad:base64String];
    return [[NSData alloc] initWithBase64EncodedString:base64String options:0];
}

+ (NSString *)decode:(NSString *)content {
    return [content stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)pad:(NSString *)content {
    int paddSize = (4 - ([content length] % 4)) % 4;
    
    if(paddSize != 0) {
        for(int i = 0; i < paddSize; ++i) {
            content = [content stringByAppendingString:@"="];
        }
    }

    return content;
}

+ (BOOL)isBase64:(NSString *)content {
    static NSCharacterSet *invertedBase64CharacterSet = nil;
    if (invertedBase64CharacterSet == nil) {
        invertedBase64CharacterSet = [[NSCharacterSet characterSetWithCharactersInString:VALID_BASE64_CHARACTERS] invertedSet];
    }
    return [content rangeOfCharacterFromSet:invertedBase64CharacterSet options:NSLiteralSearch].location == NSNotFound;
}

@end