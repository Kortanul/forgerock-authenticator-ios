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

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "FRAHotpOathMechanism.h"
#import "FRAIdentityDatabase.h"
#import "FRAIdentityDatabaseSQLiteOperations.h"
#import "FRAIdentityModel.h"
#import "FRAModelsFromDatabase.h"
#import "FRAOathCode.h"
#import "FRAOathMechanismFactory.h"
#import "FRAFMDatabaseConnectionHelper.h"
#import "FRAUriMechanismReader.h"

@interface FRAHotpOathMechanismTests : XCTestCase

@end

@implementation FRAHotpOathMechanismTests {
    id mockSqlOperations;
    id mockSqlDatabase;
    id databaseObserverMock;
    id mockModelsFromDatabase;
    FRAUriMechanismReader *reader;
    FRAIdentityDatabase *database;
    FRAIdentityModel *identityModel;
}

- (void)setUp {
    [super setUp];
    mockModelsFromDatabase = OCMClassMock([FRAModelsFromDatabase class]);
    OCMStub([mockModelsFromDatabase allIdentitiesWithDatabase:[OCMArg any] identityDatabase:[OCMArg any] identityModel:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(@[]);
    mockSqlOperations = OCMClassMock([FRAIdentityDatabaseSQLiteOperations class]);
    OCMStub([mockSqlOperations insertIdentity:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([mockSqlOperations insertMechanism:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([mockSqlOperations updateMechanism:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(YES);
    mockSqlDatabase = OCMClassMock([FRAFMDatabaseConnectionHelper class]);
    database = [[FRAIdentityDatabase alloc] initWithSqlOperations:mockSqlOperations];
    identityModel = [[FRAIdentityModel alloc] initWithDatabase:database sqlDatabase:mockSqlDatabase];
    databaseObserverMock = OCMObserverMock();
    
    // Factory used for parsing OATH URLs
    reader = [[FRAUriMechanismReader alloc] initWithDatabase:database identityModel:identityModel];
    [reader addMechanismFactory:[[FRAOathMechanismFactory alloc] init]];
}

- (void)tearDown {
    [mockSqlOperations stopMocking];
    [mockSqlDatabase stopMocking];
    [mockModelsFromDatabase stopMocking];
    [super tearDown];
}

- (void)testShouldGenerateNextCodeSequence {
    // Given
    NSString *qrString = @"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0";
    FRAHotpOathMechanism *mechanism = (FRAHotpOathMechanism *)[reader parseFromString:qrString handler:nil error:nil];
    
    // When
    BOOL result = [mechanism generateNextCode:nil];
    NSString *nextCode = [mechanism code];
    
    // Then
    XCTAssertTrue(result);
    XCTAssertEqualObjects(nextCode, @"352916", @"Incorrect next hash");
}

- (void)testGenerateDifferentCodeSequence {
    // Given
    NSString *qrString = @"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOI======&issuer=Forgerock&counter=0";
    FRAHotpOathMechanism *mechanism = (FRAHotpOathMechanism *)[reader parseFromString:qrString handler:nil error:nil];
    
    // When
    BOOL result = [mechanism generateNextCode:nil];
    NSString *nextCode = [mechanism code];
    
    // Then
    XCTAssertTrue(result);
    XCTAssertEqualObjects(nextCode, @"545550", @"Incorrect next hash");
}

- (void)testSavedHotpOathMechanismAutomaticallySavesItselfToDatabaseWhenIncrementingCounter {
    // Given
    NSString *qrString = @"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0";
    FRAHotpOathMechanism *mechanism = (FRAHotpOathMechanism *)[reader parseFromString:qrString handler:nil error:nil];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations *)mockSqlOperations insertMechanism:mechanism error:nil]).andReturn(YES);
    [database insertMechanism:mechanism error:nil];
    
    // When
    [mechanism generateNextCode:nil];
    
    // Then
    OCMVerify([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations updateMechanism:mechanism error:nil]);
}

- (void)testBroadcastsOneChangeNotificationWhenHotpOathMechanismUpdateIsAutomaticallySavedToDatabase {
    // Given
    NSString *qrString = @"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0";
    FRAHotpOathMechanism *mechanism = (FRAHotpOathMechanism *)[reader parseFromString:qrString handler:nil error:nil];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations *)mockSqlOperations insertMechanism:mechanism error:nil]).andReturn(YES);
    [database insertMechanism:mechanism error:nil];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations *)mockSqlOperations updateMechanism:mechanism error:nil]).andReturn(YES);
    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:[OCMArg any]];
    
    // When
    [mechanism generateNextCode:nil];
    
    // Then
    OCMVerifyAll(databaseObserverMock);
}

- (void)testGenerateNextCodeReturnsNoIfCantUpdateMechanism {
    // Given
    FRAIdentityDatabaseSQLiteOperations *sqlOperations = OCMClassMock([FRAIdentityDatabaseSQLiteOperations class]);
    OCMStub([sqlOperations insertIdentity:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([sqlOperations insertMechanism:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([sqlOperations updateMechanism:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(NO);
    database = [[FRAIdentityDatabase alloc] initWithSqlOperations:sqlOperations];
    identityModel = [[FRAIdentityModel alloc] initWithDatabase:database sqlDatabase:mockSqlDatabase];
    reader = [[FRAUriMechanismReader alloc] initWithDatabase:database identityModel:identityModel];
    [reader addMechanismFactory:[[FRAOathMechanismFactory alloc] init]];
    NSString *qrString = @"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOI======&issuer=Forgerock&counter=0";
    FRAHotpOathMechanism *mechanism = (FRAHotpOathMechanism *)[reader parseFromString:qrString handler:nil error:nil];
    
    // When
    BOOL result = [mechanism generateNextCode:nil];
    NSString *code = [mechanism code];
    
    // Then
    XCTAssertFalse(result);
    XCTAssertNil(code);
}

@end