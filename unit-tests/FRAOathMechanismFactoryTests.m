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
 * Copyright 2015-2016 ForgeRock AS.
 */

#import <XCTest/XCTest.h>

#import "FRAError.h"
#import "FRAHotpOathMechanism.h"
#import "FRAIdentity.h"
#import "FRAIdentityDatabase.h"
#import "FRAOathMechanismFactory.h"
#import "FRATotpOathMechanism.h"
#import "FRAUriMechanismReader.h"

static NSUInteger const DEFAULT_CODE_LENGTH = 6;

@interface FRAOathMechanismFactoryTests : XCTestCase

@end

@implementation FRAOathMechanismFactoryTests {
    FRAIdentityModel *identityModel;
    FRAOathMechanismFactory *factory;
}

- (void)setUp {
    [super setUp];
    identityModel = [[FRAIdentityModel alloc] initWithDatabase:nil sqlDatabase:nil];
    factory = [[FRAOathMechanismFactory alloc] init];
}

- (void)testParseHotpOathType {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0"];
    
    // When
    FRAHotpOathMechanism *mechanism = (FRAHotpOathMechanism *)[factory buildMechanism:qrUrl database:nil identityModel:identityModel handler:nil error:nil];
    
    // Then
    XCTAssertNotNil(mechanism);
    XCTAssertEqualObjects([[mechanism class] mechanismType], @"hotp");
}

- (void)testParseTotpOathType {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://totp/ForgeRock:demo?secret=EE3PFF5BM6GHVRNZIBBQWBNRLQ======&issuer=ForgeRock&digits=6&period=30"];
    
    // When
    FRATotpOathMechanism *mechanism = (FRATotpOathMechanism *)[factory buildMechanism:qrUrl database:nil identityModel:identityModel handler:nil error:nil];
    
    // Then
    XCTAssertNotNil(mechanism);
    XCTAssertEqualObjects([[mechanism class] mechanismType], @"totp");
}

- (void)testParseHotpOathDefaultCodeLength {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0"];
    
    // When
    FRAHotpOathMechanism *mechanism = (FRAHotpOathMechanism *)[factory buildMechanism:qrUrl database:nil identityModel:identityModel handler:nil error:nil];
    
    // Then
    XCTAssertEqual(mechanism.codeLength, DEFAULT_CODE_LENGTH);
}

- (void)testParseTotpOathDefaultCodeLength {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://totp/ForgeRock:demo?secret=EE3PFF5BM6GHVRNZIBBQWBNRLQ======&issuer=ForgeRock&period=30"];
    
    // When
    FRATotpOathMechanism *mechanism = (FRATotpOathMechanism *)[factory buildMechanism:qrUrl database:nil identityModel:identityModel handler:nil error:nil];
    
    // Then
    XCTAssertEqual(mechanism.codeLength, DEFAULT_CODE_LENGTH);
}

- (void)testParseHotpOathCodeLength {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0&digits=8"];
    
    // When
    FRAHotpOathMechanism *mechanism = (FRAHotpOathMechanism *)[factory buildMechanism:qrUrl database:nil identityModel:identityModel handler:nil error:nil];
    
    // Then
    XCTAssertEqual(mechanism.codeLength, 8);
}

- (void)testParseTotpOathCodeLength {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://totp/ForgeRock:demo?secret=EE3PFF5BM6GHVRNZIBBQWBNRLQ======&issuer=ForgeRock&digits=8&period=30"];
    
    // When
    FRATotpOathMechanism *mechanism = (FRATotpOathMechanism *)[factory buildMechanism:qrUrl database:nil identityModel:identityModel handler:nil error:nil];
    
    // Then
    XCTAssertEqual(mechanism.codeLength, 8);
}

- (void)testParseHotpOathCounter {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=12&digits=8"];
    
    // When
    FRAHotpOathMechanism *mechanism = (FRAHotpOathMechanism *)[factory buildMechanism:qrUrl database:nil identityModel:identityModel handler:nil error:nil];
    
    // Then
    XCTAssertEqual(mechanism.counter, 12);
}

- (void)testParseTotpOathPeriod {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://totp/ForgeRock:demo?secret=EE3PFF5BM6GHVRNZIBBQWBNRLQ======&issuer=ForgeRock&digits=8&period=30"];
    
    // When
    FRATotpOathMechanism *mechanism = (FRATotpOathMechanism *)[factory buildMechanism:qrUrl database:nil identityModel:identityModel handler:nil error:nil];
    
    // Then
    XCTAssertEqual(mechanism.period, 30);
}

- (void)testParseParentIdentityIssuerAndAccountForHotpOathMechanism {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0"];
    
    // When
    FRAHotpOathMechanism *mechanism = (FRAHotpOathMechanism *)[factory buildMechanism:qrUrl database:nil identityModel:identityModel handler:nil error:nil];
    
    // Then
    FRAIdentity *identity = mechanism.parent;
    XCTAssertEqualObjects(identity.issuer, @"Forgerock");
    XCTAssertEqualObjects(identity.accountName, @"demo");
}

- (void)testParseParentIdentityIssuerAndAccountForTotpOathMechanism {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://totp/Forgerock:demo?secret=EE3PFF5BM6GHVRNZIBBQWBNRLQ======&issuer=ForgeRock&digits=8&period=30"];
    
    // When
    FRATotpOathMechanism *mechanism = (FRATotpOathMechanism *)[factory buildMechanism:qrUrl database:nil identityModel:identityModel handler:nil error:nil];
    
    // Then
    FRAIdentity *identity = mechanism.parent;
    XCTAssertEqualObjects(identity.issuer, @"Forgerock");
    XCTAssertEqualObjects(identity.accountName, @"demo");
}

- (void)testBuildMechanismReturnsNilIfDuplicate {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0&digits=8"];
    [factory buildMechanism:qrUrl database:nil identityModel:identityModel handler:nil error:nil];
    
    // When
    NSError *error;
    FRAMechanism *duplicateMechanism = [factory buildMechanism:qrUrl database:nil identityModel:identityModel handler:nil error:&error];
    
    // Then
    XCTAssertNil(duplicateMechanism);
    XCTAssertEqual(error.code, FRADuplicateMechanism);
}

@end