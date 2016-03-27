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
#import "FRAOathMechanism.h"

@interface FRAIdentityDatabaseTests : XCTestCase

@end

@implementation FRAIdentityDatabaseTests

FRAIdentityDatabase* database;
FRAIdentity* identity;
FRAOathMechanism* mechanism;

- (void)setUp {
    [super setUp];
    database = [[FRAIdentityDatabase alloc] init];
    identity = [FRAIdentity identityWithAccountName:@"demo" issuedBy:@"Forgerock" withImage:[NSURL URLWithString:@"https://forgerock.org/ico/favicon-32x32.png"]];
    mechanism = [[FRAOathMechanism alloc] initWithString:@"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0"];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testCanStoreIdentities {
    // Given
    XCTAssertEqualObjects([database identities], @[]);
    
    // When
    [database addIdentity:identity];
    
    // Then
    XCTAssertEqualObjects([database identities], @[identity]);
}

- (void)testCanFindIdentityByIssuerAndLabel {
    // Given
    [database addIdentity:identity];
    
    // When
    FRAIdentity* result = [database identityWithIssuer:identity.issuer accountName:identity.accountName];
    
    // Then
    XCTAssertTrue(identity == result);
}

- (void)testCanFindMechanismByOwner {
    // Given
    XCTAssertEqualObjects([database mechanismsWithOwner:identity], @[]);
    
    // When
    [database addMechanism:mechanism];
    
    // Then
    NSArray* foundMechanisms = [database mechanismsWithOwner:identity];
    XCTAssertEqualObjects(foundMechanisms, @[mechanism]);
}

- (void)testCanFindMechanismByRowId {
    // Given
    XCTAssertEqualObjects([database mechanismsWithOwner:identity], @[]);
    [database addMechanism:mechanism];
    XCTAssertEqual(mechanism.uid, 1);
    
    // When
    FRAOathMechanism* foundMechanism = [database mechanismWithId:1];
    
    // Then
    XCTAssertEqual(mechanism, foundMechanism);
}

- (void)testCanRemoveMechanism {
    // Given
    [database addMechanism:mechanism];
    
    // When
    [database removeMechanismWithId:mechanism.uid];
    
    // Then
    NSArray* foundMechanisms = [database mechanismsWithOwner:identity];
    XCTAssertEqualObjects(foundMechanisms, @[]);
    NSArray* foundIdentities = [database identities];
    XCTAssertEqualObjects(foundIdentities, @[]);
}

- (void)testCanUpdateMechanism {
    // Given
    [database addMechanism:mechanism];
    FRAOathMechanism* mechanismCopy = [[FRAOathMechanism alloc] initWithString:@"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0"];
    mechanismCopy.uid = mechanism.uid;
    
    // When
    [database updateMechanism:mechanismCopy];
    FRAOathMechanism* foundMechanism = [database mechanismWithId:1];
    
    // Then
    XCTAssertNotEqual(mechanism, foundMechanism);
    XCTAssertEqual(mechanismCopy, foundMechanism);
}

// TODO: Add tests for listener using OCMock

@end
