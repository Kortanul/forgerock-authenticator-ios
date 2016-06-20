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

#import "FRAAccountTableViewController.h"
#import "FRAApplicationAssembly.h"
#import "FRAHotpOathMechanism.h"
#import "FRAIdentityModel.h"
#import "FRAIdentity.h"
#import "FRAModelsFromDatabase.h"
#import "FRAModelUtils.h"
#import "FRANotification.h"
#import "FRAPushMechanism.h"
#import "FRAPushMechanismTableViewCell.h"
#import "FRATotpOathMechanism.h"

@interface FRAAccountTableViewControllerTests : XCTestCase

@end

@implementation FRAAccountTableViewControllerTests {
    FRAAccountTableViewController *viewController;
    FRAIdentity *identity;
    NSIndexPath *oathMechanismIndexPath;
    NSIndexPath *pushMechanismIndexPath;
    FRAModelUtils *modelUtils;
    id mockModelsFromDatabase;
}

- (void)setUp {
    [super setUp];
    
    mockModelsFromDatabase = OCMClassMock([FRAModelsFromDatabase class]);
    OCMStub([mockModelsFromDatabase allIdentitiesWithDatabase:[OCMArg any] identityDatabase:[OCMArg any] identityModel:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(@[]);
    
    identity = [FRAIdentity identityWithDatabase:nil identityModel:nil accountName:@"Alice" issuer:@"ForgeRock" image:nil backgroundColor:nil];
    
    // load accounts controller from storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    viewController = [storyboard instantiateViewControllerWithIdentifier:@"AccountTableViewController"];
    viewController.identity = identity;
    
    oathMechanismIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    pushMechanismIndexPath = [NSIndexPath indexPathForRow:2 inSection:0];
    
    modelUtils = [[FRAModelUtils alloc] init];
}

- (void)tearDown {
    [self simulateUnloadingOfView];
    [mockModelsFromDatabase stopMocking];
    [super tearDown];
}

- (void)testDisplaysIssuerAndAccountNameForIdentity {
    // Given
    
    // When
    [self simulateLoadingOfView];
    
    // Then
    XCTAssertEqual(viewController.issuer.text, @"ForgeRock");
    XCTAssertEqual(viewController.accountName.text, @"Alice");
}

- (void)testShowsNoMechanismsIfIdentityHasNoneRegistered {
    // Given
    
    // When
    [self simulateLoadingOfView];
    
    // Then
    XCTAssertFalse([self isShowingCellAtIndexPath:oathMechanismIndexPath], @"OATH mechanism UI should not be displayed");
    XCTAssertFalse([self isShowingCellAtIndexPath:pushMechanismIndexPath], @"Push mechanism UI should not be displayed");
}

- (void)testShowsOathMechanismIfIdentityHasOneRegistered {
    // Given
    FRAHotpOathMechanism *mechanism = [modelUtils demoOathMechanism];
    
    [identity addMechanism:mechanism error:nil];
    
    // When
    [self simulateLoadingOfView];
    
    // Then
    XCTAssertTrue([self isShowingCellAtIndexPath:oathMechanismIndexPath], @"OATH mechanism UI should be displayed");
    XCTAssertFalse([self isShowingCellAtIndexPath:pushMechanismIndexPath], @"Push mechanism UI should not be displayed");
}

- (void)testShowsPushMechanismIfIdentityHasOneRegistered {
    // Given
    FRAPushMechanism *pushMechanism = [FRAPushMechanism pushMechanismWithDatabase:nil identityModel:nil];
    [identity addMechanism:pushMechanism error:nil];
    
    // When
    [self simulateLoadingOfView];
    
    // Then
    XCTAssertFalse([self isShowingCellAtIndexPath:oathMechanismIndexPath], @"OATH mechanism UI should not be displayed");
    XCTAssertTrue([self isShowingCellAtIndexPath:pushMechanismIndexPath], @"Push mechanism UI should be displayed");
}

- (void)testShowsCountOfPendingNotificationsIfIdentityHasRegisteredPushMechanism {
    // Given
    FRAPushMechanism *pushMechanism = [FRAPushMechanism pushMechanismWithDatabase:nil identityModel:nil];
    [pushMechanism addNotification:[self pendingNotification] error:nil];
    [pushMechanism addNotification:[self pendingNotification] error:nil];
    [pushMechanism addNotification:[self approvedNotification] error:nil];
    [identity addMechanism:pushMechanism error:nil];
    
    // When
    [self simulateLoadingOfView];
    
    // Then
    XCTAssertEqualObjects([self pushMechanismTableViewCell].notificationsBadge.text, @"2");
}

- (void)simulateLoadingOfView {
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_8_4) {
        [viewController view]; // force IBOutlets etc to be initialized
    } else {
        [viewController loadViewIfNeeded]; // force IBOutlets etc to be initialized
    }
    XCTAssertNotNil(viewController.view);
    [viewController viewWillAppear:YES];
}

- (void)simulateUnloadingOfView {
    [viewController viewWillDisappear:YES];
}

- (BOOL)isShowingCellAtIndexPath:(NSIndexPath *)indexPath {
    return [viewController tableView:viewController.tableView heightForRowAtIndexPath:indexPath] > 0;
}

- (FRANotification *)pendingNotification {
    return [FRANotification notificationWithDatabase:nil
                                       identityModel:nil
                                           messageId:@"dummy"
                                           challenge:@"dummy"
                                        timeReceived:[NSDate date]
                                          timeToLive:120.0
                              loadBalancerCookieData:nil];
}

- (FRANotification *)approvedNotification {
    FRANotification *notification = [self pendingNotification];
    [notification approveWithHandler:nil error:nil];
    return notification;
}

- (FRAOathMechanismTableViewCell *)oathMechanismTableViewCell {
    return (FRAOathMechanismTableViewCell*) [viewController tableView:viewController.tableView cellForRowAtIndexPath:oathMechanismIndexPath];
}

- (FRAPushMechanismTableViewCell *)pushMechanismTableViewCell {
    return (FRAPushMechanismTableViewCell*) [viewController tableView:viewController.tableView cellForRowAtIndexPath:pushMechanismIndexPath];
}

@end
