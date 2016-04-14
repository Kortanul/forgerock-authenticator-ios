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

#import <UIKit/UIKit.h>
#import "FRACircleProgressView.h"
#import "FRAOathMechanism.h"
#import "FRAOathMechanismTableViewController.h"

/*!
 * Custom UITableViewCell for Account screen token.
 */
@interface FRAOathMechanismTableViewCell : UITableViewCell

/*!
 * The delegate that acts as controller for this cell's UI elements relating to the OATH code value.
 */
@property (strong, nonatomic) FRAOathMechanismTableViewController* delegate;

/*!
 * The UILabel in which the OTP code will be displayed.
 */
@property (weak, nonatomic) IBOutlet UILabel* code;
/*!
 * The FRACircleProgressView in which the TOTP code's time remaining will be displayed.
 */
@property (weak, nonatomic) IBOutlet FRACircleProgressView* totpCodeProgress;
/*!
 * The button for generating the next HOTP code.
 */
@property (weak, nonatomic) IBOutlet UIButton *hotpRefreshButton;

/*!
 * The hotpRefreshButton touch-up inside action handler.
 */
- (IBAction)generateNextCode:(id)sender;

@end
