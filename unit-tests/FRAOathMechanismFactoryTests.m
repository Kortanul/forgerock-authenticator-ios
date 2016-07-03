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
#import <OCMock/OCMock.h>

#import "FRAError.h"
#import "FRAHotpOathMechanism.h"
#import "FRAIdentity.h"
#import "FRAIdentityDatabase.h"
#import "FRAIdentityDatabaseSQLiteOperations.h"
#import "FRAModelsFromDatabase.h"
#import "FRAOathMechanismFactory.h"
#import "FRATotpOathMechanism.h"
#import "FRAUriMechanismReader.h"

static NSUInteger const DEFAULT_CODE_LENGTH = 6;

@interface FRAOathMechanismFactoryTests : XCTestCase

@end

@implementation FRAOathMechanismFactoryTests {
    FRAIdentityDatabase *identityDatabase;
    FRAIdentityModel *identityModel;
    FRAOathMechanismFactory *factory;
    id mockDatabaseOperations;
    id mockModelsFromDatabase;
}

- (void)setUp {
    [super setUp];
    mockModelsFromDatabase = OCMClassMock([FRAModelsFromDatabase class]);
    OCMStub([mockModelsFromDatabase allIdentitiesWithDatabase:[OCMArg any] identityDatabase:[OCMArg any] identityModel:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(@[]);
    mockDatabaseOperations = OCMClassMock([FRAIdentityDatabaseSQLiteOperations class]);
    OCMStub([mockDatabaseOperations insertIdentity:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([mockDatabaseOperations insertMechanism:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(YES);
    identityDatabase = [[FRAIdentityDatabase alloc] initWithSqlOperations:mockDatabaseOperations];
    identityModel = [[FRAIdentityModel alloc] initWithDatabase:identityDatabase sqlDatabase:nil];
    factory = [[FRAOathMechanismFactory alloc] init];
}

- (void)tearDown {
    [mockDatabaseOperations stopMocking];
    [mockModelsFromDatabase stopMocking];
    [super tearDown];
}

- (void)testParseHotpOathType {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0"];
    
    // When
    FRAHotpOathMechanism *mechanism = (FRAHotpOathMechanism *)[factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:nil];
    
    // Then
    XCTAssertNotNil(mechanism);
    XCTAssertEqualObjects([[mechanism class] mechanismType], @"hotp");
}

- (void)testParseTotpOathType {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://totp/ForgeRock:demo?secret=EE3PFF5BM6GHVRNZIBBQWBNRLQ======&issuer=ForgeRock&digits=6&period=30"];
    
    // When
    FRATotpOathMechanism *mechanism = (FRATotpOathMechanism *)[factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:nil];
    
    // Then
    XCTAssertNotNil(mechanism);
    XCTAssertEqualObjects([[mechanism class] mechanismType], @"totp");
}

- (void)testParseHotpOathDefaultCodeLength {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0"];
    
    // When
    FRAHotpOathMechanism *mechanism = (FRAHotpOathMechanism *)[factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:nil];
    
    // Then
    XCTAssertEqual(mechanism.codeLength, DEFAULT_CODE_LENGTH);
}

- (void)testParseTotpOathDefaultCodeLength {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://totp/ForgeRock:demo?secret=EE3PFF5BM6GHVRNZIBBQWBNRLQ======&issuer=ForgeRock&period=30"];
    
    // When
    FRATotpOathMechanism *mechanism = (FRATotpOathMechanism *)[factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:nil];
    
    // Then
    XCTAssertEqual(mechanism.codeLength, DEFAULT_CODE_LENGTH);
}

- (void)testParseHotpOathCodeLength {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0&digits=8"];
    
    // When
    FRAHotpOathMechanism *mechanism = (FRAHotpOathMechanism *)[factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:nil];
    
    // Then
    XCTAssertEqual(mechanism.codeLength, 8);
}

- (void)testParseTotpOathCodeLength {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://totp/ForgeRock:demo?secret=EE3PFF5BM6GHVRNZIBBQWBNRLQ======&issuer=ForgeRock&digits=8&period=30"];
    
    // When
    FRATotpOathMechanism *mechanism = (FRATotpOathMechanism *)[factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:nil];
    
    // Then
    XCTAssertEqual(mechanism.codeLength, 8);
}

- (void)testParseHotpOathCounter {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=12&digits=8"];
    
    // When
    FRAHotpOathMechanism *mechanism = (FRAHotpOathMechanism *)[factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:nil];
    
    // Then
    XCTAssertEqual(mechanism.counter, 12);
}

- (void)testParseTotpOathPeriod {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://totp/ForgeRock:demo?secret=EE3PFF5BM6GHVRNZIBBQWBNRLQ======&issuer=ForgeRock&digits=8&period=30"];
    
    // When
    FRATotpOathMechanism *mechanism = (FRATotpOathMechanism *)[factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:nil];
    
    // Then
    XCTAssertEqual(mechanism.period, 30);
}

- (void)testParseParentIdentityIssuerAndAccountForHotpOathMechanism {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0"];
    
    // When
    FRAHotpOathMechanism *mechanism = (FRAHotpOathMechanism *)[factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:nil];
    
    // Then
    FRAIdentity *identity = mechanism.parent;
    XCTAssertEqualObjects(identity.issuer, @"Forgerock");
    XCTAssertEqualObjects(identity.accountName, @"demo");
}

- (void)testParseParentIdentityIssuerAndAccountForTotpOathMechanism {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://totp/Forgerock:demo?secret=EE3PFF5BM6GHVRNZIBBQWBNRLQ======&issuer=ForgeRock&digits=8&period=30"];
    
    // When
    FRATotpOathMechanism *mechanism = (FRATotpOathMechanism *)[factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:nil];
    
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
    FRAMechanism *duplicateMechanism = [factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:&error];
    
    // Then
    XCTAssertNil(duplicateMechanism);
    XCTAssertEqual(error.code, FRADuplicateMechanism);
}

- (void)testBuildMechanismReturnsNilIfNoSecretForHotp {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://hotp/Forgerock:demo?secret=&issuer=Forgerock&counter=0&digits=8"];
    
    // When
    NSError *error;
    FRAMechanism *mechanism = [factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAInvalidQRCode);
}

- (void)testBuildMechanismReturnsNilIfNoSecretForTotp {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://totp/Forgerock:demo?secret=&issuer=Forgerock&period=30&digits=8"];
    
    // When
    NSError *error;
    FRAMechanism *mechanism = [factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAInvalidQRCode);
}

- (void)testBuildMechanismReturnsIssuerFromParameter {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://hotp/demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0&digits=8"];
    
    // When
    NSError *error;
    FRAMechanism *mechanism = [factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:&error];

    FRAIdentity *identity = mechanism.parent;
    XCTAssertEqualObjects(identity.issuer, @"Forgerock");
    XCTAssertEqualObjects(identity.accountName, @"demo");
}

- (void)testBuildMechanismWithNoIssuerSetsIssuerToAccountName {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://hotp/Forgerock?secret=IJQWIZ3FOIQUEYLE&counter=0&digits=8"];
    
    // When
    NSError *error;
    FRAMechanism *mechanism = [factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:&error];
    
    FRAIdentity *identity = mechanism.parent;
    XCTAssertEqualObjects(identity.issuer, @"Forgerock");
    XCTAssertEqualObjects(identity.accountName, @"Forgerock");
}

- (void)testBuildMechanismReturnsNilIfTypeIsMissing {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth:///Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0&digits=8"];
    
    // When
    NSError *error;
    FRAMechanism *mechanism = [factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAInvalidQRCode);
}

- (void)testBuildMechanismReturnsNilIfNoCounterForHotp {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&digits=8"];
    
    // When
    NSError *error;
    FRAMechanism *mechanism = [factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAInvalidQRCode);
}

- (void)testBuildMechanismReturnsNilIfInvalidCounterForHotp {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&digits=8&counter=invalid"];
    
    // When
    NSError *error;
    FRAMechanism *mechanism = [factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAInvalidQRCode);
}

- (void)testBuildMechanismReturnsNilIfInvalidPeriodForTotp {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://totp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&digits=8&period=invalid"];
    
    // When
    NSError *error;
    FRAMechanism *mechanism = [factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAInvalidQRCode);
}

- (void)testBuildMechanismReturnsNilIfInvalidAlgorithm {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://hotp/WeightWatchers:Dave?secret=JMEZ2W7D462P3JYBDG2HV7PFBM======&issuer=WeightWatchers&digits=8&algorithm=SHA%20256&counter=0&b=FF00FF&image=http://www.utimes.pitt.edu/wp-content/uploads/2013/01/ww-logo1.jpg"];
    
    // When
    NSError *error;
    FRAMechanism *mechanism = [factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAInvalidQRCode);
}

- (void)testBuildMechanismReturnsNilIfInvalidDigits {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://hotp/WeightWatchers:Dave?secret=JMEZ2W7D462P3JYBDG2HV7PFBM======&issuer=WeightWatchers&digits=9&algorithm=SHA1&period=60&b=FF00FF&image=http://www.utimes.pitt.edu/wp-content/uploads/2013/01/ww-logo1.jpg&counter=0"];
    
    // When
    NSError *error;
    FRAMechanism *mechanism = [factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAInvalidQRCode);
}

- (void)testBuildMechanismReturnsNilIfInvalidBackgroundColor {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://hotp/WeightWatchers:Dave?secret=JMEZ2W7D462P3JYBDG2HV7PFBM======&issuer=WeightWatchers&digits=6&algorithm=SHA1&b=FF0Z0FF&image=http://www.utimes.pitt.edu/wp-content/uploads/2013/01/ww-logo1.jpg&counter=0"];
    
    // When
    NSError *error;
    FRAMechanism *mechanism = [factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAInvalidQRCode);
}

- (void)testBuildMechanismReturnsNilIfTypeIsNotSupported {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://anyotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0&digits=8"];
    
    // When
    NSError *error;
    FRAMechanism *mechanism = [factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAInvalidQRCode);
}

- (void)testBuildMechanismReturnsNilIfCantSaveIdentityInDatabase {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://totp/ForgeRock:demo?secret=EE3PFF5BM6GHVRNZIBBQWBNRLQ======&issuer=ForgeRock&digits=8&period=30"];
    FRAIdentityDatabaseSQLiteOperations *databaseOperations = OCMClassMock([FRAIdentityDatabaseSQLiteOperations class]);
    OCMStub([databaseOperations insertIdentity:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(NO);
    identityDatabase = [[FRAIdentityDatabase alloc] initWithSqlOperations:databaseOperations];
    identityModel = [[FRAIdentityModel alloc] initWithDatabase:identityDatabase sqlDatabase:nil];
    
    // When
    NSError *error;
    FRAMechanism *mechanism = [factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:&error];
    
    XCTAssertNil(mechanism);
}

- (void)testBuildMechanismReturnsNilIfCantSaveMechanismInDatabase {
    // Given
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://totp/ForgeRock:demo?secret=EE3PFF5BM6GHVRNZIBBQWBNRLQ======&issuer=ForgeRock&digits=8&period=30"];
    FRAIdentityDatabaseSQLiteOperations *databaseOperations = OCMClassMock([FRAIdentityDatabaseSQLiteOperations class]);
    OCMStub([databaseOperations insertIdentity:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([databaseOperations insertMechanism:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(NO);
    identityDatabase = [[FRAIdentityDatabase alloc] initWithSqlOperations:databaseOperations];
    identityModel = [[FRAIdentityModel alloc] initWithDatabase:identityDatabase sqlDatabase:nil];
    
    // When
    NSError *error;
    FRAMechanism *mechanism = [factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:&error];
    
    XCTAssertNil(mechanism);
}

@end