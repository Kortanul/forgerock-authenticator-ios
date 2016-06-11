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

#import "FRAApplicationAssembly.h"
#import "FRAIdentityModel.h"
#import "FRAIdentity.h"
#import "FRANotification.h"
#import "FRANotificationTableViewCell.h"
#import "FRANotificationsTableViewController.h"
#import "FRAPushMechanism.h"

static const NSInteger SECTIONS = 2;
static const NSInteger PENDING_SECTION = 0;
static const NSInteger COMPLETED_SECTION = 1;

@interface FRANotificationsTableViewControllerTests : XCTestCase

@end

@implementation FRANotificationsTableViewControllerTests {
    
    FRANotificationsTableViewController *viewController;
    FRAPushMechanism *pushMechanism;
    
}

- (void)setUp {
    [super setUp];
    
    pushMechanism = [FRAPushMechanism pushMechanismWithDatabase:nil identityModel:nil];
    
    // load notifications controller from storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    viewController = [storyboard instantiateViewControllerWithIdentifier:@"NotificationsTableViewController"];
    viewController.pushMechanism = pushMechanism;
}

- (void)tearDown {
    [self simulateUnloadingOfView];
    [super tearDown];
}

- (void)testShowsNoNotificationsIfThereAreNone {
    // Given
    
    // When
    [self simulateLoadingOfView];
    
    // Then
    XCTAssertEqual([viewController numberOfSectionsInTableView:viewController.tableView], SECTIONS);
    XCTAssertEqual([viewController tableView:viewController.tableView numberOfRowsInSection:PENDING_SECTION], 0);
    XCTAssertEqual([viewController tableView:viewController.tableView numberOfRowsInSection:COMPLETED_SECTION], 0);
}

- (void)testShowsPendingNotificationsInFirstSection {
    // Given
    [pushMechanism addNotification:[self pendingNotificationReceivedAt:[NSDate date]] error:nil];
    [pushMechanism addNotification:[self pendingNotificationReceivedAt:[NSDate date]] error:nil];
    
    // When
    [self simulateLoadingOfView];
    
    // Then
    XCTAssertEqualObjects([viewController tableView:viewController.tableView titleForHeaderInSection:PENDING_SECTION], @"");
    XCTAssertEqual([viewController tableView:viewController.tableView numberOfRowsInSection:PENDING_SECTION], 2);
    XCTAssertEqual([viewController tableView:viewController.tableView numberOfRowsInSection:COMPLETED_SECTION], 0);
}

- (void)testShowsCompletedNotificationsInSecondSection {
    // Given
    [pushMechanism addNotification:[self approvedNotificationReceivedAt:[NSDate date]] error:nil];
    [pushMechanism addNotification:[self deniedNotificationReceivedAt:[NSDate date]] error:nil];
    
    // When
    [self simulateLoadingOfView];
    
    // Then
    XCTAssertEqualObjects([viewController tableView:viewController.tableView titleForHeaderInSection:COMPLETED_SECTION], @"COMPLETED");
    XCTAssertEqual([viewController tableView:viewController.tableView numberOfRowsInSection:PENDING_SECTION], 0);
    XCTAssertEqual([viewController tableView:viewController.tableView numberOfRowsInSection:COMPLETED_SECTION], 2);
}

- (void)testShowsDetailsOfPendingNotification {
    // Given
    FRANotification *pendingNotification = [self pendingNotificationReceivedAt:[NSDate dateWithTimeIntervalSinceNow:-15.0]];
    [pushMechanism addNotification:pendingNotification error:nil];
    [self simulateLoadingOfView];
    NSIndexPath *notificationIndexPath = [NSIndexPath indexPathForRow:0 inSection:PENDING_SECTION];
    
    // When
    FRANotificationTableViewCell *cell = [self cellForRowAtIndexPath:notificationIndexPath];
    
    // Then
    XCTAssertEqualObjects(cell.status.text, @"Pending");
    XCTAssertEqualObjects(cell.time.text, [pendingNotification age]);
}

