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


#import "FRAIdentity.h"
#import "M13BadgeView.h"

/*!
 * Custom UITableViewCell for Accounts UITableView.
 */
@interface FRAAccountTableViewCell : UITableViewCell

/*!
 * The UIImageView in which the issuer's icon will be displayed.
 */
@property (weak, nonatomic) IBOutlet UIImageView *image;
/*!
 * The UILabel in which the issuer's name will be displayed.
 */
@property (weak, nonatomic) IBOutlet UILabel *issuer;
/*!
 * The UILabel in which the accoutn name will be displayed.
 */
@property (weak, nonatomic) IBOutlet UILabel *accountName;
/*!
 * The UIImageView in which the first registered mechanism's icon will be displayed.
 */
@property (weak, nonatomic) IBOutlet UIImageView *firstMechanismIcon;
/*!
 * The UIImageView in which the second registered mechanism's icon will be displayed.
 */
@property (weak, nonatomic) IBOutlet UIImageView *secondMechanismIcon;
/*!
 * The M13BadgeView in which the pending notifications count is displayed.
 * This view is added as a superscript view to whichever mechanism icon is displaying the notifications icon.
 */
@property (nonatomic, retain) M13BadgeView *notificationsBadge;

@end
