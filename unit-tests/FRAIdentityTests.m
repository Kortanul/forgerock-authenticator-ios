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
#import "FRAMechanism.h"
#import "FRAOathMechanism.h"
#import "FRAPushMechanism.h"

@interface FRAIdentityTests : XCTestCase

@end

@implementation FRAIdentityTests {
    id mockSqlOperations;
    id databaseObserverMock;
    FRAIdentityDatabase *database;
    FRAIdentity* identity;
    NSString* issuer;
    NSString* accountName;
    NSURL* image;
}

- (void)setUp {
    [super setUp];
    mockSqlOperations = OCMClassMock([FRAIdentityDatabaseSQLiteOperations class]);
    database = [[FRAIdentityDatabase alloc] initWithSqlOperations:mockSqlOperations];
    issuer = @"ForgeRock";
    accountName = @"joe.bloggs";
    image = [NSURL URLWithString:@"https://forgerock.org/ico/favicon-32x32.png"];
    identity = [FRAIdentity identityWithDatabase:database accountName:accountName issuer:issuer image:image backgroundColor:nil];
    databaseObserverMock = OCMObserverMock();
}

- (void)tearDown {
    [mockSqlOperations stopMocking];
    [super tearDown];
}

- (void)testCanInitIdentityWithLabelIssuerImage {
    XCTAssertEqualObjects(identity.issuer, issuer);
    XCTAssertEqualObjects(identity.accountName, accountName);
    XCTAssertEqualObjects([identity.image absoluteString], [image description]);
}

- (void)testCanAddMechanism {
    // Given
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    
    // When
    BOOL mechanismAdded = [identity addMechanism:pushMechanism error:nil];
    
    // Then
    XCTAssertTrue(mechanismAdded);
    XCTAssertEqual(pushMechanism.parent, identity);
    XCTAssertTrue([[identity mechanisms] containsObject:pushMechanism]);
}

- (void)testSavedIdentityAutomaticallySavesAddedMechanismToDatabase {
    // Given
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertIdentity:identity error:nil]).andReturn(YES);
    [database insertIdentity:identity error:nil];
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:pushMechanism error:nil]).andReturn(YES);
    
    // When
    BOOL mechanismAdded = [identity addMechanism:pushMechanism error:nil];
    
    // Then
    XCTAssertTrue(mechanismAdded);
    XCTAssertTrue([pushMechanism isStored]);
    OCMVerify([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:pushMechanism error:nil]);
}

- (void)testBroadcastsOneChangeNotificationWhenMechanismIsAutomaticallySavedToDatabase {
    // Given
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertIdentity:identity error:nil]).andReturn(YES);
    [database insertIdentity:identity error:nil];
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:[OCMArg any]];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:pushMechanism error:nil]).andReturn(YES);
    
    // When
    BOOL mechanismAdded = [identity addMechanism:pushMechanism error:nil];
    
    // Then
    XCTAssertTrue(mechanismAdded);
    OCMVerifyAll(databaseObserverMock);
}

- (void)testCanRemoveMechanism {
    // Given
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:pushMechanism error:nil]).andReturn(YES);
    [identity addMechanism:pushMechanism error:nil];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations deleteMechanism:pushMechanism error:nil]).andReturn(YES);
    
    // When
    BOOL mechanismRemoved = [identity removeMechanism:pushMechanism error:nil];
    
    // Then
    XCTAssertTrue(mechanismRemoved);
    XCTAssertEqual(pushMechanism.parent, nil);
    XCTAssertFalse([[identity mechanisms] containsObject:pushMechanism]);
}

- (void)testSavedIdentityAutomaticallyRemovesMechanismFromDatabase {
    // Given
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertIdentity:identity error:nil]).andReturn(YES);
    [database insertIdentity:identity error:nil];
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:pushMechanism error:nil]).andReturn(YES);
    [identity addMechanism:pushMechanism error:nil];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations deleteMechanism:pushMechanism error:nil]).andReturn(YES);
    
    // When
    BOOL mechanismRemoved = [identity removeMechanism:pushMechanism error:nil];
    
    // Then
    XCTAssertTrue(mechanismRemoved);
    XCTAssertFalse([pushMechanism isStored]);
    OCMVerify([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations deleteMechanism:pushMechanism error:nil]);
}

- (void)testBroadcastsOneChangeNotificationWhenMechanismIsAutomaticallyRemovedFromDatabase {
    // Given
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertIdentity:identity error:nil]).andReturn(YES);
    [database insertIdentity:identity error:nil];
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:pushMechanism error:nil]).andReturn(YES);
    [identity addMechanism:pushMechanism error:nil];
    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:[OCMArg any]];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations deleteMechanism:pushMechanism error:nil]).andReturn(YES);
    
    // When
    BOOL mechanismRemoved = [identity removeMechanism:pushMechanism error:nil];
    
    // Then
    XCTAssertTrue(mechanismRemoved);
    OCMVerifyAll(databaseObserverMock);
}

- (void)testCanQueryForMechanismByType {
    // Given
    FRAOathMechanism *oathMechanism = [[FRAOathMechanism alloc] initWithDatabase:database];
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:oathMechanism error:nil]).andReturn(YES);
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:pushMechanism error:nil]).andReturn(YES);
    
    // When
    BOOL oathMechanismAdded = [identity addMechanism:oathMechanism error:nil];
    BOOL pushMechanismAdded = [identity addMechanism:pushMechanism error:nil];
    
    // Then
    XCTAssertTrue(oathMechanismAdded);
    XCTAssertTrue(pushMechanismAdded);
    XCTAssertEqualObjects([identity mechanismOfClass:[FRAOathMechanism class]], oathMechanism);
    XCTAssertEqualObjects([identity mechanismOfClass:[FRAPushMechanism class]], pushMechanism);
}

@end
