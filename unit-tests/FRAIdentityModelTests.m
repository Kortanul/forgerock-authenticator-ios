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
#import "FRASqlDatabase.h"

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
    mockSqlDatabase = OCMClassMock([FRASqlDatabase class]);
    database = [[FRAIdentityDatabase alloc] initWithSqlOperations:mockSqlOperations];
    identityModel = [[FRAIdentityModel alloc] initWithDatabase:database andSqlDatabase:mockSqlDatabase];
    aliceIdentity = [FRAIdentity identityWithDatabase:database accountName:@"alice" issuer:@"Forgerock" image:nil backgroundColor:nil];
    bobIdentity = [FRAIdentity identityWithDatabase:database accountName:@"bob" issuer:@"Forgerock" image:nil backgroundColor:nil];
    databaseObserverMock = OCMObserverMock();
}

- (void)tearDown {
    [mockSqlOperations stopMocking];
    [mockSqlDatabase stopMocking];
    [super tearDown];
}

- (void)testCanSaveNewIdentityToDatabase {
    // Given
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertIdentity:aliceIdentity withError:nil]).andReturn(YES);
    XCTAssertEqualObjects([identityModel identities], @[]);
    
    // When
    BOOL aliceAdded = [identityModel addIdentity:aliceIdentity withError:nil];
    
    // Then
    XCTAssertTrue(aliceAdded);
    XCTAssertTrue([aliceIdentity isStored]);
    XCTAssertTrue([[identityModel identities] containsObject:aliceIdentity]);
    OCMVerify([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertIdentity:aliceIdentity withError:nil]);
}

- (void)testBroadcastsOneChangeNotificationWhenIdentityIsSavedToDatabase {
    // Given
    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertIdentity:aliceIdentity withError:nil]).andReturn(YES);
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:[OCMArg any]];
    
    // When
    BOOL aliceAdded = [identityModel addIdentity:aliceIdentity withError:nil];
    
    // Then
    XCTAssertTrue(aliceAdded);
    OCMVerifyAll(databaseObserverMock);
}

- (void)testSavedIdentitiesAreGivenUniqueStorageIds {
    // Given
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertIdentity:aliceIdentity withError:nil]).andReturn(YES);
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertIdentity:bobIdentity withError:nil]).andReturn(YES);
    
    // When
    BOOL aliceAdded = [identityModel addIdentity:aliceIdentity withError:nil];
    BOOL bobAdded = [identityModel addIdentity:bobIdentity withError:nil];
    
    // Then
    XCTAssertTrue(aliceAdded);
    XCTAssertTrue(bobAdded);
    XCTAssertTrue([aliceIdentity isStored]);
    XCTAssertTrue([bobIdentity isStored]);
    XCTAssertNotEqual(aliceIdentity.uid, bobIdentity.uid);
}

- (void)testCanFindIdentityById {
    // Given
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertIdentity:aliceIdentity withError:nil]).andReturn(YES);
    [identityModel addIdentity:aliceIdentity withError:nil];
    
    // When
    FRAIdentity* foundIdentity = [identityModel identityWithId:aliceIdentity.uid];
    
    // Then
    XCTAssertEqual(aliceIdentity, foundIdentity);
}

- (void)testCanFindIdentityByIssuerAndLabel {
    // Given
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertIdentity:aliceIdentity withError:nil]).andReturn(YES);
    [identityModel addIdentity:aliceIdentity withError:nil];
    
    // When
    FRAIdentity* foundIdentity = [identityModel identityWithIssuer:aliceIdentity.issuer accountName:aliceIdentity.accountName];
    
    // Then
    XCTAssertEqual(aliceIdentity, foundIdentity);
}

- (void)testCanRemoveIdentityFromDatabase {
    // Given
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertIdentity:aliceIdentity withError:nil]).andReturn(YES);
    [identityModel addIdentity:aliceIdentity withError:nil];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations deleteIdentity:aliceIdentity withError:nil]).andReturn(YES);
    
    // When
    BOOL aliceRemoved = [identityModel removeIdentity:aliceIdentity withError:nil];
    
    // Then
    XCTAssertTrue(aliceRemoved);
    XCTAssertFalse([aliceIdentity isStored]);
    XCTAssertFalse([[identityModel identities] containsObject:aliceIdentity]);
}

- (void)testBroadcastsOneChangeNotificationWhenIdentityIsRemovedFromDatabase {
    // Given
    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertIdentity:aliceIdentity withError:nil]).andReturn(YES);
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:[OCMArg any]];
    [identityModel addIdentity:aliceIdentity withError:nil];
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:[OCMArg any]];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations deleteIdentity:aliceIdentity withError:nil]).andReturn(YES);
    
    // When
    BOOL aliceRemoved = [identityModel removeIdentity:aliceIdentity withError:nil];
    
    // Then
    XCTAssertTrue(aliceRemoved);
    OCMVerifyAll(databaseObserverMock);
}

