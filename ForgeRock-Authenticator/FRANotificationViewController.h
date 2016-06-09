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

#import "FRALAContextFactory.h"
#import "FRANotificationUISlider.h"

@class FRANotification;

/*! The storyboard identifier assigned to this view controller. */
extern NSString * const FRANotificationViewControllerStoryboardIdentifer;

/*!
 * Controller for Notification view.
 */
@interface FRANotificationViewController : UIViewController

/*!
 * The notification model. Exposed to allow (setter) dependency injection.
 */
@property (weak, nonatomic) FRANotification *notification;
/*!
 * Factory for LAContext objects used to perform Touch ID.
 */
@property (strong, nonatomic) FRALAContextFactory *authContextFactory;
/*!
 * The FRANotificationUISlider used to authorize the requested action.
 */
@property (weak, nonatomic) IBOutlet FRANotificationUISlider *authorizeSlider;
/*!
 * The UIButton used to deny the requested action.
 */
@property (weak, nonatomic) IBOutlet UIButton *denyButton;
/*!
 * The UIImageView in which the issuer's icon will be displayed.
 */
@property (weak, nonatomic) IBOutlet UIImageView *image;
/*!
 * The UILabel in which the notification message will be displayed.
 */
@property (weak, nonatomic) IBOutlet UILabel *message;
/*!
 * The UIView whose background color will be set to that of the issuer.
 */
@property (weak, nonatomic) IBOutlet UIView *backgroundView;

/*!
 * The callback used to check if the slider needs to be moved to the start of the track.
 */
- (IBAction)updateSliderPosition:(id)sender;

/*!
 * The callback used to permit the requested authorization requested.
 */
- (IBAction)authorize:(id)sender;

/*!
 * The callback used to deny the requested authorization requested.
 */
- (IBAction)dismiss:(id)sender;

@end
