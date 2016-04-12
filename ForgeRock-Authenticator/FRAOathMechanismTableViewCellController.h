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



#import "FRAOathMechanism.h"
@class FRAOathMechanismTableViewCell;

/*!
 * Controller for OATH code displayed in table cell on Account screen.
 */
@interface FRAOathMechanismTableViewCellController : UIViewController

/*!
 * The model.
 */
@property (weak, nonatomic) FRAOathMechanism *mechanism;
/*!
 * The view.
 */
@property (weak, nonatomic) FRAOathMechanismTableViewCell *tableViewCell;

/*!
 * Creates a new object with the provided property values.
 */
- (instancetype)initWithView:(FRAOathMechanismTableViewCell *)view mechanism:(FRAOathMechanism *)mechanism;

/*!
 * Creates a new object with the provided property values.
 */
+ (instancetype)controllerWithView:(FRAOathMechanismTableViewCell *)view mechanism:(FRAOathMechanism *)mechanism;

/*!
 * Updates UI from latest mechanism state.
 */
- (void)reloadData;

/*!
 * Callback for generating first HOTP code, or copying existing HOTP or TOTP code to the clipboard.
 */
- (void)didTouchUpInside;

/*!
 * Callback for generating the next HOTP code (when refresh icon is touched).
 */
- (void)generateNextCode;

@end
