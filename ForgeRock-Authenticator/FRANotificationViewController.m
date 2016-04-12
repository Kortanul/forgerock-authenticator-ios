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

#import "FRANotificationViewController.h"
#import "FRANotification.h"

NSString * const FRANotificationViewControllerStoryboardIdentifer = @"NotificationViewController";

@implementation FRANotificationViewController

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //  _image = ... // TODO: Use UIImageView+AFNetworking category provided by AFNetworking
    [_authorizeSlider setThumbImage:[UIImage imageNamed:@"OffSwitchIcon"] forState:UIControlStateNormal];
    _image.layer.cornerRadius = _image.frame.size.width / 2;
    _image.clipsToBounds = YES;
}

#pragma mark -
#pragma mark FRANotificationViewController

- (IBAction)updateSliderPosition:(id)sender {
    if(![self isSliderAtEndOfTrack]) {
        [self moveSliderToStartOfTrack];
    }
}

- (IBAction)authorize:(id)sender {
    if([self isSliderAtEndOfTrack]) {
        [self approveNotification];
    }
}

- (IBAction)dismiss:(id)sender {
    [self dismissNotification];
}

#pragma mark -
#pragma mark Helper methods

- (BOOL)isSliderAtEndOfTrack {
    return (_authorizeSlider.value == _authorizeSlider.maximumValue);
}

- (void)moveSliderToStartOfTrack {
    [_authorizeSlider setValue:_authorizeSlider.minimumValue animated:YES];
}

- (void)approveNotification {
    [_authorizeSlider setThumbImage:[UIImage imageNamed:@"OnSwitchIcon"] forState:UIControlStateNormal];
    _authorizeSlider.userInteractionEnabled = NO;
    @autoreleasepool {
        NSError* error;
        [self.notification approveWithError:&error];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissNotification {
    @autoreleasepool {
        NSError* error;
        [self.notification denyWithError:&error];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end