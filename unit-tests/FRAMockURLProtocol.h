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

/*!
 * Mock implementation of NSURLProtocol, used for testing.
 */
@interface FRAMockURLProtocol : NSURLProtocol

/*!
 * Get the HTTP request.
 *
 * @return The HTTP request.
 */
+ (NSURLRequest *)getRequest;

/*!
 * Set the payload of the HTTP request.
 *
 * @param data The payload.
 */
+ (void)setResponseData:(NSData*)data;

/*!
 * Set the response headers.
 *
 * @param headers The response HTTP headers.
 */
+ (void)setResponseHeaders:(NSDictionary*)headers;

/*!
 * Set the request status code.
 *
 * @param statusCode The response status code.
 */
+ (void)setStatusCode:(NSInteger)statusCode;

/*!
 * Set the response error (e.g. timeout).
 *
 * @param error The error.
 */
+ (void)setError:(NSError*)error;

@end