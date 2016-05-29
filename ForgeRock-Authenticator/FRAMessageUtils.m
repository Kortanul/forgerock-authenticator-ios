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

#include <CommonCrypto/CommonHMAC.h>

#import "FRAMessageUtils.h"
#import "FRAQRUtils.h"

/*! The Communication mechanism Content Type. */
static NSString * const JSON_CONTENT_TYPE = @"application/json";
/*! The Communication mechanism key. */
static NSString * const CONTENT_TYPE_HEADER = @"Content-Type";

@implementation FRAMessageUtils

+ (void)respondWithEndpoint:(NSString *)endpoint
               base64Secret:(NSString *)base64Secret
                  messageId:(NSString *)messageId
                       data:(NSDictionary *)data
                    handler:(void (^)(NSInteger, NSError *))handler {
    [self respondWithEndpoint:endpoint base64Secret:base64Secret messageId:messageId data:data protocol:nil handler:handler];
}

+ (void)respondWithEndpoint:(NSString *)endpoint
               base64Secret:(NSString *)base64Secret
                  messageId:(NSString *)messageId
                       data:(NSDictionary *)data
                   protocol:(Class) protocol
                    handler:(void (^)(NSInteger, NSError *))handler {
    
    NSURL *URL = [NSURL URLWithString:endpoint];
    NSDictionary *payload = [self createPayloadWithMessageId:messageId base64Secret:base64Secret data:data];
    
    AFHTTPSessionManager *manager = [self createHTTPSessionManager:protocol];
    [manager setRequestSerializer:[AFJSONRequestSerializer serializer]];
    [manager.requestSerializer setValue:JSON_CONTENT_TYPE forHTTPHeaderField:CONTENT_TYPE_HEADER];
    
    [manager POST:URL.absoluteString
      parameters:payload
        progress:nil
         success:^(NSURLSessionTask *task, id responseObject) {
             handler([(NSHTTPURLResponse*)task.response statusCode], nil);
         } failure:^(NSURLSessionTask *task, NSError *error) {
             NSLog(@"Error code = %li", [(NSHTTPURLResponse*)task.response statusCode]);
            
             handler([(NSHTTPURLResponse*)task.response statusCode], error);
         }];
    
}

+ (AFHTTPSessionManager *)createHTTPSessionManager:(Class)protocol {
    
    if(protocol) {
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSMutableArray * protocolsArray = [sessionConfiguration.protocolClasses mutableCopy];
        [protocolsArray insertObject:protocol atIndex:0];
        sessionConfiguration.protocolClasses = protocolsArray;
        
        return [[AFHTTPSessionManager alloc] initWithSessionConfiguration:sessionConfiguration];
    }
    
    return [AFHTTPSessionManager manager];
}

+ (NSDictionary *)createPayloadWithMessageId:(NSString *)messageId
                                base64Secret:(NSString *)base64Secret
                                        data:(NSDictionary *)data {
    NSString *jwtData = [self generateJwtWithPayload:data base64Secret:base64Secret];
    NSDictionary *topLevelData = @{@"messageId":messageId, @"jwt":jwtData};
    
    return topLevelData;
}

+ (NSString *)generateJwtWithPayload:(NSDictionary *)payload base64Secret:(NSString *)base64Secret {
    id<JWTAlgorithm> algorithm = [JWTAlgorithmFactory algorithmByName:@"HS256"];
    NSData *secretBytes = [FRAQRUtils decodeURL:base64Secret];
 
    return [JWTBuilder encodePayload:payload].secretData(secretBytes).algorithm(algorithm).encode;
}

+ (NSDictionary *)extractJTWBodyFromString:(NSString *)message {
    NSArray* strings = [message componentsSeparatedByString:@"."];
    NSString* payloadString = strings[1];
    payloadString = [FRAQRUtils pad:payloadString];
    
    NSData *payloadBytes = [[NSData alloc] initWithBase64EncodedString:payloadString options:0];
    
    NSError *jsonError;
    NSDictionary* data =  [NSJSONSerialization JSONObjectWithData:payloadBytes
                                                          options:NSJSONReadingMutableContainers
                                                            error:&jsonError];
    return data;
}

+ (NSString *)generateChallengeResponse:(NSString *)challenge secret:(NSString *)secret {
    
    NSData *saltData = [FRAQRUtils decodeURL:secret];
    NSData *paramData = [FRAQRUtils decodeBase64:challenge];
    
    NSMutableData * data = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, saltData.bytes, saltData.length, paramData.bytes, paramData.length, data.mutableBytes);
    NSString * hashedResponseString = [data base64EncodedStringWithOptions:0];
    
    return hashedResponseString;
}

@end
