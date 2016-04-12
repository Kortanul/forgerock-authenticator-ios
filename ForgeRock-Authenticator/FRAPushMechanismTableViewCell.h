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



#import "FRAPushMechanism.h"
#import "FRAPushMechanismTableViewCellController.h"
#import "M13BadgeView.h"

/*!
 * Custom UITableViewCell for Account screen token.
 */
@interface FRAPushMechanismTableViewCell : UITableViewCell

/*!
 * The delegate that acts as controller for this cell's UI elements.
 */
@property (strong, nonatomic) FRAPushMechanismTableViewCellController *delegate;

/*!
 * The M13BadgeView in which the pending notifications count is displayed.
 */
@property (weak, nonatomic) IBOutlet M13BadgeView *notificationsBadge;

@end
