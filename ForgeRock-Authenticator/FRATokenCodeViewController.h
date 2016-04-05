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

#import <Foundation/Foundation.h>
#import "FRAOathMechanism.h"
#import "FRACircleProgressView.h"

@class FRATokenCodeViewController;

/*!
 * Abstraction that allows FRATokenCodeViewController to operate FRATokensTableViewCell and FRAAccountTokenTableViewCell.
 */
@protocol FRATokenCodeView <NSObject>

/*!
 * The mechanism shown by this cell.
 */
@property (weak, nonatomic) FRAOathMechanism* mechanism;
/*!
 * The delegate that acts as controller for this cell's UI elements relating to the OATH code value.
 */
@property (strong, nonatomic) FRATokenCodeViewController* delegate;

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


/*!
 * Controller for OATH code displayed in table cell of Tokens tab table view and on Account screen.
 */
@interface FRATokenCodeViewController : NSObject

/*!
 * The model.
 */
@property (weak, nonatomic) FRAOathMechanism* mechanism;
/*!
 * The view.
 */
@property (weak, nonatomic) id<FRATokenCodeView> view;
/*!
 * Flag to be set by the owning UITableViewController when entering/exiting edit mode.
 */
@property(nonatomic, getter=isEditing) BOOL editing;

/*!
 * Creates a new object with the provided property values.
 */
+ (instancetype)controllerForView:(id<FRATokenCodeView>)view withMechanism:(FRAOathMechanism*)mechanism;
/*!
 * Creates a new object with the provided property values.
 */
- (instancetype)initForView:(id<FRATokenCodeView>)view withMechanism:(FRAOathMechanism*)mechanism;

/*!
 * Callback for generating first HOTP code, or copying existing HOTP or TOTP code to the clipboard.
 */
- (void)didTouchUpInside;

/*!
 * Callback for generating the next HOTP code (when refresh icon is touched).
 */
- (void)generateNextCode;

@end
