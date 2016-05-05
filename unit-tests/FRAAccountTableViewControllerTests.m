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
#import "FRAIdentityModel.h"
#import "FRAIdentity.h"
#import "FRANotification.h"
#import "FRAOathMechanism.h"
#import "FRAPushMechanism.h"
#import "FRAPushMechanismTableViewCell.h"

@interface FRAAccountTableViewControllerTests : XCTestCase

@end

@implementation FRAAccountTableViewControllerTests {
    
    FRAAccountTableViewController *viewController;
    FRAIdentity *identity;
    NSIndexPath *oathMechanismIndexPath;
    NSIndexPath *pushMechanismIndexPath;
    
}

- (void)setUp {
    [super setUp];
    
    identity = [FRAIdentity identityWithDatabase:nil accountName:@"Alice" issuer:@"ForgeRock" image:nil];
    
    // load accounts controller from storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    viewController = [storyboard instantiateViewControllerWithIdentifier:@"AccountTableViewController"];
    viewController.identity = identity;
    
    oathMechanismIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    pushMechanismIndexPath = [NSIndexPath indexPathForRow:2 inSection:0];
}

- (void)tearDown {
    [self simulateUnloadingOfView];
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

// FIXME: This test failing because FRAIdentity mechanismsList sees oath mechanism as FRAMechanism rather than FRAOathMechanism!
//- (void)testShowsOathMechanismIfIdentityHasOneRegistered {
//    // Given
//    FRAOathMechanism *oathMechanism = [FRAOathMechanism oathMechanismWithDatabase:nil type:nil usingSecretKey:nil andHMACAlgorithm:nil withKeyLength:nil andEitherPeriod:nil orCounter:nil];
//    [identity addMechanism:oathMechanism];
//    
//    // When
//    [self simulateLoadingOfView];
//    
//    // Then
//    XCTAssertTrue([self isShowingCellAtIndexPath:oathMechanismIndexPath], @"OATH mechanism UI should be displayed");
//    XCTAssertFalse([self isShowingCellAtIndexPath:pushMechanismIndexPath], @"Push mechanism UI should not be displayed");
//}

- (void)testShowsPushMechanismIfIdentityHasOneRegistered {
    // Given
    FRAPushMechanism *pushMechanism = [FRAPushMechanism pushMechanismWithDatabase:nil];
    [identity addMechanism:pushMechanism];
    
    // When
    [self simulateLoadingOfView];
    
    // Then
    XCTAssertFalse([self isShowingCellAtIndexPath:oathMechanismIndexPath], @"OATH mechanism UI should not be displayed");
    XCTAssertTrue([self isShowingCellAtIndexPath:pushMechanismIndexPath], @"Push mechanism UI should be displayed");
}

- (void)testShowsCountOfPendingNotificationsIfIdentityHasRegisteredPushMechanism {
    // Given
    FRAPushMechanism *pushMechanism = [FRAPushMechanism pushMechanismWithDatabase:nil];
    [pushMechanism addNotification:[self pendingNotification]];
    [pushMechanism addNotification:[self pendingNotification]];
    [pushMechanism addNotification:[self approvedNotification]];
    [identity addMechanism:pushMechanism];
    
    // When
    [self simulateLoadingOfView];
    
    // Then
    XCTAssertEqualObjects([self pushMechanismTableViewCell].notificationsBadge.text, @"2");
}

- (void)simulateLoadingOfView {
    [viewController loadViewIfNeeded]; // force IBOutlets etc to be initialized
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
                                           messageId:@"dummy"
                                           challenge:@"dummy"
                                        timeReceived:[NSDate date]
                                                 timeToLive:120.0];
}

- (FRANotification *)approvedNotification {
    FRANotification *notification = [self pendingNotification];
    [notification approve];
    return notification;
}

- (FRAOathMechanismTableViewCell *)oathMechanismTableViewCell {
    return (FRAOathMechanismTableViewCell*) [viewController tableView:viewController.tableView cellForRowAtIndexPath:oathMechanismIndexPath];
}

- (FRAPushMechanismTableViewCell *)pushMechanismTableViewCell {
    return (FRAPushMechanismTableViewCell*) [viewController tableView:viewController.tableView cellForRowAtIndexPath:pushMechanismIndexPath];
}

@end
