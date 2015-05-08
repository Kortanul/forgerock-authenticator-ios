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
 * Copyright 2015 ForgeRock AS.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Token.h"

@interface Tokentest : XCTestCase

@end

@implementation Tokentest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testSecretKeyParse {
    // Given
    NSString* token = @"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0";
    
    // When
    Token* result = [[Token alloc] initWithString:token];
    
    // Then
    NSString* code = [[result code] currentCode]; // Testing parsing by testing generated code.
    XCTAssert(strcmp([code UTF8String], "352916") == 0, @"Secret Key parsing failed");
}

- (void)testSecretKeyCanParseEqualSymbol {
    // Given
    NSString* token = @"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOI======&issuer=Forgerock&counter=0";
    
    // When
    Token* result = [[Token alloc] initWithString:token];
    
    // Then
    NSString* code = [[result code] currentCode]; // Testing parsing by testing generated code.
    XCTAssert(strcmp([code UTF8String], "545550") == 0, @"Secret Key parsing failed");
}

@end
