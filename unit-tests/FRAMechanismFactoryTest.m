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

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "FRAIdentity.h"
#import "FRAMechanismFactory.h"
#import "FRAOathCode.h"
#import "FRAOathMechanism.h"

@interface FRAMechanismFactoryTest : XCTestCase

@end

@implementation FRAMechanismFactoryTest {
    FRAMechanismFactory* factory;
}

- (void)setUp {
    [super setUp];
    factory = [[FRAMechanismFactory alloc] init];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testParseOATHType {
    // Given
    NSString* qrString = @"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0";
    
    // When
    FRAOathMechanism* mechanism = (FRAOathMechanism*)[factory parseFromString:qrString];
    
    // Then
    XCTAssert(strcmp([[mechanism type] UTF8String], "hotp") == 0);
}

- (void)testParseOATHDefaultDigits {
    // Given
    NSString* qrString = @"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0";
    
    // When
    FRAOathMechanism* mechanism = (FRAOathMechanism*)[factory parseFromString:qrString];
    
    // Then
    XCTAssertEqual([mechanism digits], 6);
}

- (void)testParseOATHDigits {
    // Given
    NSString* qrString = @"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0&digits=8";
    
    // When
    FRAOathMechanism* mechanism = (FRAOathMechanism*)[factory parseFromString:qrString];
    
    // Then
    XCTAssertEqual([mechanism digits], 8);
}

- (void)testParseParentIdentityIssuerAndAccount {
    // Given
    NSString* qrString = @"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0";
    
    // When
    FRAMechanism* mechanism = [factory parseFromString:qrString];
    
    // Then
    FRAIdentity* identity = [mechanism parent];
    XCTAssert(strcmp([[identity issuer] UTF8String], "Forgerock") == 0);
    XCTAssert(strcmp([[identity accountName] UTF8String], "demo") == 0);
}

@end
