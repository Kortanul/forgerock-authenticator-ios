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

#import <OCMock/OCMock.h>

#import <XCTest/XCTest.h>

#import "FRAIdentityDatabase.h"
#import "FRAIdentityDatabaseSQLiteOperations.h"
#import "FRAIdentityModel.h"
#import "FRAOathCode.h"
#import "FRAOathMechanism.h"
#import "FRAOathMechanismFactory.h"
#import "FRAFMDatabaseConnectionHelper.h"
#import "FRAUriMechanismReader.h"

@interface FRAOathMechanismTests : XCTestCase

@end

@implementation FRAOathMechanismTests {
    id mockSqlOperations;
    id mockSqlDatabase;
    id databaseObserverMock;
    FRAUriMechanismReader* factory;
    FRAIdentityDatabase *database;
    FRAIdentityModel *identityModel;
}

- (void)setUp {
    [super setUp];
    mockSqlOperations = OCMClassMock([FRAIdentityDatabaseSQLiteOperations class]);
    mockSqlDatabase = OCMClassMock([FRAFMDatabaseConnectionHelper class]);
    database = [[FRAIdentityDatabase alloc] initWithSqlOperations:mockSqlOperations];
    identityModel = [[FRAIdentityModel alloc] initWithDatabase:database sqlDatabase:mockSqlDatabase];
    databaseObserverMock = OCMObserverMock();
    
    // Factory used for parsing OATH URLs
    factory = [[FRAUriMechanismReader alloc] initWithDatabase:database identityModel:identityModel];
    [factory addMechanismFactory:[[FRAOathMechanismFactory alloc] init]];
}

- (void)tearDown {
    [mockSqlOperations stopMocking];
    [mockSqlDatabase stopMocking];
    [super tearDown];
}

- (void)testShouldGenerateNextCodeSequence {
    // Given
    NSString* qrString = @"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0";
    FRAOathMechanism* mechanism = (FRAOathMechanism*)[factory parseFromString:qrString];
    
    // When
    [mechanism generateNextCodeWithError:nil];
    NSString* result = [[mechanism code] value];
    
    // Then
    XCTAssertEqualObjects(result, @"352916", @"Incorrect next hash");
}

- (void)testGenerateDifferentCodeSequence {
    // Given
    NSString* qrString = @"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOI======&issuer=Forgerock&counter=0";
    FRAOathMechanism* mechanism = (FRAOathMechanism*)[factory parseFromString:qrString];
    
    // When
    [mechanism generateNextCodeWithError:nil];
    NSString* result = [[mechanism code] value];
    
    // Then
    XCTAssertEqualObjects(result, @"545550", @"Incorrect next hash");
}

- (void)testSavedHotpOathMechanismAutomaticallySavesItselfToDatabaseWhenIncrementingCounter {
    // Given
    NSString* qrString = @"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0";
    FRAOathMechanism* mechanism = (FRAOathMechanism*)[factory parseFromString:qrString];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:mechanism error:nil]).andReturn(YES);
    [database insertMechanism:mechanism error:nil];
    
    // When
    [mechanism generateNextCodeWithError:nil];
    
    // Then
    OCMVerify([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations updateMechanism:mechanism error:nil]);
}

- (void)testBroadcastsOneChangeNotificationWhenHotpOathMechanismUpdateIsAutomaticallySavedToDatabase {
    // Given
    NSString* qrString = @"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0";
    FRAOathMechanism* mechanism = (FRAOathMechanism*)[factory parseFromString:qrString];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:mechanism error:nil]).andReturn(YES);
    [database insertMechanism:mechanism error:nil];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations updateMechanism:mechanism error:nil]).andReturn(YES);
    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:[OCMArg any]];
    
    // When
    [mechanism generateNextCodeWithError:nil];
    
    // Then
    OCMVerifyAll(databaseObserverMock);
}

@end