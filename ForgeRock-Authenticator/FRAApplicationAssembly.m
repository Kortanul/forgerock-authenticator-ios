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
#import "FRAIdentityDatabaseSQLiteOperations.h"
#import "FRAIdentityModel.h"
#import "FRAMechanismFactory.h"
#import "FRANotificationGateway.h"
#import "FRANotificationHandler.h"
#import "FRAQRScanViewController.h"

@implementation FRAApplicationAssembly

- (FRAAccountTableViewController *)accountTableViewController {
    return [TyphoonDefinition withClass:[FRAAccountTableViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition injectProperty:@selector(identityModel) with:[self identityModel]];
    }];
}

- (FRAAccountsTableViewController *)accountsTableViewController {
    return [TyphoonDefinition withClass:[FRAAccountsTableViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition injectProperty:@selector(identityModel) with:[self identityModel]];
    }];
}

- (FRAIdentityDatabase *)identityDatabase {
    return [TyphoonDefinition withClass:[FRAIdentityDatabase class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithSqlOperations:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self identityDatabaseSQLiteOperations]];
        }];
        definition.scope = TyphoonScopeSingleton;
    }];
}

- (FRAIdentityDatabase *)identityDatabaseSQLiteOperations {
    return [TyphoonDefinition withClass:[FRAIdentityDatabaseSQLiteOperations class] configuration:^(TyphoonDefinition *definition) {
        definition.scope = TyphoonScopeSingleton;
    }];
}

- (FRAIdentityModel *)identityModel {
    return [TyphoonDefinition withClass:[FRAIdentityModel class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithDatabase:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self identityDatabase]];
        }];
        definition.scope = TyphoonScopeSingleton;
    }];
}

- (FRAMechanismFactory *)mechanismFactory {
    return [TyphoonDefinition withClass:[FRAMechanismFactory class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithDatabase:identityModel:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self identityDatabase]];
            [initializer injectParameterWith:[self identityModel]];
        }];
    }];
}

- (FRANotificationGateway *)notificationGateway {
    return [TyphoonDefinition withClass:[FRANotificationGateway class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithHandler:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self notificationHandler]];
        }];
        definition.scope = TyphoonScopeSingleton;
    }];
}

- (FRANotificationHandler *)notificationHandler {
    return [TyphoonDefinition withClass:[FRANotificationHandler class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithDatabase:identityModel:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self identityDatabase]];
            [initializer injectParameterWith:[self identityModel]];
        }];
        definition.scope = TyphoonScopeSingleton;
    }];
}

- (FRAQRScanViewController *)qrScanViewController {
    return [TyphoonDefinition withClass:[FRAQRScanViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition injectProperty:@selector(mechanismFactory) with:[self mechanismFactory]];
    }];
}


@end
