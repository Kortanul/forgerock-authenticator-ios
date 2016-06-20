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

#import <OCMock/OCMock.h>

#import "FRAHotpOathMechanism.h"
#import "FRAIdentityDatabase.h"
#import "FRAIdentityDatabaseSQLiteOperations.h"
#import "FRAIdentityModel.h"
#import "FRAModelUtils.h"
#import "FRAOathMechanismFactory.h"
#import "FRAUriMechanismReader.h"

@implementation FRAModelUtils {
    FRAUriMechanismReader *reader;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        id mockDatabaseOperations = OCMClassMock([FRAIdentityDatabaseSQLiteOperations class]);
        OCMStub([mockDatabaseOperations insertIdentity:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(YES);
        OCMStub([mockDatabaseOperations insertMechanism:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(YES);
        FRAIdentityDatabase *identityDatabase = [[FRAIdentityDatabase alloc] initWithSqlOperations:mockDatabaseOperations];
        FRAIdentityModel *identityModel = [[FRAIdentityModel alloc] initWithDatabase:identityDatabase sqlDatabase:nil];
        reader = [[FRAUriMechanismReader alloc] initWithDatabase:identityDatabase identityModel:identityModel];
        [reader addMechanismFactory:[[FRAOathMechanismFactory alloc] init]];
    }
    return self;
}

- (FRAHotpOathMechanism *)demoOathMechanism {
    NSString *qrString = @"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0";
    return (FRAHotpOathMechanism *)[reader parseFromString:qrString handler:nil error:nil];
}

@end
