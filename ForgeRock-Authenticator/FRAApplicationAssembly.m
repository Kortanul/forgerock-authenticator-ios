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

#import "FRAAccountsTableViewController.h"
#import "FRAAccountTableViewController.h"
#import "FRAApplicationAssembly.h"
#import "FRAIdentityDatabase.h"
#import "FRAQRScanViewController.h"

@implementation FRAApplicationAssembly

- (FRAAccountsTableViewController *)accountsTableViewController {
    return [TyphoonDefinition withClass:[FRAAccountsTableViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition injectProperty:@selector(database) with:[self identityDatabase]];
    }];
}

- (FRAAccountTableViewController *)accountTableViewController {
    return [TyphoonDefinition withClass:[FRAAccountTableViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition injectProperty:@selector(database) with:[self identityDatabase]];
    }];
}

- (FRAQRScanViewController *)qrScanViewController {
    return [TyphoonDefinition withClass:[FRAQRScanViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition injectProperty:@selector(database) with:[self identityDatabase]];
    }];
}

- (FRAIdentityDatabase *)identityDatabase {
    return [TyphoonDefinition withClass:[FRAIdentityDatabase class] configuration:^(TyphoonDefinition *definition) {
        definition.scope = TyphoonScopeSingleton;
    }];
}

@end
