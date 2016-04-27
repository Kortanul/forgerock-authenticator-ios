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

    FRAIdentityDatabaseSQLiteOperations *mockSqlOperations;
    FRAIdentityDatabase *database;
    FRAIdentityModel *identityModel;
    FRAIdentity *aliceIdentity;
    FRAIdentity *bobIdentity;
    id databaseObserverMock;

}

- (void)setUp {
    [super setUp];
    mockSqlOperations = OCMClassMock([FRAIdentityDatabaseSQLiteOperations class]);
    database = [[FRAIdentityDatabase alloc] initWithSqlOperations:mockSqlOperations];
    identityModel = [[FRAIdentityModel alloc] initWithDatabase:database];
    aliceIdentity = [FRAIdentity identityWithDatabase:database accountName:@"alice" issuer:@"Forgerock" image:nil];
    bobIdentity = [FRAIdentity identityWithDatabase:database accountName:@"bob" issuer:@"Forgerock" image:nil];
    databaseObserverMock = OCMObserverMock();
}

- (void)tearDown {
    [super tearDown];
}

- (void)testCanSaveNewIdentityToDatabase {
    // Given
    XCTAssertEqualObjects([identityModel identities], @[]);
    
    // When
    [identityModel addIdentity:aliceIdentity];
    
    // Then
    XCTAssertTrue([aliceIdentity isStored]);
    XCTAssertTrue([[identityModel identities] containsObject:aliceIdentity]);
    OCMVerify([mockSqlOperations insertIdentity:aliceIdentity]);
}

- (void)testBroadcastsOneChangeNotificationWhenIdentityIsSavedToDatabase {
    // Given
    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:[OCMArg any]];
    
    // When
    [identityModel addIdentity:aliceIdentity];
    
    // Then
    OCMVerifyAll(databaseObserverMock);
}

- (void)testSavedIdentitiesAreGivenUniqueStorageIds {
    // Given
    
    // When
    [identityModel addIdentity:aliceIdentity];
    [identityModel addIdentity:bobIdentity];
    
    // Then
    XCTAssertTrue([aliceIdentity isStored]);
    XCTAssertTrue([bobIdentity isStored]);
    XCTAssertNotEqual(aliceIdentity.uid, bobIdentity.uid);
}

- (void)testCanFindIdentityById {
    // Given
    [identityModel addIdentity:aliceIdentity];
    
    // When
    FRAIdentity* foundIdentity = [identityModel identityWithId:aliceIdentity.uid];
    
    // Then
    XCTAssertEqual(aliceIdentity, foundIdentity);
}

- (void)testCanFindIdentityByIssuerAndLabel {
    // Given
    [identityModel addIdentity:aliceIdentity];
    
    // When
    FRAIdentity* foundIdentity = [identityModel identityWithIssuer:aliceIdentity.issuer accountName:aliceIdentity.accountName];
    
    // Then
    XCTAssertEqual(aliceIdentity, foundIdentity);
}

- (void)testCanRemoveIdentityFromDatabase {
    // Given
    [identityModel addIdentity:aliceIdentity];
    
    // When
    [identityModel removeIdentity:aliceIdentity];
    
    // Then
    XCTAssertFalse([aliceIdentity isStored]);
    XCTAssertFalse([[identityModel identities] containsObject:aliceIdentity]);
}

- (void)testBroadcastsOneChangeNotificationWhenIdentityIsRemovedFromDatabase {
    // Given
    [identityModel addIdentity:aliceIdentity];
    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:[OCMArg any]];
    
    // When
    [identityModel removeIdentity:aliceIdentity];
    
    // Then
    OCMVerifyAll(databaseObserverMock);
}

- (void)testCanSaveMechanismsOfNewIdentityToDatabase {
    // Given
    FRAPushMechanism *mechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    [aliceIdentity addMechanism:mechanism];
    XCTAssertFalse([mechanism isStored]);
    
    // When
    [identityModel addIdentity:aliceIdentity];
    
    // Then
    XCTAssertTrue([mechanism isStored]);
    XCTAssertTrue([aliceIdentity isStored]);
    OCMVerify([mockSqlOperations insertIdentity:aliceIdentity]);
    OCMVerify([mockSqlOperations insertMechanism:mechanism]);
}

- (void)testBroadcastsOneChangeNotificationWhenIdentityObjectGraphIsSavedToDatabase {
    // Given
    FRAPushMechanism *mechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    [aliceIdentity addMechanism:mechanism];
    FRANotification *notification = [[FRANotification alloc] initWithDatabase:database];
    [mechanism addNotification:notification];
    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    NSDictionary *expectedChanges = @{
            @"added" : [NSSet setWithObjects:notification, mechanism, aliceIdentity, nil],
            @"removed" : [NSSet set],
            @"updated" : [NSSet set]
    };
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:expectedChanges];
    
    // When
    [identityModel addIdentity:aliceIdentity];
    
    // Then
    XCTAssertTrue([notification isStored]);
    XCTAssertTrue([mechanism isStored]);
    XCTAssertTrue([aliceIdentity isStored]);
    OCMVerifyAll(databaseObserverMock);
}

- (void)testBroadcastsOneChangeNotificationWhenIdentityObjectGraphIsRemovedFromDatabase {
    // Given
    FRAPushMechanism *mechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    [aliceIdentity addMechanism:mechanism];
    FRANotification *notification = [[FRANotification alloc] initWithDatabase:database];
    [mechanism addNotification:notification];
    [identityModel addIdentity:aliceIdentity];
    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    NSDictionary *expectedChanges = @{
            @"added" : [NSSet set],
            @"removed" : [NSSet setWithObjects:notification, mechanism, aliceIdentity, nil],
            @"updated" : [NSSet set]
    };
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:expectedChanges];
    
    // When
    [identityModel removeIdentity:aliceIdentity];
    
    // Then
    XCTAssertFalse([notification isStored]);
    XCTAssertFalse([mechanism isStored]);
    XCTAssertFalse([aliceIdentity isStored]);
    OCMVerifyAll(databaseObserverMock);
}

- (void)testCanFindMechanismById {
    // Given
    [identityModel addIdentity:aliceIdentity];
    FRAPushMechanism *mechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    [aliceIdentity addMechanism:mechanism];
    XCTAssertEqual(mechanism.uid, 0);
    
    // When
    FRAMechanism *foundMechanism = [identityModel mechanismWithId:mechanism.uid];
    
    // Then
    XCTAssertEqual(mechanism, foundMechanism);
}

@end
