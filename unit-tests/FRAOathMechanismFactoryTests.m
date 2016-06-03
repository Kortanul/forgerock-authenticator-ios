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
 * Copyright 2015-2016 ForgeRock AS.
 */

#import <XCTest/XCTest.h>

#import "FRAError.h"
#import "FRAOathMechanismFactory.h"

@interface FRAOathMechanismFactoryTests : XCTestCase

@end

@implementation FRAOathMechanismFactoryTests {
    FRAIdentityModel *identityModel;
    FRAOathMechanismFactory *factory;
}

- (void)setUp {
    [super setUp];
    identityModel = [[FRAIdentityModel alloc] initWithDatabase:nil sqlDatabase:nil];
    factory = [[FRAOathMechanismFactory alloc] init];
}

- (void)testBuildMechanismReturnsNilIfDuplicate {
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0&digits=8"];
    [factory buildMechanism:qrUrl database:nil identityModel:identityModel error:nil];
    
    NSError *error;
    FRAMechanism *duplicateMechanism = [factory buildMechanism:qrUrl database:nil identityModel:identityModel error:&error];
    
    XCTAssertNil(duplicateMechanism);
    XCTAssertEqual(error.code, FRADuplicateMechanism);
}

@end