- (void)testCanSaveMechanismsOfNewIdentityToDatabase {
    // Given
    FRAPushMechanism *mechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:mechanism withError:nil]).andReturn(YES);
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertIdentity:aliceIdentity withError:nil]).andReturn(YES);
    [aliceIdentity addMechanism:mechanism withError:nil];
    XCTAssertFalse([mechanism isStored]);
    
    // When
    BOOL aliceAdded = [identityModel addIdentity:aliceIdentity withError:nil];
    
    // Then
    XCTAssertTrue(aliceAdded);
    XCTAssertTrue([mechanism isStored]);
    XCTAssertTrue([aliceIdentity isStored]);
    OCMVerify([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertIdentity:aliceIdentity withError:nil]);
    OCMVerify([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:mechanism withError:nil]);
}

- (void)testBroadcastsOneChangeNotificationWhenIdentityObjectGraphIsSavedToDatabase {
    // Given
    FRAPushMechanism *mechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    [aliceIdentity addMechanism:mechanism withError:nil];
    NSTimeInterval timeToLive = 120.0;
    FRANotification *notification = [[FRANotification alloc] initWithDatabase:database messageId:@"messageId" challenge:[@"challange" dataUsingEncoding:NSUTF8StringEncoding] timeReceived:[NSDate date] timeToLive:timeToLive];

    [mechanism addNotification:notification withError:nil];

    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    NSDictionary *expectedChanges = @{
            @"added" : [NSSet setWithObjects:notification, mechanism, aliceIdentity, nil],
            @"removed" : [NSSet set],
            @"updated" : [NSSet set]
    };
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertNotification:notification withError:nil]).andReturn(YES);
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:mechanism withError:nil]).andReturn(YES);
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertIdentity:aliceIdentity withError:nil]).andReturn(YES);
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:expectedChanges];
    
    // When
    BOOL aliceAdded = [identityModel addIdentity:aliceIdentity withError:nil];
    
    // Then
    XCTAssertTrue(aliceAdded);
    XCTAssertTrue([notification isStored]);
    XCTAssertTrue([mechanism isStored]);
    XCTAssertTrue([aliceIdentity isStored]);
    OCMVerifyAll(databaseObserverMock);
}

- (void)testBroadcastsOneChangeNotificationWhenIdentityObjectGraphIsRemovedFromDatabase {
    // Given
    FRAPushMechanism *mechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    [aliceIdentity addMechanism:mechanism withError:nil];
    NSTimeInterval timeToLive = 120.0;
    FRANotification *notification = [[FRANotification alloc] initWithDatabase:database messageId:@"messageId" challenge:[@"challange" dataUsingEncoding:NSUTF8StringEncoding] timeReceived:[NSDate date] timeToLive:timeToLive];
    [mechanism addNotification:notification withError:nil];

    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertIdentity:aliceIdentity withError:nil]).andReturn(YES);
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertNotification:notification withError:nil]).andReturn(YES);
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:mechanism withError:nil]).andReturn(YES);

    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:[OCMArg any]];
    [identityModel addIdentity:aliceIdentity withError:nil];
    
    NSDictionary *expectedChanges = @{
            @"added" : [NSSet set],
            @"removed" : [NSSet setWithObjects:notification, mechanism, aliceIdentity, nil],
            @"updated" : [NSSet set]
    };
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations deleteIdentity:aliceIdentity withError:nil]).andReturn(YES);
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations deleteNotification:notification withError:nil]).andReturn(YES);
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations deleteMechanism:mechanism withError:nil]).andReturn(YES);
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:expectedChanges];
    
    // When
    BOOL aliceRemoved = [identityModel removeIdentity:aliceIdentity withError:nil];
    
    // Then
    XCTAssertTrue(aliceRemoved);
    XCTAssertFalse([notification isStored]);
    XCTAssertFalse([mechanism isStored]);
    XCTAssertFalse([aliceIdentity isStored]);
    OCMVerifyAll(databaseObserverMock);
}

- (void)testCanFindMechanismById {
    // Given
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertIdentity:aliceIdentity withError:nil]).andReturn(YES);
    [identityModel addIdentity:aliceIdentity withError:nil];
    FRAPushMechanism *mechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:mechanism withError:nil]).andReturn(YES);
    [aliceIdentity addMechanism:mechanism withError:nil];
    XCTAssertEqual(mechanism.uid, 0);
    
    // When
    FRAMechanism *foundMechanism = [identityModel mechanismWithId:mechanism.uid];
    
    // Then
    XCTAssertEqual(mechanism, foundMechanism);
}

@end
