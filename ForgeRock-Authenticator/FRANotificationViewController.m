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

#import <LocalAuthentication/LocalAuthentication.h>

#import "FRAIdentity.h"
#import "FRAMechanism.h"
#import "FRANotification.h"
#import "FRANotificationViewController.h"
#import "FRAUIUtils.h"

NSString * const FRANotificationViewControllerStoryboardIdentifer = @"NotificationViewController";

@implementation FRANotificationViewController

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.authorizeSlider setThumbImage:[UIImage imageNamed:@"OffSwitchIcon"] forState:UIControlStateNormal];
    FRAIdentity *identity = self.notification.parent.parent;
    [FRAUIUtils setImage:self.image fromIssuerLogoURL:identity.image];
    self.image.layer.cornerRadius = self.image.frame.size.width / 2;
    self.image.clipsToBounds = YES;
    self.message.text = [NSString stringWithFormat:@"Log in to %@", identity.issuer];
    [FRAUIUtils setView:self.backgroundView issuerBackgroundColor:identity.backgroundColor];
    
    if ([self isTouchIDEnabled]) {
        self.authorizeSlider.hidden = YES;
        self.denyButton.hidden = YES;
        [self authenticateUsingTouchID];
    } else {
        self.authorizeSlider.hidden = NO;
        self.denyButton.hidden = NO;
    }
}

#pragma mark -
#pragma mark FRANotificationViewController

- (IBAction)updateSliderPosition:(id)sender {
    if (![self isSliderAtEndOfTrack]) {
        [self moveSliderToStartOfTrack];
    }
}

- (IBAction)authorize:(id)sender {
    if ([self isSliderAtEndOfTrack]) {
        [self approveNotification];
    }
}

- (IBAction)dismiss:(id)sender {
    [self dismissNotification];
}

#pragma mark -
#pragma mark Helper methods

- (BOOL)isSliderAtEndOfTrack {
    return (self.authorizeSlider.value == self.authorizeSlider.maximumValue);
}

- (void)moveSliderToStartOfTrack {
    [self.authorizeSlider setValue:self.authorizeSlider.minimumValue animated:YES];
}

- (void)approveNotification {
    [self.authorizeSlider setThumbImage:[UIImage imageNamed:@"OnSwitchIcon"] forState:UIControlStateNormal];
    self.authorizeSlider.userInteractionEnabled = NO;
    self.denyButton.userInteractionEnabled = NO;
    @autoreleasepool {
        NSError* error;
        [self.notification approveWithError:&error];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissNotification {
    self.authorizeSlider.userInteractionEnabled = NO;
    self.denyButton.userInteractionEnabled = NO;
    @autoreleasepool {
        NSError* error;
        [self.notification denyWithError:&error];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

// TODO: Ensure code still compiles / runs on iOS 7 - May need to guard calls to Touch ID functions etc

- (BOOL)isTouchIDEnabled {
    LAContext *authContext = [self.authContextFactory newLAContext];
    NSError *error = nil;
    return [authContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
}

- (void)authenticateUsingTouchID {
    LAContext *authContext = [self.authContextFactory newLAContext];
    FRAIdentity *identity = self.notification.parent.parent;
    NSString *localizedReason = [NSString stringWithFormat:@"Log in to %@ as %@ using Touch ID", identity.issuer, identity.accountName];
    
    [authContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                localizedReason:localizedReason
                          reply:^(BOOL success, NSError *callbackError) {
                              if (success) {
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      [self approveNotification];
                                  });
                              } else {
                                  // TODO: Provide error feedback to user in some circumstances
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      [self dismissNotification];
                                  });
                              }
                          }];
}

@end