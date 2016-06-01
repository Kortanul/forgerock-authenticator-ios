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

#import "FRAFMDatabaseConnectionHelper.h"
#import "FRAIdentity.h"
#import "FRAIdentityDatabase.h"
#import "FRAIdentityDatabaseSQLiteOperations.h"
#import "FRAIdentityModel.h"
#import "FRAMechanism.h"
#import "FRANotification.h"
#import "FRAPushMechanism.h"

@interface FRAIdentityModelTests : XCTestCase

@end

@implementation FRAIdentityModelTests {
    id mockSqlOperations;
    id mockSqlDatabase;
    id databaseObserverMock;
    FRAIdentityDatabase *database;
    FRAIdentityModel *identityModel;
    FRAIdentity *aliceIdentity;
    FRAIdentity *bobIdentity;
}

- (void)setUp {
    [super setUp];
    mockSqlOperations = OCMClassMock([FRAIdentityDatabaseSQLiteOperations class]);
    mockSqlDatabase = OCMClassMock([FRAFMDatabaseConnectionHelper class]);
    database = [[FRAIdentityDatabase alloc] initWithSqlOperations:mockSqlOperations];
    identityModel = [[FRAIdentityModel alloc] initWithDatabase:database sqlDatabase:mockSqlDatabase];
    aliceIdentity = [FRAIdentity identityWithDatabase:database identityModel:identityModel accountName:@"alice" issuer:@"Forgerock" image:nil backgroundColor:nil];
    bobIdentity = [FRAIdentity identityWithDatabase:database identityModel:identityModel accountName:@"bob" issuer:@"Forgerock" image:nil backgroundColor:nil];
    databaseObserverMock = OCMObserverMock();
}

- (void)tearDown {
    [mockSqlOperations stopMocking];
    [mockSqlDatabase stopMocking];
    [super tearDown];
}

- (void)testCanSaveNewIdentityToDatabase {
    // Given
    OCMStub([mockSqlOperations insertIdentity:aliceIdentity error:nil]).andReturn(YES);
    XCTAssertEqualObjects([identityModel identities], @[]);
    
    // When
    BOOL aliceAdded = [identityModel addIdentity:aliceIdentity error:nil];
    
    // Then
    XCTAssertTrue(aliceAdded);
    XCTAssertTrue([aliceIdentity isStored]);
    XCTAssertTrue([[identityModel identities] containsObject:aliceIdentity]);
    OCMVerify([mockSqlOperations insertIdentity:aliceIdentity error:nil]);
}

- (void)testBroadcastsOneChangeNotificationWhenIdentityIsSavedToDatabase {
    // Given
    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    OCMStub([mockSqlOperations insertIdentity:aliceIdentity error:nil]).andReturn(YES);
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:[OCMArg any]];
    
    // When
    BOOL aliceAdded = [identityModel addIdentity:aliceIdentity error:nil];
    
    // Then
    XCTAssertTrue(aliceAdded);
    OCMVerifyAll(databaseObserverMock);
}

- (void)testCanFindIdentityByIssuerAndLabel {
    // Given
    OCMStub([mockSqlOperations insertIdentity:aliceIdentity error:nil]).andReturn(YES);
    [identityModel addIdentity:aliceIdentity error:nil];
    
    // When
    FRAIdentity* foundIdentity = [identityModel identityWithIssuer:aliceIdentity.issuer accountName:aliceIdentity.accountName];
    
    // Then
    XCTAssertEqual(aliceIdentity, foundIdentity);
}

- (void)testCanRemoveIdentityFromDatabase {
    // Given
    OCMStub([mockSqlOperations insertIdentity:aliceIdentity error:nil]).andReturn(YES);
    [identityModel addIdentity:aliceIdentity error:nil];
    OCMStub([mockSqlOperations deleteIdentity:aliceIdentity error:nil]).andReturn(YES);
    
    // When
    BOOL aliceRemoved = [identityModel removeIdentity:aliceIdentity error:nil];
    
    // Then
    XCTAssertTrue(aliceRemoved);
    XCTAssertFalse([aliceIdentity isStored]);
    XCTAssertFalse([[identityModel identities] containsObject:aliceIdentity]);
}

- (void)testBroadcastsOneChangeNotificationWhenIdentityIsRemovedFromDatabase {
    // Given
    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    OCMStub([mockSqlOperations insertIdentity:aliceIdentity error:nil]).andReturn(YES);
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:[OCMArg any]];
    [identityModel addIdentity:aliceIdentity error:nil];
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:[OCMArg any]];
    OCMStub([mockSqlOperations deleteIdentity:aliceIdentity error:nil]).andReturn(YES);
    
    // When
    BOOL aliceRemoved = [identityModel removeIdentity:aliceIdentity error:nil];
    
    // Then
    XCTAssertTrue(aliceRemoved);
    OCMVerifyAll(databaseObserverMock);
}

