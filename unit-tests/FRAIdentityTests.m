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

    FRAIdentityDatabaseSQLiteOperations *mockSqlOperations;
    FRAIdentityDatabase *database;
    FRAIdentity* identity;
    NSString* issuer;
    NSString* accountName;
    NSURL* image;
    id databaseObserverMock;

}

- (void)setUp {
    [super setUp];
    mockSqlOperations = OCMClassMock([FRAIdentityDatabaseSQLiteOperations class]);
    database = [[FRAIdentityDatabase alloc] initWithSqlOperations:mockSqlOperations];
    issuer = @"ForgeRock";
    accountName = @"joe.bloggs";
    image = [NSURL URLWithString:@"https://forgerock.org/ico/favicon-32x32.png"];
    identity = [FRAIdentity identityWithDatabase:database accountName:accountName issuer:issuer image:image];
    databaseObserverMock = OCMObserverMock();
}

- (void)tearDown {
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
    [identity addMechanism:pushMechanism];
    
    // Then
    XCTAssertEqual(pushMechanism.parent, identity);
    XCTAssertTrue([[identity mechanisms] containsObject:pushMechanism]);
}

- (void)testSavedIdentityAutomaticallySavesAddedMechanismToDatabase {
    // Given
    [database insertIdentity:identity];
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    
    // When
    [identity addMechanism:pushMechanism];
    
    // Then
    XCTAssertTrue([pushMechanism isStored]);
    OCMVerify([mockSqlOperations insertMechanism:pushMechanism]);
}

- (void)testBroadcastsOneChangeNotificationWhenMechanismIsAutomaticallySavedToDatabase {
    // Given
    [database insertIdentity:identity];
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:[OCMArg any]];
    
    // When
    [identity addMechanism:pushMechanism];
    
    // Then
    OCMVerifyAll(databaseObserverMock);
}

- (void)testCanRemoveMechanism {
    // Given
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    [identity addMechanism:pushMechanism];
    
    // When
    [identity removeMechanism:pushMechanism];
    
    // Then
    XCTAssertEqual(pushMechanism.parent, nil);
    XCTAssertFalse([[identity mechanisms] containsObject:pushMechanism]);
}

- (void)testSavedIdentityAutomaticallyRemovesMechanismFromDatabase {
    // Given
    [database insertIdentity:identity];
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    [identity addMechanism:pushMechanism];
    
    // When
    [identity removeMechanism:pushMechanism];
    
    // Then
    XCTAssertFalse([pushMechanism isStored]);
    OCMVerify([mockSqlOperations deleteMechanism:pushMechanism]);
}

- (void)testBroadcastsOneChangeNotificationWhenMechanismIsAutomaticallyRemovedFromDatabase {
    // Given
    [database insertIdentity:identity];
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    [identity addMechanism:pushMechanism];
    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:[OCMArg any]];
    
    // When
    [identity removeMechanism:pushMechanism];
    
    // Then
    OCMVerifyAll(databaseObserverMock);
}

- (void)testCanQueryForMechanismByType {
    // Given
    FRAOathMechanism *oathMechanism = [[FRAOathMechanism alloc] initWithDatabase:database];
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    
    // When
    [identity addMechanism:oathMechanism];
    [identity addMechanism:pushMechanism];
    
    // Then
    XCTAssertEqualObjects([identity mechanismOfClass:[FRAOathMechanism class]], oathMechanism);
    XCTAssertEqualObjects([identity mechanismOfClass:[FRAPushMechanism class]], pushMechanism);
}

@end
