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

#import "FRAQRUtils.h"

@interface FRAQRUtilsTests : XCTestCase

@end

@implementation FRAQRUtilsTests

- (void)testReplaceCharactersForURLDecodingReplacesDashes {
    
    NSString *content = @"-123-456-";
    
    NSString *result = [FRAQRUtils replaceCharactersForURLDecoding:content];
    
    XCTAssertEqualObjects(result, @"+123+456+");
}

- (void)testReplaceCharactersForURLDecodingReplacesUnderscores {
    
    NSString *content = @"_123_456_";
    
    NSString *result = [FRAQRUtils replaceCharactersForURLDecoding:content];
    
    XCTAssertEqualObjects(result, @"/123/456/");
}

- (void)testReplaceCharactersForURLDecodingDoesntReplaceIfValid {
    
    NSString *content = @"123456";
    
    NSString *result = [FRAQRUtils replaceCharactersForURLDecoding:content];
    
    XCTAssertEqualObjects(result, @"123456");
}

- (void)testDecodeBase64NilReturnsNil {
    
    NSData *result = [FRAQRUtils decodeBase64:nil];
    
    XCTAssertNil(result);
}

@end