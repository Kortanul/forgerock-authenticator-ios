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



/*!
 * Custom UITableViewCell for Notifications tab UITableView.
 *
 * This class exists to allow easy access to the cell's UI elements.
 */
@interface FRANotificationTableViewCell : UITableViewCell

/*!
 * The UIImageView in which the notification issuer's icon will be displayed.
 */
@property (weak, nonatomic) IBOutlet UIImageView *image;
/*!
 * The UILabel in which the notification status will be displayed.
 */
@property (weak, nonatomic) IBOutlet UILabel *status;
/*!
 * The UILabel in which the notification time will be displayed.
 */
@property (weak, nonatomic) IBOutlet UILabel *time;

@end
