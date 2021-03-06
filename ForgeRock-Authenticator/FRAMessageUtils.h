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

#import <AFNetworking.h>
#import <JWT.h>
#import <JWTAlgorithmFactory.h>

/*!
 * Class that handles communication with OpenAM.
 */
@interface FRAMessageUtils : NSObject

/*!
 * POST request method.
 *
 * @param endpoint The URL string used to create the request URL.
 * @param base64Secret The secret used to sign the JWT.
 * @param messageId The id of the message.
 * @param data The payload to transmit with the request.
 * @param handler A block object to be executed when the task finishes.
 */
+ (void)respondWithEndpoint:(NSString *)endpoint
               base64Secret:(NSString *)base64Secret
                  messageId:(NSString *)messageId
     loadBalancerCookieData:(NSString *)loadBalancerCookieData
                       data:(NSDictionary *)data
                    handler:(void (^)(NSInteger statusCode, NSError *error))handler;

/*!
 * POST request method.
 *
 * @param endpoint The URL string used to create the request URL.
 * @param base64Secret The secret used to sign the JWT.
 * @param messageId The id of the message.
 * @param data The payload to transmit with the request.
 * @param protocol The protocol used to process URLs.
 * @param handler A block object to be executed when the task finishes.
 */
+ (void)respondWithEndpoint:(NSString *)endpoint
               base64Secret:(NSString *)base64Secret
                  messageId:(NSString *)messageId
     loadBalancerCookieData:(NSString *)loadBalancerCookieData
                       data:(NSDictionary *)data
                   protocol:(Class) protocol
                    handler:(void (^)(NSInteger statusCode, NSError *error))handler;

/*!
 * Generate challenge response.
 *
 * @param challenge The challenge.
 * @param secret The secret.
 * @return The challenge response.
 */
+ (NSString *) generateChallengeResponse:(NSString *) challenge secret:(NSString *) secret;

/*!
 * Extracts the data from the body of a JWT string;
 *
 * @param message The compleye JWT string.
  * @param error If an error occurs, upon returns contains an NSError object that describes the problem. If you are not interested in possible errors, you may pass in NULL.
 * @return The data from the body of the JWT.
 */
+ (NSDictionary *)extractJTWBodyFromString:(NSString *)message error:(NSError *__autoreleasing*)error;

@end