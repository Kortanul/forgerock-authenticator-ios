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
#import "M13BadgeView.h"
#import "FRAIdentity.h"
#import "FRAIdentityDatabase.h"
#import "FRAIdentityModel.h"
#import "FRAOathMechanismTableViewCell.h"

/*!
 * Controller for the table-view showing an individual Account.
 */
@interface FRAAccountTableViewController : UITableViewController

/*!
 * The identity model. Exposed to allow (setter) dependency injection.
 */
@property (nonatomic, strong) FRAIdentityModel* identityModel;
/*!
 * The identity displayed by this view controller.
 */
@property (nonatomic) FRAIdentity* identity;
/*!
 * The UIImageView in which the issuer's icon will be displayed.
 */
@property (weak, nonatomic) IBOutlet UIImageView *image;
/*!
 * The UILabel in which the issuer's name will be displayed.
 */
@property (weak, nonatomic) IBOutlet UILabel *issuer;
/*!
 * The UILabel in which the account name will be displayed.
 */
@property (weak, nonatomic) IBOutlet UILabel *accountName;
/*!
 * The static table-view cell in which OATH tokens are presented.
 */
@property (weak, nonatomic) IBOutlet FRAOathMechanismTableViewCell *tokenTableViewCell;
/*!
 * The M13BadgeView in which the pending notifications count is displayed.
 */
@property (weak, nonatomic) IBOutlet M13BadgeView *notificationsBadge;

@end