- (void)testCanSaveMechanismsOfNewIdentityToDatabase {
    // Given
    FRAPushMechanism *mechanism = [[FRAPushMechanism alloc] initWithDatabase:database identityModel:identityModel];
    OCMStub([mockSqlOperations insertMechanism:mechanism error:nil]).andReturn(YES);
    OCMStub([mockSqlOperations insertIdentity:aliceIdentity error:nil]).andReturn(YES);
    [aliceIdentity addMechanism:mechanism error:nil];
    XCTAssertFalse([mechanism isStored]);
    
    // When
    BOOL aliceAdded = [identityModel addIdentity:aliceIdentity error:nil];
    
    // Then
    XCTAssertTrue(aliceAdded);
    XCTAssertTrue([mechanism isStored]);
    XCTAssertTrue([aliceIdentity isStored]);
    OCMVerify([mockSqlOperations insertIdentity:aliceIdentity error:nil]);
    OCMVerify([mockSqlOperations insertMechanism:mechanism error:nil]);
}

- (void)testBroadcastsOneChangeNotificationWhenIdentityObjectGraphIsSavedToDatabase {
    // Given
    FRAPushMechanism *mechanism = [[FRAPushMechanism alloc] initWithDatabase:database identityModel:identityModel];
    [aliceIdentity addMechanism:mechanism error:nil];
    NSTimeInterval timeToLive = 120.0;
    FRANotification *notification = [[FRANotification alloc] initWithDatabase:database identityModel:identityModel messageId:@"messageId" challenge:@"challenge" timeReceived:[NSDate date] timeToLive:timeToLive];

    [mechanism addNotification:notification error:nil];

    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    NSDictionary *expectedChanges = @{
            @"added" : [NSSet setWithObjects:notification, mechanism, aliceIdentity, nil],
            @"removed" : [NSSet set],
            @"updated" : [NSSet set]
    };
    OCMStub([mockSqlOperations insertNotification:notification error:nil]).andReturn(YES);
    OCMStub([mockSqlOperations insertMechanism:mechanism error:nil]).andReturn(YES);
    OCMStub([mockSqlOperations insertIdentity:aliceIdentity error:nil]).andReturn(YES);
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:expectedChanges];
    
    // When
    BOOL aliceAdded = [identityModel addIdentity:aliceIdentity error:nil];
    
    // Then
    XCTAssertTrue(aliceAdded);
    XCTAssertTrue([notification isStored]);
    XCTAssertTrue([mechanism isStored]);
    XCTAssertTrue([aliceIdentity isStored]);
    OCMVerifyAll(databaseObserverMock);
}

- (void)testBroadcastsOneChangeNotificationWhenIdentityObjectGraphIsRemovedFromDatabase {
    // Given
    FRAPushMechanism *mechanism = [[FRAPushMechanism alloc] initWithDatabase:database identityModel:identityModel];
    [aliceIdentity addMechanism:mechanism error:nil];
    NSTimeInterval timeToLive = 120.0;
    FRANotification *notification = [[FRANotification alloc] initWithDatabase:database identityModel:identityModel messageId:@"messageId" challenge:@"challenge" timeReceived:[NSDate date] timeToLive:timeToLive];
    [mechanism addNotification:notification error:nil];

    OCMStub([mockSqlOperations insertIdentity:aliceIdentity error:nil]).andReturn(YES);
    OCMStub([mockSqlOperations insertNotification:notification error:nil]).andReturn(YES);
    OCMStub([mockSqlOperations insertMechanism:mechanism error:nil]).andReturn(YES);

    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:[OCMArg any]];
    [identityModel addIdentity:aliceIdentity error:nil];
    
    NSDictionary *expectedChanges = @{
            @"added" : [NSSet set],
            @"removed" : [NSSet setWithObjects:notification, mechanism, aliceIdentity, nil],
            @"updated" : [NSSet set]
    };
    OCMStub([mockSqlOperations deleteIdentity:aliceIdentity error:nil]).andReturn(YES);
    OCMStub([mockSqlOperations deleteNotification:notification error:nil]).andReturn(YES);
    OCMStub([mockSqlOperations deleteMechanism:mechanism error:nil]).andReturn(YES);
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:expectedChanges];
    
    // When
    BOOL aliceRemoved = [identityModel removeIdentity:aliceIdentity error:nil];
    
    // Then
    XCTAssertTrue(aliceRemoved);
    XCTAssertFalse([notification isStored]);
    XCTAssertFalse([mechanism isStored]);
    XCTAssertFalse([aliceIdentity isStored]);
    OCMVerifyAll(databaseObserverMock);
}

- (void)testCanFindMechanismById {
    // Given
    OCMStub([mockSqlOperations insertIdentity:aliceIdentity error:nil]).andReturn(YES);
    [identityModel addIdentity:aliceIdentity error:nil];
    FRAPushMechanism *mechanism = [[FRAPushMechanism alloc] initWithDatabase:database identityModel:identityModel];
    OCMStub([mockSqlOperations insertMechanism:mechanism error:nil]).andReturn(YES);
    [aliceIdentity addMechanism:mechanism error:nil];
    
    // When
    FRAMechanism *foundMechanism = [identityModel mechanismWithId:mechanism.mechanismUID];
    
    // Then
    XCTAssertEqual(mechanism, foundMechanism);
}

@end
