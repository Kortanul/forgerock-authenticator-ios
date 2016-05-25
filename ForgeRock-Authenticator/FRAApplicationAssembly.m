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
#import "FRADatabaseConfiguration.h"
#import "FRAFMDatabaseFactory.h"
#import "FRAIdentityDatabase.h"
#import "FRAIdentityDatabaseSQLiteOperations.h"
#import "FRAIdentityModel.h"
#import "FRAMessageUtils.h"
#import "FRANotificationGateway.h"
#import "FRANotificationHandler.h"
#import "FRAOathMechanismFactory.h"
#import "FRAPushMechanismFactory.h"
#import "FRAQRScanViewController.h"
#import "FRAFMDatabaseConnectionHelper.h"
#import "FRAUriMechanismReader.h"

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

- (FRAIdentityDatabaseSQLiteOperations *)identityDatabaseSQLiteOperations {
    return [TyphoonDefinition withClass:[FRAIdentityDatabaseSQLiteOperations class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithDatabase:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self databaseConnectionHelper]];
        }];

    }];
}

- (FRAIdentityModel *)identityModel {
    return [TyphoonDefinition withClass:[FRAIdentityModel class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithDatabase:sqlDatabase:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self identityDatabase]];
            [initializer injectParameterWith:[self databaseConnectionHelper]];
        }];
        definition.scope = TyphoonScopeSingleton;
    }];
}

- (FRAUriMechanismReader *)uriMechanismReader {
    return [TyphoonDefinition withClass:[FRAUriMechanismReader class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithDatabase:identityModel:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self identityDatabase]];
            [initializer injectParameterWith:[self identityModel]];
        }];
        [definition injectMethod:@selector(addMechanismFactory:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self oathMechanismFactory]];
        }];
        [definition injectMethod:@selector(addMechanismFactory:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self pushMechanismFactory]];
        }];
        definition.scope = TyphoonScopeSingleton;
    }];
}

- (FRAOathMechanismFactory *)oathMechanismFactory {
    return [TyphoonDefinition withClass:[FRAOathMechanismFactory class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(init)];
        definition.scope = TyphoonScopeSingleton;
    }];
}

- (FRAPushMechanismFactory *)pushMechanismFactory {
    return [TyphoonDefinition withClass:[FRAPushMechanismFactory class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithGateway:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self notificationGateway]];
        }];
        definition.scope = TyphoonScopeSingleton;
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
        [definition injectProperty:@selector(uriMechanismReader) with:[self uriMechanismReader]];
    }];
}

- (FRAFMDatabaseConnectionHelper *)databaseConnectionHelper {
    return [TyphoonDefinition withClass:[FRAFMDatabaseConnectionHelper class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithConfiguration:databaseFactory:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[[FRADatabaseConfiguration alloc] init]];
            [initializer injectParameterWith:[[FRAFMDatabaseFactory alloc] init]];
        }];
        definition.scope = TyphoonScopeSingleton;
    }];
}

@end
