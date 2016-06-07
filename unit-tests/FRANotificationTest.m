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
#import "FRAIdentityModel.h"
#import "FRAMessageUtils.h"
#import "FRANotification.h"
#import "FRAPushMechanism.h"

@interface FRANotificationTest : XCTestCase

@end

@implementation FRANotificationTest {
    id mockSqlOperations;
    id mockIdentityModel;
    id databaseObserverMock;
    FRAIdentityDatabase *database;
    FRANotification* notification;
    id messageUtilsMock;
    FRAPushMechanism *mechanism;
}

- (void)setUp {
    [super setUp];
    
    mockSqlOperations = OCMClassMock([FRAIdentityDatabaseSQLiteOperations class]);
    mockIdentityModel = OCMClassMock([FRAIdentityModel class]);
    database = [[FRAIdentityDatabase alloc] initWithSqlOperations:mockSqlOperations];
    NSTimeInterval timeToLive = 120.0;
    mechanism = [[FRAPushMechanism alloc] initWithDatabase:database identityModel:mockIdentityModel authEndpoint:@"http://service.endpoint" secret:@"secret"];
    notification = [[FRANotification alloc] initWithDatabase:database identityModel:mockIdentityModel messageId:@"messageId" challenge:@"challenge" timeReceived:[NSDate date] timeToLive:timeToLive loadBalancerCookieData:@"amlbcookie=03"];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations *)mockSqlOperations insertNotification:notification error:nil]).andReturn(YES);
    OCMStub([(FRAIdentityDatabaseSQLiteOperations *)mockSqlOperations updateNotification:notification error:nil]).andReturn(YES);
    databaseObserverMock = OCMObserverMock();
    messageUtilsMock = OCMClassMock([FRAMessageUtils class]);
    [notification setParent:mechanism];
}

- (void)tearDown {
    [mockSqlOperations stopMocking];
    [messageUtilsMock stopMocking];
    [super tearDown];
}

- (void)testInitialStateOfNotification {
    // Given
    
    // When
    
    // Then
    XCTAssertEqual([notification isPending], YES);
    XCTAssertEqual([notification isApproved], NO);
    XCTAssertEqual([notification isDenied], NO);
    XCTAssertEqual([notification isExpired], NO);
}

- (void)testShouldSetTimeExpired {
    // Given
    NSDate *timeReceived = [NSDate date];
    NSTimeInterval timeToLive = 120.0;
    FRANotification *expiringNotification = [[FRANotification alloc] initWithDatabase:database identityModel:mockIdentityModel messageId:@"messageId" challenge:@"challenge" timeReceived:timeReceived timeToLive:timeToLive loadBalancerCookieData:@"amlbcookie=03"];

    // When
    
    // Then
    XCTAssertEqualObjects([expiringNotification timeExpired], [timeReceived dateByAddingTimeInterval:timeToLive]);
}

- (void)testShouldApproveNotification {
    // Given
    
    // When
    [notification approveWithError:nil];
    
    // Then
    XCTAssertEqual([notification isPending], NO);
    XCTAssertEqual([notification isApproved], YES);
    XCTAssertEqual([notification isDenied], NO);
}

- (void)testApproveNotificationSendsMessageToService {
    // Given
    [database insertNotification:notification error:nil];
    OCMExpect([messageUtilsMock respondWithEndpoint:@"http://service.endpoint"
                                       base64Secret:@"secret"
                                          messageId:@"messageId"
                             loadBalancerCookieData:@"amlbcookie=03"
                                               data:@{@"response":[FRAMessageUtils generateChallengeResponse:@"challenge"
                                                                                                      secret:@"secret"]}
                                            handler:[OCMArg any]]);
    
    // When
    [notification approveWithError:nil];
    
    // Then
    OCMVerifyAll(messageUtilsMock);
}

- (void)testShouldDenyNotification {
    // Given
    
    // When
    [notification denyWithError:nil];
    
    // Then
    XCTAssertEqual([notification isPending], NO);
    XCTAssertEqual([notification isApproved], NO);
    XCTAssertEqual([notification isDenied], YES);
}

