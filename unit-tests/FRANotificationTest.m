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
#import <XCTest/XCTest.h>
#import "FRANotification.h"

@interface FRANotificationTest : XCTestCase

@end

@implementation FRANotificationTest {
    FRANotification* notification;
}


- (void)setUp {
    [super setUp];
    notification = [[FRANotification alloc] init];
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




@end