- (void)testCanSequeFromPendingNotificationToNotificationView {
    // Given
    [pushMechanism addNotification:[self pendingNotificationReceivedAt:[NSDate date]] error:nil];
    [self simulateLoadingOfView];
    NSIndexPath *notificationIndexPath = [NSIndexPath indexPathForRow:0 inSection:PENDING_SECTION];
    
    // When
    FRANotificationTableViewCell *cell = [self cellForRowAtIndexPath:notificationIndexPath];
    
    // Then
    XCTAssertEqual(cell.selectionStyle, UITableViewCellSelectionStyleDefault);
    XCTAssertEqual(cell.isUserInteractionEnabled, YES);
    XCTAssertEqual(cell.accessoryType, UITableViewCellAccessoryDisclosureIndicator);
    XCTAssertEqualObjects([viewController tableView:viewController.tableView willSelectRowAtIndexPath:notificationIndexPath], notificationIndexPath);
}

- (void)testShowsDetailsOfApprovedNotification {
    // Given
    FRANotification *approvedNotification = [self approvedNotificationReceivedAt:[NSDate dateWithTimeIntervalSinceNow:-15.0]];
    [pushMechanism addNotification:approvedNotification error:nil];
    [self simulateLoadingOfView];
    NSIndexPath *notificationIndexPath = [NSIndexPath indexPathForRow:0 inSection:COMPLETED_SECTION];

    // When
    FRANotificationTableViewCell *cell = [self cellForRowAtIndexPath:notificationIndexPath];
    
    // Then
    XCTAssertEqualObjects(cell.status.text, @"Approved");
    XCTAssertEqualObjects(cell.time.text, [approvedNotification age]);
}

- (void)testCannotSequeFromApprovedNotificationToNotificationView {
    // Given
    [pushMechanism addNotification:[self approvedNotificationReceivedAt:[NSDate date]] error:nil];
    [self simulateLoadingOfView];
    NSIndexPath *notificationIndexPath = [NSIndexPath indexPathForRow:0 inSection:COMPLETED_SECTION];
    
    // When
    FRANotificationTableViewCell *cell = [self cellForRowAtIndexPath:notificationIndexPath];
    
    // Then
    XCTAssertEqual(cell.selectionStyle, UITableViewCellSelectionStyleNone);
    XCTAssertEqual(cell.isUserInteractionEnabled, NO);
    XCTAssertEqual(cell.accessoryType, UITableViewCellAccessoryNone);
    XCTAssertEqualObjects([viewController tableView:viewController.tableView willSelectRowAtIndexPath:notificationIndexPath], nil);
}

- (void)testShowsDetailsOfDeniedNotification {
    // Given
    FRANotification *deniedNotification = [self deniedNotificationReceivedAt:[NSDate dateWithTimeIntervalSinceNow:-15.0]];
    [pushMechanism addNotification:deniedNotification error:nil];
    [self simulateLoadingOfView];
    NSIndexPath *notificationIndexPath = [NSIndexPath indexPathForRow:0 inSection:COMPLETED_SECTION];
    
    // When
    FRANotificationTableViewCell *cell = [self cellForRowAtIndexPath:notificationIndexPath];
    
    // Then
    XCTAssertEqualObjects(cell.status.text, @"Denied");
    XCTAssertEqualObjects(cell.time.text, [deniedNotification age]);
}

- (void)testCannotSequeFromDeniedNotificationToNotificationView {
    // Given
    [pushMechanism addNotification:[self deniedNotificationReceivedAt:[NSDate date]] error:nil];
    [self simulateLoadingOfView];
    NSIndexPath *notificationIndexPath = [NSIndexPath indexPathForRow:0 inSection:COMPLETED_SECTION];
    
    // When
    FRANotificationTableViewCell *cell = [self cellForRowAtIndexPath:notificationIndexPath];
    
    // Then
    XCTAssertEqual(cell.selectionStyle, UITableViewCellSelectionStyleNone);
    XCTAssertEqual(cell.isUserInteractionEnabled, NO);
    XCTAssertEqual(cell.accessoryType, UITableViewCellAccessoryNone);
    XCTAssertEqualObjects([viewController tableView:viewController.tableView willSelectRowAtIndexPath:notificationIndexPath], nil);
}

