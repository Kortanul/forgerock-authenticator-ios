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

#import <Typhoon/Typhoon.h>

@class FRAAccountsTableViewController;
@class FRAFMDatabaseConnectionHelper;
@class FRAIdentityDatabase;
@class FRAIdentityDatabaseSQLiteOperations;
@class FRAIdentityModel;
@class FRALAContextFactory;
@class FRAMechanismReaderAction;
@class FRANotificationGateway;
@class FRANotificationHandler;
@class FRANotificationViewController;
@class FRAOathMechanismFactory;
@class FRAPushMechanismFactory;
@class FRAQRScanViewController;
@class FRAUriMechanismReader;

/*!
 * Typhoon dependency injection configuration.
 */
@interface FRAApplicationAssembly : TyphoonAssembly

- (FRAAccountsTableViewController *)accountsTableViewController;
- (FRALAContextFactory *)authContextFactory;
- (FRAFMDatabaseConnectionHelper *)databaseConnectionHelper;
- (FRAIdentityDatabase *)identityDatabase;
- (FRAIdentityDatabaseSQLiteOperations *)identityDatabaseSQLiteOperations;
- (FRAIdentityModel *)identityModel;
- (FRAMechanismReaderAction *)mechanismReaderAction;
- (FRANotificationHandler *)notificationHandler;
- (FRANotificationGateway *)notificationGateway;
- (FRANotificationViewController *)notificationViewController;
- (FRAOathMechanismFactory *)oathMechanismFactory;
- (FRAPushMechanismFactory *)pushMechanismFactory;
- (FRAQRScanViewController *)qrScanViewController;
- (FRAUriMechanismReader *)uriMechanismReader;

@end
