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

#import "FRALAContextFactory.h"
#import "FRANotification.h"
#import "FRANotificationViewController.h"

@interface FRANotificationViewControllerTests : XCTestCase

@end

@implementation FRANotificationViewControllerTests {
    
    FRANotificationViewController *viewController;
    FRANotification *notification;
    FRALAContextFactory *authContextFactory;
    
}

- (void)setUp {
    [super setUp];
    
    notification = OCMClassMock([FRANotification class]);
    authContextFactory = OCMClassMock([FRALAContextFactory class]);
    
    // load notification controller from storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    viewController = [storyboard instantiateViewControllerWithIdentifier:FRANotificationViewControllerStoryboardIdentifer];
    viewController.notification = notification;
    viewController.authContextFactory = authContextFactory;
}

- (void)tearDown {
    [self simulateUnloadingOfView];
    [super tearDown];
}

- (void)testIfTouchIDUnavailableThenUserShouldBeShownSliderToApproveAndButtonToDenyAuthentication {
    // Given
    id authContext = OCMClassMock([LAContext class]);
    OCMStub([authContextFactory newLAContext]).andReturn(authContext);
    
    // When
    [self simulateLoadingOfView];
    
    // Then
    OCMVerifyAll(authContext);
    XCTAssertEqual(viewController.authorizeSlider.hidden, NO, "slider should be shown if Touch ID unavailable");
    XCTAssertEqual(viewController.denyButton.hidden, NO, "deny button should be shown if Touch ID unavailable");
}

- (void)testTouchIDShouldBeUsedIfAvailable {
    // Given
    id authContext = OCMClassMock([LAContext class]);
    OCMStub([authContextFactory newLAContext]).andReturn(authContext);
    OCMExpect([authContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMExpect([authContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:@"Log in to <issuer> using Touch ID" reply:[OCMArg any]]);
    
    // When
    [self simulateLoadingOfView];
    
    // Then
    OCMVerifyAll(authContext);
    XCTAssertEqual(viewController.authorizeSlider.hidden, YES, "slider should not be shown if Touch ID is available");
    XCTAssertEqual(viewController.denyButton.hidden, YES, "deny button should not be shown if Touch ID is available");
}

- (void)simulateLoadingOfView {
    [viewController loadViewIfNeeded]; // force IBOutlets etc to be initialized
    XCTAssertNotNil(viewController.view);
    [viewController viewWillAppear:YES];
}

- (void)simulateUnloadingOfView {
    [viewController viewWillDisappear:YES];
}

@end