// FIXME: testSortsPendingNotificationsChronologically fails due to unmet assertions in UIKit
//- (void)testSortsPendingNotificationsChronologically {
//    // Given
//    FRANotification *firstNotification = [self pendingNotificationReceivedAt:[NSDate dateWithTimeIntervalSinceNow:-15.0]];
//    FRANotification *secondNotification = [self pendingNotificationReceivedAt:[NSDate dateWithTimeIntervalSinceNow:-240.0]];
//    FRANotification *thirdNotification = [self pendingNotificationReceivedAt:[NSDate dateWithTimeIntervalSinceNow:-300.0]];
//    // NB. Add notifications out of order to confirm that they get sorted after retrieval from the push mechanism
//    [pushMechanism addNotification:secondNotification error:nil];
//    [pushMechanism addNotification:thirdNotification error:nil];
//    [pushMechanism addNotification:firstNotification error:nil];
//    
//    // When
//    FRANotificationTableViewCell *firstCell = [self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:PENDING_SECTION]];
//    FRANotificationTableViewCell *secondCell = [self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:PENDING_SECTION]];
//    FRANotificationTableViewCell *thirdCell = [self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:PENDING_SECTION]];
//    
//    // Then
//    XCTAssertEqualObjects(firstCell.time.text, [firstNotification age]);
//    XCTAssertEqualObjects(secondCell.time.text, [secondNotification age]);
//    XCTAssertEqualObjects(thirdCell.time.text, [thirdNotification age]);
//}

- (void)testSortsCompletedNotificationsChronologically {
    // Given
    FRANotification *firstNotification = [self approvedNotificationReceivedAt:[NSDate dateWithTimeIntervalSinceNow:-15.0]];
    FRANotification *secondNotification = [self deniedNotificationReceivedAt:[NSDate dateWithTimeIntervalSinceNow:-240.0]];
    FRANotification *thirdNotification = [self approvedNotificationReceivedAt:[NSDate dateWithTimeIntervalSinceNow:-300.0]];
    // NB. Add notifications out of order to confirm that they get sorted after retrieval from the push mechanism
    [pushMechanism addNotification:secondNotification error:nil];
    [pushMechanism addNotification:thirdNotification error:nil];
    [pushMechanism addNotification:firstNotification error:nil];
    
    // When
    FRANotificationTableViewCell *firstCell = [self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:COMPLETED_SECTION]];
    FRANotificationTableViewCell *secondCell = [self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:COMPLETED_SECTION]];
    FRANotificationTableViewCell *thirdCell = [self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:COMPLETED_SECTION]];
    
    // Then
    XCTAssertEqualObjects(firstCell.time.text, [firstNotification age]);
    XCTAssertEqualObjects(secondCell.time.text, [secondNotification age]);
    XCTAssertEqualObjects(thirdCell.time.text, [thirdNotification age]);
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

- (FRANotification *)pendingNotificationReceivedAt:(NSDate *)timeReceived {
    return [FRANotification notificationWithDatabase:nil
                                       identityModel:nil
                                           messageId:@"dummy"
                                           challenge:@"dummy"
                                        timeReceived:timeReceived
                                          timeToLive:120.0
                              loadBalancerCookieData:@"01"];
}

- (FRANotification *)approvedNotificationReceivedAt:(NSDate *)timeReceived {
    FRANotification *notification = [self pendingNotificationReceivedAt:timeReceived];
    [notification approveWithError:nil];
    return notification;
}

- (FRANotification *)deniedNotificationReceivedAt:(NSDate *)timeReceived {
    FRANotification *notification = [self pendingNotificationReceivedAt:timeReceived];
    [notification denyWithError:nil];
    return notification;
}

- (FRANotificationTableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return (FRANotificationTableViewCell *)
            [viewController tableView:viewController.tableView cellForRowAtIndexPath:indexPath];
}

@end
