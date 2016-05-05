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

#import <XCTest/XCTest.h>
#import "FRAIdentityDatabase.h"
#import "FRAIdentity.h"
#import "FRAPushMechanism.h"
#import "FRANotificationHandler.h"
#import "FRAIdentityModel.h"

@interface FRANotificationHandlerTest : XCTestCase

@end


static NSString *const TEST_USERNAME = @"Alice";

@implementation FRANotificationHandlerTest {
    FRANotificationHandler* handler;
    FRAIdentityDatabase* database;
    FRAIdentityModel* identityModel;
    FRAIdentity* testIdentity;
    FRAPushMechanism* testMechanism;
    NSInteger testMechanismUid;
}

- (void)setUp {
    [super setUp];
    
    database = [[FRAIdentityDatabase alloc] init];
    
    identityModel = [[FRAIdentityModel alloc] initWithDatabase:database];
    
    testIdentity = [FRAIdentity identityWithDatabase:database accountName:TEST_USERNAME issuer:@"ForgeRock" image:nil];
    testMechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    
    [identityModel addIdentity:testIdentity];
    [testIdentity addMechanism:testMechanism];
    [database insertIdentity:testIdentity];
    [database insertMechanism:testMechanism];
    
    testMechanismUid = testMechanism.uid;
    
    handler = [[FRANotificationHandler alloc] initWithDatabase:database identityModel:identityModel];
}

- (void)tearDown {
    [testIdentity removeMechanism:testMechanism];
    [database deleteMechanism:testMechanism];
    [database deleteIdentity:testIdentity];
    
    [super tearDown];
}

- (void)testHandleRemoteNotification {
    // Given
    NSDictionary* data = @{
                           @"messageId": @"123",
                           @"mechanismUID": [NSString stringWithFormat: @"%ld", (long)testMechanismUid],
                           @"timeToLive": @"120",
                           @"challenge": @"pistolsAtDawn",
                           };
    // When
    
    [handler handleRemoteNotification:data];
    // Then
    FRAMechanism *mechanismResult = [identityModel mechanismWithId:testMechanismUid];
    
    XCTAssertEqual([[mechanismResult notifications] count], 1, "Mechanism did not contain expected Notification");
}

@end
