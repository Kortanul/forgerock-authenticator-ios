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
#import "FRAOathMechanism.h"
#import "FRAPushMechanism.h"

@interface FRAIdentityTests : XCTestCase

@end

@implementation FRAIdentityTests {
    id mockSqlOperations;
    id databaseObserverMock;
    FRAIdentityDatabase *database;
    FRAIdentity *identity;
    FRAIdentityModel *identityModel;
    NSString *issuer;
    NSString *accountName;
    NSURL *image;
}

- (void)setUp {
    [super setUp];
    mockSqlOperations = OCMClassMock([FRAIdentityDatabaseSQLiteOperations class]);
    database = [[FRAIdentityDatabase alloc] initWithSqlOperations:mockSqlOperations];
    issuer = @"ForgeRock";
    accountName = @"joe.bloggs";
    image = [NSURL URLWithString:@"https://forgerock.org/ico/favicon-32x32.png"];
    identityModel = [[FRAIdentityModel alloc] initWithDatabase:database sqlDatabase:nil];
    identity = [FRAIdentity identityWithDatabase:database identityModel:identityModel accountName:accountName issuer:issuer image:image backgroundColor:nil];
    [identityModel addIdentity:identity error:nil];
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

- (void)testCanGetIdentityModel {
    
    FRAIdentityModel *model = identity.identityModel;
    
    XCTAssertEqual(model, identityModel);
}

- (void)testCanAddMechanism {
    // Given
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database identityModel:identityModel];
    
    // When
    BOOL mechanismAdded = [identity addMechanism:pushMechanism error:nil];
    
    // Then
    XCTAssertTrue(mechanismAdded);
    XCTAssertEqual(pushMechanism.parent, identity);
    XCTAssertTrue([[identity mechanisms] containsObject:pushMechanism]);
}

- (void)testSavedIdentityAutomaticallySavesAddedMechanismToDatabase {
    // Given
    OCMStub([mockSqlOperations insertIdentity:identity error:nil]).andReturn(YES);
    [database insertIdentity:identity error:nil];
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database identityModel:identityModel];
    OCMStub([mockSqlOperations insertMechanism:pushMechanism error:nil]).andReturn(YES);
    
    // When
    BOOL mechanismAdded = [identity addMechanism:pushMechanism error:nil];
    
    // Then
    XCTAssertTrue(mechanismAdded);
    XCTAssertTrue([pushMechanism isStored]);
    OCMVerify([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:pushMechanism error:nil]);
}

- (void)testBroadcastsOneChangeNotificationWhenMechanismIsAutomaticallySavedToDatabase {
    // Given
    OCMStub([mockSqlOperations insertIdentity:identity error:nil]).andReturn(YES);
    [database insertIdentity:identity error:nil];
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database identityModel:identityModel];
    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:[OCMArg any]];
    OCMStub([mockSqlOperations insertMechanism:pushMechanism error:nil]).andReturn(YES);
    
    // When
    BOOL mechanismAdded = [identity addMechanism:pushMechanism error:nil];
    
    // Then
    XCTAssertTrue(mechanismAdded);
    OCMVerifyAll(databaseObserverMock);
}

- (void)testCanRemoveMechanism {
    // Given
    OCMStub([mockSqlOperations insertIdentity:identity error:nil]).andReturn(YES);
    [database insertIdentity:identity error:nil];
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database identityModel:identityModel];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:pushMechanism error:nil]).andReturn(YES);
    [identity addMechanism:pushMechanism error:nil];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations deleteMechanism:pushMechanism error:nil]).andReturn(YES);
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations deleteIdentity:identity error:nil]).andReturn(YES);
    
    // When
    BOOL mechanismRemoved = [identity removeMechanism:pushMechanism error:nil];
    
    // Then
    XCTAssertTrue(mechanismRemoved);
    XCTAssertEqual(pushMechanism.parent, nil);
    XCTAssertFalse([[identity mechanisms] containsObject:pushMechanism]);
}

- (void)testSavedIdentityAutomaticallyRemovesMechanismFromDatabase {
    // Given
    OCMStub([mockSqlOperations insertIdentity:identity error:nil]).andReturn(YES);
    [database insertIdentity:identity error:nil];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertIdentity:identity error:nil]).andReturn(YES);
    [database insertIdentity:identity error:nil];
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database identityModel:identityModel];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:pushMechanism error:nil]).andReturn(YES);
    [identity addMechanism:pushMechanism error:nil];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations deleteMechanism:pushMechanism error:nil]).andReturn(YES);
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations deleteIdentity:identity error:nil]).andReturn(YES);
    
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
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database identityModel:identityModel];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:pushMechanism error:nil]).andReturn(YES);
    [identity addMechanism:pushMechanism error:nil];
    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:[OCMArg any]];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations deleteMechanism:pushMechanism error:nil]).andReturn(YES);
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations deleteIdentity:identity error:nil]).andReturn(YES);
    
    // When
    BOOL mechanismRemoved = [identity removeMechanism:pushMechanism error:nil];
    
    // Then
    XCTAssertTrue(mechanismRemoved);
    OCMVerifyAll(databaseObserverMock);
}

- (void)testRemoveMechanisRemovesIdentityFromIdentityModelIfLastMechanism {
    // Given
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database identityModel:identityModel];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:pushMechanism error:nil]).andReturn(YES);
    [identity addMechanism:pushMechanism error:nil];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations deleteMechanism:pushMechanism error:nil]).andReturn(YES);
    
    // When
    [identity removeMechanism:pushMechanism error:nil];
    
    // Then
    XCTAssertEqual(identityModel.identities.count, 0);
}

- (void)testRemoveNonExistingMechanismFromIdentity {
    // Given
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertIdentity:identity error:nil]).andReturn(YES);
    [database insertIdentity:identity error:nil];
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database identityModel:identityModel];
    [pushMechanism setValue:[NSNumber numberWithBool:YES] forKey:@"stored"];
    OCMReject([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations deleteMechanism:pushMechanism error:[OCMArg anyObjectRef]]);
    NSError *error;
    
    // When
    BOOL mechanismRemoved = [identity removeMechanism:pushMechanism error:&error];
    
    // Then
    XCTAssertFalse(mechanismRemoved);
    XCTAssertNotNil(error);
    // TODO: Check the error code
    // XCTAssertEqual(error.code, FRAInvalidOperation);
}

- (void)testCanQueryForMechanismByType {
    // Given
    FRAOathMechanism *oathMechanism = [[FRAOathMechanism alloc] initWithDatabase:database identityModel:identityModel];
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database identityModel:identityModel];
    OCMStub([mockSqlOperations insertMechanism:oathMechanism error:nil]).andReturn(YES);
    OCMStub([mockSqlOperations insertMechanism:pushMechanism error:nil]).andReturn(YES);
    
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
