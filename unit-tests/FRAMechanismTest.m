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

#import "FRAIdentityDatabase.h"
#import "FRAIdentityDatabaseSQLiteOperations.h"
#import "FRAMechanism.h"
#import "FRANotification.h"

@interface FRAMechanismTest : XCTestCase

@end

@implementation FRAMechanismTest {
    id mockSqlOperations;
    id databaseObserverMock;
    FRAIdentityDatabase *database;
    FRAMechanism *mechanism;
}

- (void)setUp {
    [super setUp];
    mockSqlOperations = OCMClassMock([FRAIdentityDatabaseSQLiteOperations class]);
    database = [[FRAIdentityDatabase alloc] initWithSqlOperations:mockSqlOperations];
    mechanism = [[FRAMechanism alloc] initWithDatabase:database];
    databaseObserverMock = OCMObserverMock();
}

- (void)tearDown {
    [mockSqlOperations stopMocking];
    [super tearDown];
}

- (void)testCanAddNotificationToMechanism {
    // Given
    FRANotification *notification = [self dummyNotification];
    
    // When
    BOOL notificationAdded = [mechanism addNotification:notification error:nil];
    
    // Then
    XCTAssertTrue(notificationAdded);
    XCTAssertEqual(notification.parent, mechanism);
    XCTAssertTrue([[mechanism notifications] containsObject:notification]);
}

- (void)testSavedMechanismAutomaticallySavesAddedNotificationToDatabase {
    // Given
    FRANotification *notification = [self dummyNotification];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:mechanism error:nil]).andReturn(YES);
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertNotification:notification error:nil]).andReturn(YES);
    XCTAssertTrue([database insertMechanism:mechanism error:nil]);

    // When
    BOOL notificationAdded = [mechanism addNotification:notification error:nil];
    
    // Then
    XCTAssertTrue(notificationAdded);
    XCTAssertTrue([notification isStored]);
}

- (void)testBroadcastsOneChangeNotificationWhenNotificationIsAutomaticallySavedToDatabase {
    // Given
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:mechanism error:nil]).andReturn(YES);
    [database insertMechanism:mechanism error:nil];
    FRANotification *notification = [self dummyNotification];
    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:[OCMArg any]];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertNotification:notification error:nil]).andReturn(YES);
    
    // When
    BOOL notificationAdded = [mechanism addNotification:notification error:nil];
    
    // Then
    XCTAssertTrue(notificationAdded);
    OCMVerifyAll(databaseObserverMock);
}

- (void)testCanRemoveNotificationFromMechanism {
    // Given
    FRANotification *notification = [self dummyNotification];

    [mechanism addNotification:notification error:nil];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations deleteNotification:notification error:nil]).andReturn(YES);
    
    // When
    BOOL notificationRemoved = [mechanism removeNotification:notification error:nil];
    
    // Then
    XCTAssertTrue(notificationRemoved);
    XCTAssertEqual(notification.parent, nil);
    XCTAssertFalse([[mechanism notifications] containsObject:notification]);
}

- (void)testSavedMechanismAutomaticallyRemovesNotificationFromDatabase {
    // Given
    FRANotification *notification = [self dummyNotification];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:mechanism error:nil]).andReturn(YES);
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertNotification:notification error:nil]).andReturn(YES);
    XCTAssertTrue([database insertMechanism:mechanism error:nil]);

    XCTAssertTrue([mechanism addNotification:notification error:nil]);
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations deleteNotification:notification error:nil]).andReturn(YES);
    
    // When
    BOOL notificationRemoved = [mechanism removeNotification:notification error:nil];
    
    // Then
    XCTAssertTrue(notificationRemoved);
    XCTAssertFalse([notification isStored]);
}

- (void)testBroadcastsOneChangeNotificationWhenMechanismIsAutomaticallyRemovedFromDatabase {
    // Given
    FRANotification *notification = [self dummyNotification];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertMechanism:mechanism error:nil]).andReturn(YES);
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertNotification:notification error:nil]).andReturn(YES);
    [database insertMechanism:mechanism error:nil];

    [mechanism addNotification:notification error:nil];
    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:[OCMArg any]];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations deleteNotification:notification error:nil]).andReturn(YES);
    
    // When
    BOOL notificationRemoved = [mechanism removeNotification:notification error:nil];
    
    // Then
    XCTAssertTrue(notificationRemoved);
    OCMVerifyAll(databaseObserverMock);
}

- (void)testCanLocateChildNotificationByMessageId {
    // Given
    [mechanism addNotification:[self dummyNotificationWithMessageId:@"ID-1"] error:nil];
    [mechanism addNotification:[self dummyNotificationWithMessageId:@"ID-2"] error:nil];
    [mechanism addNotification:[self dummyNotificationWithMessageId:@"ID-3"] error:nil];

    // When

    // Then
    XCTAssertEqual([mechanism notificationWithMessageId:@"ID-1"].messageId, @"ID-1", @"Should find child notification by message ID");
    XCTAssertEqual([mechanism notificationWithMessageId:@"ID-2"].messageId, @"ID-2", @"Should find child notification by message ID");
    XCTAssertEqual([mechanism notificationWithMessageId:@"ID-3"].messageId, @"ID-3", @"Should find child notification by message ID");
}


- (FRANotification *)dummyNotification {
    return [self dummyNotificationWithMessageId:@"messageId"];
}

- (FRANotification *)dummyNotificationWithMessageId:(NSString *)messageId {
    return [[FRANotification alloc] initWithDatabase:database
                                           messageId:messageId
                                           challenge:@"Challenge"
                                        timeReceived:[NSDate date]
                                          timeToLive:120.0];
}

@end
