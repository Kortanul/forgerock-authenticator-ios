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
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "FRAIdentityDatabase.h"
#import "FRAIdentityDatabaseSQLiteOperations.h"
#import "FRAIdentityModel.h"
#import "FRAOathMechanism.h"
#import "FRAOathCode.h"
#import "FRAMechanismFactory.h"

@interface FRAOathMechanismTests : XCTestCase

@end

@implementation FRAOathMechanismTests {

    FRAMechanismFactory* factory;
    FRAIdentityDatabaseSQLiteOperations *mockSqlOperations;
    FRAIdentityDatabase *database;
    FRAIdentityModel *identityModel;
    id databaseObserverMock;

}

- (void)setUp {
    [super setUp];
    mockSqlOperations = OCMClassMock([FRAIdentityDatabaseSQLiteOperations class]);
    database = [[FRAIdentityDatabase alloc] initWithSqlOperations:mockSqlOperations];
    identityModel = [[FRAIdentityModel alloc] initWithDatabase:database];
    factory = [[FRAMechanismFactory alloc] initWithDatabase:database identityModel:identityModel];
    databaseObserverMock = OCMObserverMock();
}

- (void)tearDown {
    [super tearDown];
}

- (void)testShouldGenerateNextCodeSequence {
    // Given
    NSString* qrString = @"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0";
    FRAOathMechanism* mechanism = (FRAOathMechanism*)[factory parseFromString:qrString];
    
    // When
    [mechanism generateNextCode];
    
    // Then
    NSString* code = [[mechanism code] value];
    XCTAssert(strcmp([code UTF8String], "352916") == 0, @"Incorrect next hash");
}

- (void)testGenerateDifferentCodeSequence {
    // Given
    NSString* qrString = @"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOI======&issuer=Forgerock&counter=0";
    FRAOathMechanism* mechanism = (FRAOathMechanism*)[factory parseFromString:qrString];
    
    // When
    [mechanism generateNextCode];
    
    // Then
    NSString* code = [[mechanism code] value];
    XCTAssert(strcmp([code UTF8String], "545550") == 0, @"Incorrect next hash");
}

- (void)testSavedHotpOathMechanismAutomaticallySavesItselfToDatabaseWhenIncrementingCounter {
    // Given
    NSString* qrString = @"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0";
    FRAOathMechanism* mechanism = (FRAOathMechanism*)[factory parseFromString:qrString];
    [database insertMechanism:mechanism];
    
    // When
    [mechanism generateNextCode];
    
    // Then
    OCMVerify([mockSqlOperations updateMechanism:mechanism]);
}

- (void)testBroadcastsOneChangeNotificationWhenHotpOathMechanismUpdateIsAutomaticallySavedToDatabase {
    // Given
    NSString* qrString = @"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0";
    FRAOathMechanism* mechanism = (FRAOathMechanism*)[factory parseFromString:qrString];
    [database insertMechanism:mechanism];
    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:[OCMArg any]];
    
    // When
    [mechanism generateNextCode];
    
    // Then
    OCMVerifyAll(databaseObserverMock);
}

@end