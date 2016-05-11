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

#import "FRAMessageUtils.h"

static NSString * const JSON_CONTENT_TYPE = @"application/json";
static NSString * const CONTENT_TYPE_HEADER = @"Content-Type";

NSInteger const NOT_FOUND = 404;

@implementation FRAMessageUtils

- (void)respond:(NSString *)endpoint
   base64Secret:(NSString *)base64Secret
      messageId:(NSString *)messageId
           data:(NSDictionary *)data
        handler:(void (^)(NSInteger, NSError *))handler {
    [self respond:endpoint base64Secret:base64Secret messageId:messageId data:data protocol:nil handler:handler];
}

- (void)respond:(NSString *)endpoint
   base64Secret:(NSString *)base64Secret
      messageId:(NSString *)messageId
           data:(NSDictionary *)data
       protocol:(Class) protocol
        handler:(void (^)(NSInteger, NSError *))handler {
    
    NSURL *URL = [NSURL URLWithString:endpoint];
    NSDictionary *payload = [self createPayloadWithMessageId:messageId base64Secret:base64Secret data:data];
    
    AFHTTPSessionManager *manager = [self createHTTPSessionManager:protocol];
    [manager.requestSerializer setValue:JSON_CONTENT_TYPE forHTTPHeaderField:CONTENT_TYPE_HEADER];
    
    [manager POST:URL.absoluteString
      parameters:payload
        progress:nil
         success:^(NSURLSessionTask *task, id responseObject) {
             handler([(NSHTTPURLResponse*)task.response statusCode], nil);
         } failure:^(NSURLSessionTask *operation, NSError *error) {
             handler(NOT_FOUND, error);
         }];
}

- (AFHTTPSessionManager *)createHTTPSessionManager:(Class)protocol {
    
    if(protocol) {
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSMutableArray * protocolsArray = [sessionConfiguration.protocolClasses mutableCopy];
        [protocolsArray insertObject:protocol atIndex:0];
        sessionConfiguration.protocolClasses = protocolsArray;
        
        return [[AFHTTPSessionManager alloc] initWithSessionConfiguration:sessionConfiguration];
    }
    
    return [AFHTTPSessionManager manager];
}

- (NSDictionary *)createPayloadWithMessageId:(NSString *)messageId
                                base64Secret:(NSString *)base64Secret
                                        data:(NSDictionary *)data {
    return @{@"messageId":messageId, @"jwt":[self generateJwtWithPayload:data base64Secret:base64Secret]};
}

- (NSString *)generateJwtWithPayload:(NSDictionary *)payload base64Secret:(NSString *)base64Secret {

    id<JWTAlgorithm> algorithm = [JWTAlgorithmFactory algorithmByName:@"HS256"];
    
    return [JWTBuilder encodePayload:payload].secret(base64Secret).algorithm(algorithm).encode;
}

@end
