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
#import "FRACircleProgressView.h"
#import "FRAIdentityDatabase.h"
#import "FRAOathMechanism.h"
@class FRAOathMechanismTableViewCell;

/*!
 * Controller for OATH code displayed in table cell on Account screen.
 */
@interface FRAOathMechanismTableViewController : NSObject

/*!
 * The database. Exposed to allow (setter) dependency injection.
 */
@property (nonatomic, strong) FRAIdentityDatabase* database;
/*!
 * The model.
 */
@property (weak, nonatomic) FRAOathMechanism* mechanism;
/*!
 * The view.
 */
@property (weak, nonatomic) FRAOathMechanismTableViewCell* view;
/*!
 * Flag to be set by the owning UITableViewController when entering/exiting edit mode.
 */
@property(nonatomic, getter=isEditing) BOOL editing;

/*!
 * Creates a new object with the provided property values.
 */
+ (instancetype)controllerForView:(FRAOathMechanismTableViewCell*)view withMechanism:(FRAOathMechanism*)mechanism withDatabase:(FRAIdentityDatabase*)database;
/*!
 * Creates a new object with the provided property values.
 */
- (instancetype)initForView:(FRAOathMechanismTableViewCell*)view withMechanism:(FRAOathMechanism*)mechanism withDatabase:(FRAIdentityDatabase*)database;

/*!
 * Callback for generating first HOTP code, or copying existing HOTP or TOTP code to the clipboard.
 */
- (void)didTouchUpInside;

/*!
 * Callback for generating the next HOTP code (when refresh icon is touched).
 */
- (void)generateNextCode;

@end
