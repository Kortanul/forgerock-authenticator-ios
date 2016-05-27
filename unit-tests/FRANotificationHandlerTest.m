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
#import "FRAModelObjectProtected.h"
#import "FRANotification.h"
#import "FRANotificationHandler.h"
#import "FRAOathMechanism.h"
#import "FRAPushMechanism.h"
#import "FRAFMDatabaseConnectionHelper.h"

@interface FRANotificationHandlerTest : XCTestCase

@end

static NSString *const TEST_USERNAME = @"Alice";
static NSString *const CHALLENGE = @"thelegendofluna";

@implementation FRANotificationHandlerTest {
    FRANotificationHandler *handler;
    FRAIdentityDatabase *database;
    FRAIdentityModel *identityModel;
    FRAIdentity *identity;
    FRAPushMechanism *pushMechanism;
    FRAOathMechanism *oathMechanism;
    UIApplication *mockApplication;
    FRASqlDatabase* mockSqlDatabase;
    id mockDatabaseOperations;
}

- (void)setUp {
    [super setUp];
    
    mockApplication = OCMClassMock([UIApplication class]);
    mockDatabaseOperations = OCMClassMock([FRAIdentityDatabaseSQLiteOperations class]);
    database = [[FRAIdentityDatabase alloc] initWithSqlOperations:mockDatabaseOperations];
    
    // create object model
    identityModel = [[FRAIdentityModel alloc] initWithDatabase:database sqlDatabase:mockSqlDatabase];
    identity = [FRAIdentity identityWithDatabase:database accountName:TEST_USERNAME issuer:@"ForgeRock" image:nil backgroundColor:nil];
    
    pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    [pushMechanism setValue:@"0" forKey:@"mechanismUID"];

    oathMechanism = [[FRAOathMechanism alloc] initWithDatabase:database];
    [identityModel addIdentity:identity error:nil];
    [identity addMechanism:pushMechanism error:nil];
    [identity addMechanism:oathMechanism error:nil];
    
    // persist to object model database
    [database insertIdentity:identity error:nil];

    handler = [[FRANotificationHandler alloc] initWithDatabase:database identityModel:identityModel];
}

- (void)tearDown {
    [mockDatabaseOperations stopMocking];
    [super tearDown];
}

- (void)testCreatesNotificationObjectFromMessageAndSavesToIdentifiedPushMechanism {
    // Given
    NSDictionary *data = @{@"aps":@{@"messageId":@"123", @"data":@"eyAidHlwIjogIkpXVCIsICJhbGciOiAiSFMyNTYiIH0.ew0KICAgICJjIjoiZEdobGJHVm5aVzVrYjJac2RXNWgiLA0KICAgICJsIjoiWVcxc1ltTnZiMnRwWlQxaGJXeGlZMjl2YTJsbFBUQXgiLA0KICAgICJ0IiA6IjEyMCIsDQogICAgInUiOiIwIg0KfQ==.1SAWJlT-5vjYRbpZ_57K-NpFRs4VZbSzZjAF_3RTu7k"}};
    // When
    [handler application:mockApplication didReceiveRemoteNotification:data];
    
    // Then
    FRANotification *notification = [pushMechanism notificationWithMessageId:@"123"];
    XCTAssertNotNil(notification, @"Mechanism did not contain expected Notification");
    XCTAssertEqualObjects(notification.database, database, @"Notification not initialized with database");
    XCTAssertEqualObjects(notification.messageId, @"123", @"Notification not initialized with messageId");
    XCTAssertEqualObjects(notification.challenge, CHALLENGE, @"Notification not initialized with challenge");
    XCTAssertNotNil(notification.timeReceived, @"Notification not initialized with timeReceived");
    XCTAssertEqual(notification.timeToLive, 120, @"Notification not initialized with time to live");
}

- (void)testNotificationHandlingShouldBeIdempotent {
    // Given
    NSDictionary *data = @{@"aps":@{@"messageId":@"123", @"data":@"eyAidHlwIjogIkpXVCIsICJhbGciOiAiSFMyNTYiIH0.ew0KICAgICJjIjoiZEdobGJHVm5aVzVrYjJac2RXNWgiLA0KICAgICJsIjoiWVcxc1ltTnZiMnRwWlQxaGJXeGlZMjl2YTJsbFBUQXgiLA0KICAgICJ0IiA6IjEyMCIsDQogICAgInUiOiIwIg0KfQ==.1SAWJlT-5vjYRbpZ_57K-NpFRs4VZbSzZjAF_3RTu7k"}};
    
    // When
    [handler application:mockApplication didReceiveRemoteNotification:data];
    [handler application:mockApplication didReceiveRemoteNotification:data];
    
    // Then
    XCTAssertEqual([pushMechanism notifications].count, 1, @"Notification handling should be idempotent");
}

- (void)testOnlyHandlesNotificationsThatReferToPushMechanism {
    // Given
    NSDictionary *data = @{@"aps":@{@"messageId":@"123", @"data":@"eyAidHlwIjogIkpXVCIsICJhbGciOiAiSFMyNTYiIH0.ew0KICAgICJjIjoiZEdobGJHVm5aVzVrYjJac2RXNWgiLA0KICAgICJsIjoiWVcxc1ltTnZiMnRwWlQxaGJXeGlZMjl2YTJsbFBUQXgiLA0KICAgICJ0IiA6IjEyMCIsDQogICAgInUiOiIwIg0KfQ==.1SAWJlT-5vjYRbpZ_57K-NpFRs4VZbSzZjAF_3RTu7k"}};
    
    // When
    [handler application:mockApplication didReceiveRemoteNotification:data];
    
    // Then
    XCTAssertEqual([oathMechanism notifications].count, 0, @"Only Push-Mechanism notifications should be handled");
    XCTAssertEqual([pushMechanism notifications].count, 1, @"Only Push-Mechanism notifications should be handled");
}

@end
