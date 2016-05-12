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

#import <XCTest/XCTest.h>
#import "FRAMessageUtils.h"
#import "FRAMockURLProtocol.h"

static NSString * const url = @"http://any.website.com";
static NSString * const messageId = @"message id";
static NSString * const base64Secret = @"c2VjcmV0";
static NSTimeInterval const testTimeout = 10.0;

@interface FRAMessageUtilsTests : XCTestCase

@end

@implementation FRAMessageUtilsTests {
    FRAMessageUtils *messageUtils;
}

- (void)setUp {
    [super setUp];
    messageUtils =[FRAMessageUtils alloc];
}

- (void)tearDown {
    [FRAMockURLProtocol setResponseData:nil];
    [FRAMockURLProtocol setResponseHeaders:nil];
    [FRAMockURLProtocol setError:nil];
    [super tearDown];
}

- (void)testUsePost {
    XCTestExpectation *expectation = [self expectationWithDescription:@"asynchronous request"];
    
    [messageUtils respond:url
         base64Secret:base64Secret
             messageId:messageId
                  data:@{@"some":@"data"}
              protocol:[FRAMockURLProtocol class]
               handler:^(NSInteger statusCode, NSError *error) {
                   NSURLRequest *request = [FRAMockURLProtocol getRequest];
                   XCTAssertEqualObjects([request HTTPMethod], @"POST");
                   [expectation fulfill];
               }];
    
    [self waitForExpectationsWithTimeout:testTimeout handler:nil];
}

- (void)testMakeCallToUrl {
    XCTestExpectation *expectation = [self expectationWithDescription:@"asynchronous request"];
    
    [messageUtils respond:url
         base64Secret:base64Secret
             messageId:messageId
                  data:@{@"some":@"data"}
              protocol:[FRAMockURLProtocol class]
               handler:^(NSInteger statusCode, NSError *error) {
                NSURLRequest *request = [FRAMockURLProtocol getRequest];
                XCTAssertEqual(request.URL.absoluteString, url);
                [expectation fulfill];
            }];

    [self waitForExpectationsWithTimeout:testTimeout handler:nil];
}

- (void)testSetJsonContentType {
    XCTestExpectation *expectation = [self expectationWithDescription:@"asynchronous request"];
    
    [messageUtils respond:url
         base64Secret:base64Secret
             messageId:messageId
                  data:@{@"some":@"data"}
              protocol:[FRAMockURLProtocol class]
               handler:^(NSInteger statusCode, NSError *error) {
                   NSURLRequest *request = [FRAMockURLProtocol getRequest];
                   XCTAssertEqualObjects([request valueForHTTPHeaderField:@"Content-Type"], @"application/json");
                   [expectation fulfill];
               }];
    
    [self waitForExpectationsWithTimeout:testTimeout handler:nil];
}

@end