- (void)testDenyNotificationSendsMessageToService {
    // Given
    [database insertNotification:notification error:nil];
    NSDictionary *expectedData = @{
            @"response":[FRAMessageUtils generateChallengeResponse:@"challenge" secret:@"secret"],
            @"deny": @YES
            };
    OCMExpect([messageUtilsMock respondWithEndpoint:@"http://service.endpoint"
                                       base64Secret:@"secret"
                                          messageId:@"messageId"
                             loadBalancerCookieData:@"amlbcookie=03"
                                               data:expectedData
                                            handler:[OCMArg any]]);
    
    // When
    [notification denyWithError:nil];
    
    // Then
    OCMVerifyAll(messageUtilsMock);
}

- (void)testSavedNotificationAutomaticallySavesItselfToDatabaseWhenApproved {
    // Given
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertNotification:notification error:nil]).andReturn(YES);
    [database insertNotification:notification error:nil];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations updateNotification:notification error:nil]).andReturn(YES);
    OCMStub([messageUtilsMock respondWithEndpoint:@"http://service.endpoint"
                                     base64Secret:@"secret"
                                        messageId:@"messageId"
                           loadBalancerCookieData:@"amlbcookie=03"
                                             data:@{@"response":[FRAMessageUtils generateChallengeResponse:@"challenge"
                                                                                                    secret:@"secret"]}
                                          handler:[OCMArg any]]);

    
    // When
    BOOL notificationApproved = [notification approveWithError:nil];
    
    // Then
    XCTAssertTrue(notificationApproved);
}

- (void)testSavedNotificationAutomaticallySavesItselfToDatabaseWhenDenied {
    // Given
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertNotification:notification error:nil]).andReturn(YES);
    [database insertNotification:notification error:nil];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations updateNotification:notification error:nil]).andReturn(YES);
    
    // When
    BOOL notificationDenied = [notification denyWithError:nil];
    
    // Then
    XCTAssertTrue(notificationDenied);
}

- (void)testBroadcastsOneChangeNotificationWhenNotificationUpdateIsAutomaticallySavedToDatabase {
    // Given
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations insertNotification:notification error:nil]).andReturn(YES);
    [database insertNotification:notification error:nil];
    OCMStub([(FRAIdentityDatabaseSQLiteOperations*)mockSqlOperations updateNotification:notification error:nil]).andReturn(YES);
    [[NSNotificationCenter defaultCenter] addMockObserver:databaseObserverMock name:FRAIdentityDatabaseChangedNotification object:database];
    [[databaseObserverMock expect] notificationWithName:FRAIdentityDatabaseChangedNotification object:database userInfo:[OCMArg any]];
    OCMStub([messageUtilsMock respondWithEndpoint:@"http://service.endpoint"
                                     base64Secret:@"secret"
                                        messageId:@"messageId"
                           loadBalancerCookieData:@"amlbcookie=03"
                                             data:@{@"response":[FRAMessageUtils generateChallengeResponse:@"challenge"
                                                                                                    secret:@"secret"]}
                                          handler:[OCMArg any]]);
    
    // When
    BOOL notificationApproved = [notification approveWithError:nil];
    
    // Then
    XCTAssertTrue(notificationApproved);
    OCMVerifyAll(databaseObserverMock);
}

- (void)testIsExpiredReturnsYesIfNotificationHasExpired {
    // Given
    FRANotification *expiredNotification = [[FRANotification alloc] initWithDatabase:database identityModel:mockIdentityModel messageId:@"messageId" challenge:@"challenge" timeReceived:[NSDate date] timeToLive:-10.0 loadBalancerCookieData:@"amlbcookie=03"];
    
    // When
    
    // Then
    XCTAssertEqual([expiredNotification isExpired], YES);
    XCTAssertEqual([expiredNotification isPending], NO);
    XCTAssertEqual([expiredNotification isApproved], NO);
    XCTAssertEqual([expiredNotification isDenied], NO);
}

- (void)testIsExpiredReturnsNoIfNotificationHasNotExpired {
    // Given
    FRANotification *expiredNotification = [[FRANotification alloc] initWithDatabase:database identityModel:mockIdentityModel messageId:@"messageId" challenge:@"challenge" timeReceived:[NSDate date] timeToLive:120.0 loadBalancerCookieData:@"amlbcookie=03"];
    
    // When
    
    // Then
    XCTAssertEqual([expiredNotification isExpired], NO);
    XCTAssertEqual([expiredNotification isPending], YES);
    XCTAssertEqual([expiredNotification isApproved], NO);
    XCTAssertEqual([expiredNotification isDenied], NO);
}

@end

