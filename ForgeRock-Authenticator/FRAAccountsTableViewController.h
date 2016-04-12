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



@class FRAIdentityModel;

/*! The storyboard identifier assigned to this view controller. */
extern NSString * const FRAAccountsTableViewControllerStoryboardIdentifer;
/*! The storyboard identifier for the segue from FRAAccountsTableViewController to FRAAccountTableViewController. */
extern NSString * const FRAAccountsTableViewControllerShowAccountSegue;
/*! The storyboard identifier for the segue from FRAAccountsTableViewController to FRAQRScanViewController. */
extern NSString * const FRAAccountsTableViewControllerScanQrCodeSegue;

/*!
 * Controller for Accounts table-view.
 */
@interface FRAAccountsTableViewController : UITableViewController

/*!
 * The identity model. Exposed to allow (setter) dependency injection.
 */
@property (nonatomic, strong) FRAIdentityModel *identityModel;

/*!
 * Timer for updating notifications count.
 */
@property (strong, nonatomic) NSTimer *timer;

@end
