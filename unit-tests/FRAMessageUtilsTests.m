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

@implementation FRAMessageUtilsTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [FRAMockURLProtocol setResponseData:nil];
    [FRAMockURLProtocol setResponseHeaders:nil];
    [FRAMockURLProtocol setError:nil];
    [super tearDown];
}

- (void)testUsePost {
    XCTestExpectation *expectation = [self expectationWithDescription:@"asynchronous request"];
    
    [FRAMessageUtils respondWithEndpoint:url
                            base64Secret:base64Secret
                               messageId:messageId
                  loadBalancerCookieData:@"amlbcookie=03"
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
    
    [FRAMessageUtils respondWithEndpoint:url
                            base64Secret:base64Secret
                               messageId:messageId
                  loadBalancerCookieData:@"amlbcookie=03"
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
    
    [FRAMessageUtils respondWithEndpoint:url
                            base64Secret:base64Secret
                               messageId:messageId
                  loadBalancerCookieData:@"amlbcookie=03"
                                    data:@{@"some":@"data"}
                                protocol:[FRAMockURLProtocol class]
                                 handler:^(NSInteger statusCode, NSError *error) {
                                     NSURLRequest *request = [FRAMockURLProtocol getRequest];
                                     XCTAssertEqualObjects([request valueForHTTPHeaderField:@"Content-Type"], @"application/json");
                                     [expectation fulfill];
                                 }];
    
    [self waitForExpectationsWithTimeout:testTimeout handler:nil];
}

-(void)testDecodeJWTMessage {
    NSString* altertJwt = @"eyAidHlwIjogIkpXVCIsICJhbGciOiAiSFMyNTYiIH0.eyAiYyI6ICJKZVlTTXlLdW9QbldmRHVXaU1GVGlENlc2WTNQOWVYTVBYUDljNUEvSEJNPSIsICJ0IjogIjEyMCIsICJ1IjogIjMiLCAibCI6ICJZVzFzWW1OdmIydHBaVDFoYld4aVkyOXZhMmxsUFRBeCIgfQ.1SAWJlT-5vjYRbpZ_57K-NpFRs4VZbSzZjAF_3RTu7k";
    
    NSDictionary* dictionary = [FRAMessageUtils extractJTWBodyFromString:altertJwt error:nil];
    
    XCTAssertEqualObjects([dictionary valueForKey:@"c"], @"JeYSMyKuoPnWfDuWiMFTiD6W6Y3P9eXMPXP9c5A/HBM=");
    XCTAssertEqualObjects([dictionary valueForKey:@"l"], @"YW1sYmNvb2tpZT1hbWxiY29va2llPTAx");
    XCTAssertEqualObjects([dictionary valueForKey:@"t"], @"120");
    XCTAssertEqualObjects([dictionary valueForKey:@"u"], @"3");
}

- (void)testIncludesLoadBalancerCookie {
    XCTestExpectation *expectation = [self expectationWithDescription:@"request with cookie"];

    [FRAMessageUtils respondWithEndpoint:url
                            base64Secret:base64Secret
                               messageId:messageId
                  loadBalancerCookieData:@"amlbcookie=03"
                                    data:@{@"some":@"data"}
                                protocol:[FRAMockURLProtocol class]
                                 handler:^(NSInteger statusCode, NSError *error) {
                                     NSURLRequest *request = [FRAMockURLProtocol getRequest];

                                     NSArray *cookies =[[NSArray alloc]init];
                                     cookies = [NSHTTPCookie
                                                cookiesWithResponseHeaderFields:[request allHTTPHeaderFields]
                                                forURL:[NSURL URLWithString:@""]];
                                     NSHTTPCookie *actualCookie = cookies.firstObject;

                                     XCTAssertTrue([@"amlbcookie" isEqualToString:actualCookie.name]);
                                     XCTAssertTrue([@"03" isEqualToString:actualCookie.value]);

                                     [expectation fulfill];
                                 }];

    [self waitForExpectationsWithTimeout:testTimeout handler:nil];
}

- (void)testIncludesAcceptAPIVersionHeader {
    XCTestExpectation *expectation = [self expectationWithDescription:@"request with api version header"];
    
    [FRAMessageUtils respondWithEndpoint:url
                            base64Secret:base64Secret
                               messageId:messageId
                  loadBalancerCookieData:@"amlbcookie=03"
                                    data:@{@"some":@"data"}
                                protocol:[FRAMockURLProtocol class]
                                 handler:^(NSInteger statusCode, NSError *error) {
                                     NSURLRequest *request = [FRAMockURLProtocol getRequest];
                                     
                                     NSDictionary<NSString *, NSString *> *headers = [request allHTTPHeaderFields];
                                     NSString *acceptAPIVersionHeader = [headers valueForKey:@"Accept-API-Version"];
                                     
                                     XCTAssertNotNil(acceptAPIVersionHeader);
                                     XCTAssertEqualObjects(acceptAPIVersionHeader, @"resource=1.0, protocol=1.0");
                                     
                                     [expectation fulfill];
                                 }];
    
    [self waitForExpectationsWithTimeout:testTimeout handler:nil];
}

@end

