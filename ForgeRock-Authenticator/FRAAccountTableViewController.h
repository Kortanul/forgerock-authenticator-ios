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

#import "FRAIdentity.h"
#import "FRAIdentityDatabase.h"
#import "FRAIdentityModel.h"
#import "FRAOathMechanismTableViewCell.h"
#import "FRAPushMechanismTableViewCell.h"

/*! The storyboard identifier assigned to this view controller. */
extern NSString * const FRAAccountTableViewControllerStoryboardIdentifer;
/*! The storyboard identifier for the segue from FRAAccountTableViewController to FRANotificationsTableViewController. */
extern NSString * const FRAAccountTableViewControllerShowNotificationsSegue;

/*!
 * Controller for the table-view showing an individual Account.
 */
@interface FRAAccountTableViewController : UITableViewController

/*!
 * The identity displayed by this view controller.
 */
@property (nonatomic) FRAIdentity *identity;
/*!
 * The identity model to which the identity is stored.
 */
@property (nonatomic) FRAIdentityModel *identityModel;
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
 * The static table-view cell in which the OATH mechanism is presented.
 */
@property (weak, nonatomic) IBOutlet FRAOathMechanismTableViewCell *oathTableViewCell;
/*!
 * The static table-view cell in which the Push mechanism is presented.
 */
@property (weak, nonatomic) IBOutlet FRAPushMechanismTableViewCell *pushTableViewCell;

@end
