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

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "FRAIdentityDatabase.h"
#import "FRAIdentityDatabaseSQLiteOperations.h"
#import "FRANotification.h"

@interface FRANotificationTest : XCTestCase

@end

@implementation FRANotificationTest {

    FRAIdentityDatabaseSQLiteOperations *mockSqlOperations;
    FRAIdentityDatabase *database;
    FRANotification* notification;
    id databaseObserverMock;

}

- (void)setUp {
    [super setUp];
    mockSqlOperations = OCMClassMock([FRAIdentityDatabaseSQLiteOperations class]);
    database = [[FRAIdentityDatabase alloc] initWithSqlOperations:mockSqlOperations];
    NSTimeInterval timeToLive = 120.0;
    notification = [[FRANotification alloc] initWithDatabase:database messageId:@"messageId" challenge:@"challenge" timeReceived:[NSDate date] timeToLive:timeToLive];
    databaseObserverMock = OCMObserverMock();
}

- (void)tearDown {
    [super tearDown];
}

- (void)testInitialStateOfNotification {
    // Given
    
    // When
    
    // Then
    XCTAssertEqual([notification isPending], YES);
    XCTAssertEqual([notification isApproved], NO);
}

- (void)testShouldApproveNotification {
    // Given
    
    // When
    [notification approve];
    
    // Then
    XCTAssertEqual([notification isPending], NO);
    XCTAssertEqual([notification isApproved], YES);
}

- (void)testShouldDenyNotification {
    // Given
    
    // When
    [notification deny];
    
    // Then
    XCTAssertEqual([notification isPending], NO);
    XCTAssertEqual([notification isApproved], NO);
}

- (void)testSavedNotificationAutomaticallySavesItselfToDatabaseWhenApproved {
    // Given
    [database insertNotification:notification];
    
    // When
    [notification approve];
    
    // Then
    OCMVerify([mockSqlOperations updateNotification:notification]);
}

- (void)testSavedNotificationAutomaticallySavesItselfToDatabaseWhenDenied {
    // Given
    [database insertNotification:notification];
    
    // When
    [notification deny];
    
    // Then
    OCMVerify([mockSqlOperations updateNotification:notification]);
}

- (void)testBroadcastsOneChangeNotificationWhenNotificationUpdateIsAutomaticallySavedToDatabase {
    // Given
    [database insertNotification:notification];
    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:[OCMArg any]];
    
    // When
    [notification approve];
    
    // Then
    OCMVerifyAll(databaseObserverMock);
}

@end

