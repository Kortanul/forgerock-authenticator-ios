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

#import "FRAMockURLProtocol.h"

static NSURLRequest *initialRequest;
static NSData *mockResponseData = nil;
static NSDictionary *mockResponseHeaders = nil;
static NSInteger mockStatusCode = 200;
static NSError *mockError = nil;

@implementation FRAMockURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if(request != initialRequest) {
        initialRequest = request;
    }
    
    return YES;
}

+ (NSURLRequest *)getRequest {
    return initialRequest;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

+ (void)setResponseData:(NSData*)data {
    if(data != mockResponseData) {
        mockResponseData = data;
    }
}

+ (void)setResponseHeaders:(NSDictionary*)headers {
    if(headers != mockResponseHeaders) {
        mockResponseHeaders = headers;
    }
}

+ (void)setStatusCode:(NSInteger)statusCode {
    mockStatusCode = statusCode;
}

+ (void)setError:(NSError*)error {
    if(error != mockError) {
        mockError = error;
    }
}

- (NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (void)startLoading {
    
    NSURLRequest *request = [self request];
    id<NSURLProtocolClient> client = [self client];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[request URL]
                                                              statusCode:mockStatusCode
                                                             HTTPVersion:@"1.1"
                                                            headerFields:mockResponseHeaders];
    
    [client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [client URLProtocol:self didLoadData:mockResponseData];
    [client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {
}

@end
