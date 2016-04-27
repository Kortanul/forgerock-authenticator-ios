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
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "FRANotificationGateway.h"
#import "FRANotificationHandler.h"

@interface FRANotificationGatewayTests : XCTestCase

@end

@implementation FRANotificationGatewayTests {

    FRANotificationGateway *notificationGateway;
    FRANotificationHandler *mockNotificationHandler;
    UIApplication *mockApplication;

}

- (void)setUp {
    [super setUp];
    mockApplication = OCMClassMock([UIApplication class]);
    mockNotificationHandler = OCMClassMock([FRANotificationHandler class]);
    notificationGateway = [FRANotificationGateway gatewayWithHandler:mockNotificationHandler];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testPropagatesPushNotificationsToRegisteredHandler {
    // Given
    NSDictionary *notification = @{};
    
    // When
    [notificationGateway application:mockApplication didReceiveRemoteNotification:notification];
    
    // Then
    OCMVerify([mockNotificationHandler handleRemoteNotification:notification]);
}

- (void)testBackgroundPropagatesPushNotificationsToRegisteredHandler {
    // Given
    NSDictionary *notification = @{};
    // When
    [notificationGateway application:mockApplication
        didReceiveRemoteNotification:notification
              fetchCompletionHandler:^(UIBackgroundFetchResult result){}];
    
    // Then
    OCMVerify([mockNotificationHandler handleRemoteNotification:notification]);
}

@end
