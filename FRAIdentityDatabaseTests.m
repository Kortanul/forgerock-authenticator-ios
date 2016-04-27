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
#import "FRAIdentity.h"
#import "FRAIdentityDatabase.h"
#import "FRAMechanismFactory.h"
#import "FRAOathMechanism.h"

@interface FRAIdentityDatabaseTests : XCTestCase

@end

@implementation FRAIdentityDatabaseTests

FRAIdentityDatabase* database;
FRAIdentity* aliceIdentity;
FRAOathMechanism* aliceOathMechanism;
FRAIdentity* bobIdentity;
FRAOathMechanism* bobOathMechanism;
FRAMechanismFactory* factory;

- (void)setUp {
    [super setUp];
    database = [[FRAIdentityDatabase alloc] init];
    factory = [[FRAMechanismFactory alloc]init];
    aliceOathMechanism = (FRAOathMechanism*)[factory parseFromString:@"otpauth://hotp/Forgerock:alice?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0"];
    aliceIdentity = [aliceOathMechanism parent];
    bobOathMechanism = (FRAOathMechanism*)[factory parseFromString:@"otpauth://hotp/Forgerock:bob?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0"];
    bobIdentity = [bobOathMechanism parent];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testCanStoreIdentities {
    // Given
    XCTAssertEqualObjects([database identities], @[]);
    
    // When
    [database addIdentity:aliceIdentity];
    [database addIdentity:bobIdentity];
    
    // Then
    XCTAssertTrue([[database identities] containsObject:aliceIdentity]);
    XCTAssertTrue([[database identities] containsObject:bobIdentity]);
}

- (void)testCanFindIdentityById {
    // Given
    XCTAssertEqualObjects([database identities], @[]);
    [database addMechanism:aliceOathMechanism];
    XCTAssertEqual(aliceIdentity.uid, 0);
    
    // When
    FRAIdentity* foundIdentity = [database identityWithId:aliceIdentity.uid];
    
    // Then
    XCTAssertEqual(aliceIdentity, foundIdentity);
}

- (void)testCanFindIdentityByIssuerAndLabel {
    // Given
    [database addIdentity:aliceIdentity];
    
    // When
    FRAIdentity* result = [database identityWithIssuer:aliceIdentity.issuer accountName:aliceIdentity.accountName];
    
    // Then
    XCTAssertTrue(aliceIdentity == result);
}

- (void)testCanRemoveIdentity {
    // Given
    [database addMechanism:aliceOathMechanism];
    
    // When
    [database removeIdentityWithId:aliceIdentity.uid];
    
    // Then
    NSArray* foundIdentities = [database identities];
    XCTAssertEqualObjects(foundIdentities, @[]);
}

- (void)testCanFindMechanismById {
    // Given
    [database addMechanism:aliceOathMechanism];
    
    // When
    FRAOathMechanism* foundMechanism = [database mechanismWithId:[aliceOathMechanism uid]];
    
    // Then
    XCTAssertEqual(aliceOathMechanism, foundMechanism);
}

- (void)testCanRemoveMechanism {
    // Given
    [database addMechanism:aliceOathMechanism];
    
    // When
    [database removeMechanism:aliceOathMechanism];
    
    // Then
    NSArray* foundMechanisms = [aliceIdentity mechanisms];
    XCTAssertEqualObjects(foundMechanisms, @[]);
}

- (void) testRemoveLastMechanismAlsoRemovesIdenitity {
    // Given
    [database addMechanism:aliceOathMechanism];
    
    // When
    [database removeMechanism:aliceOathMechanism];
    
    // Then
    NSArray* foundIdentities = [database identities];
    XCTAssertEqualObjects(foundIdentities, @[]);
}

// TODO: Add tests for listener using OCMock

@end
