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

#import "FRABlockAlertView.h"
#import "FRAIdentity.h"
#import "FRAMechanism.h"
#import "FRANotification.h"
#import "FRANotificationViewController.h"
#import "FRAUIUtils.h"

NSString * const FRANotificationViewControllerStoryboardIdentifer = @"NotificationViewController";

static NSString * const OFF_SWITCH_IMAGE_NAME = @"OffSwitchIcon";
static NSString * const ON_SWITCH_IMAGE_NAME = @"OnSwitchIcon";

@implementation FRANotificationViewController

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.authorizeSlider.continuous = YES;
    [self setSliderThumbImage:OFF_SWITCH_IMAGE_NAME];
    FRAIdentity *identity = self.notification.parent.parent;
    [FRAUIUtils setImage:self.image fromIssuerLogoURL:identity.image];
    self.image.layer.cornerRadius = self.image.frame.size.width / 2;
    self.image.clipsToBounds = YES;
    self.message.text = [NSString stringWithFormat:@"Log in to %@", identity.issuer];
    [FRAUIUtils setView:self.backgroundView issuerBackgroundColor:identity.backgroundColor];
    
    if ([self isTouchIDEnabled]) {
        [self layoutViewForTouchID];
        [self authenticateUsingTouchID];
    } else {
        [self layoutViewForSlider];
    }
}

#pragma mark -
#pragma mark FRANotificationViewController

- (IBAction)updateSliderPosition:(id)sender {
    if (![self isSliderAtEndOfTrack]) {
        [self setSliderThumbImage:OFF_SWITCH_IMAGE_NAME];
    } else {
        [self setSliderThumbImage:ON_SWITCH_IMAGE_NAME];
    }
}

- (IBAction)touchUpOutside:(id)sender {
    [self setSliderThumbImage:OFF_SWITCH_IMAGE_NAME];
    [self moveSliderToStartOfTrack];
}

- (IBAction)authorize:(id)sender {
    if ([self isSliderAtEndOfTrack]) {
        [self approveNotification];
    } else {
        [self moveSliderToStartOfTrack];
    }
}

- (IBAction)dismiss:(id)sender {
    [self dismissNotification];
}

#pragma mark -
#pragma mark Helper methods

- (void)setSliderThumbImage:(NSString *)imageName {
    [self.authorizeSlider setThumbImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}

- (BOOL)isSliderAtEndOfTrack {
    return (self.authorizeSlider.value == self.authorizeSlider.maximumValue);
}

- (void)moveSliderToStartOfTrack {
    [self.authorizeSlider setValue:self.authorizeSlider.minimumValue animated:YES];
}

- (void)approveNotification {
    self.authorizeSlider.userInteractionEnabled = NO;
    self.denyButton.userInteractionEnabled = NO;
    NSError* error;
    if (![self.notification approveWithHandler:[self approveDismissNotificationCallbackWithTitle:NSLocalizedString(@"notification_approval_error_title", nil)] error:&error]) {
        [self showAlertWithTitle:NSLocalizedString(@"notification_approval_error_title", nil)
                         message:nil];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissNotification {
    self.authorizeSlider.userInteractionEnabled = NO;
    self.denyButton.userInteractionEnabled = NO;
    NSError* error;
    if (![self.notification denyWithHandler:[self approveDismissNotificationCallbackWithTitle:NSLocalizedString(@"notification_dismissal_error_title", nil)] error:&error]) {
        [self showAlertWithTitle:NSLocalizedString(@"notification_dismissal_error_title", nil)
                         message:nil];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)isTouchIDEnabled {
    LAContext *authContext = [self.authContextFactory newLAContext];
    NSError *error = nil;
    return [authContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
}

- (void)authenticateUsingTouchID {
    FRAIdentity *identity = self.notification.parent.parent;
    NSString *localizedReason = [NSString stringWithFormat:@"Log in to %@ as %@ using Touch ID", identity.issuer, identity.accountName];
    
    LAContext *authContext = [self.authContextFactory newLAContext];
    
    // Request Touch ID authentication, (allowing user fallback to Password)
    [authContext evaluatePolicy:LAPolicyDeviceOwnerAuthentication
                localizedReason:localizedReason
                          reply:^(BOOL success, NSError *callbackError) {
                              if (success) {
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      [self approveNotification];
                                  });
                              } else {
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      [self dismissNotification];
                                  });
                              }
                          }];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    FRABlockAlertView *alertView = [[FRABlockAlertView alloc] initWithTitle:title
                                                                    message:message
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                                           otherButtonTitle:nil
                                                                    handler:nil];
    [alertView show];
}

- (void(^)(NSInteger, NSError *))approveDismissNotificationCallbackWithTitle:(NSString *)title {
    return ^(NSInteger statusCode, NSError *error) {
        if (200 != statusCode) {
            [self showAlertWithTitle:title message:NSLocalizedString(@"notification_error_network_failure_message", nil)];
        }
    };
}

- (void)layoutViewForTouchID {
    [self hideControls:YES];
    [self.backgroundView removeConstraints:self.backgroundView.constraints];
    NSLayoutConstraint *imageCenterX =[NSLayoutConstraint
                                       constraintWithItem:self.image
                                       attribute:NSLayoutAttributeCenterX
                                       relatedBy:NSLayoutRelationEqual
                                       toItem:self.view
                                       attribute:NSLayoutAttributeCenterX
                                       multiplier:1.0f
                                       constant:0.f];
    NSLayoutConstraint *imageCenterY =[NSLayoutConstraint
                                       constraintWithItem:self.image
                                       attribute:NSLayoutAttributeCenterY
                                       relatedBy:NSLayoutRelationEqual
                                       toItem:self.backgroundView
                                       attribute:NSLayoutAttributeCenterY
                                       multiplier:0.4f
                                       constant:0.f];
    NSLayoutConstraint *backgroundViewBottom =[NSLayoutConstraint
                                               constraintWithItem:self.backgroundView
                                               attribute:NSLayoutAttributeBottom
                                               relatedBy:NSLayoutRelationEqual
                                               toItem:self.view
                                               attribute:NSLayoutAttributeBottom
                                               multiplier:1.0f
                                               constant:0.f];
    [self.view addConstraint:imageCenterX];
    [self.view addConstraint:imageCenterY];
    [self.view addConstraint:backgroundViewBottom];
}

- (void)layoutViewForSlider {
    [self hideControls:NO];
}

- (void)hideControls:(BOOL)hide {
    self.authorizeSlider.hidden = hide;
    self.denyButton.hidden = hide;
    self.message.hidden = hide;
}

@end