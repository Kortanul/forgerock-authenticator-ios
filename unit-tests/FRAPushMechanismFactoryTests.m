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
#import <OCMock/OCMock.h>

#import "FRAError.h"
#import "FRAMessageUtils.h"
#import "FRAPushMechanismFactory.h"

@interface FRAPushMechanismFactoryTests : XCTestCase

@end

@implementation FRAPushMechanismFactoryTests {
    FRAIdentityModel *identityModel;
    FRAPushMechanismFactory *factory;
    id mockMessageUtils;
}

- (void)setUp {
    [super setUp];
    mockMessageUtils = OCMClassMock([FRAMessageUtils class]);
    identityModel = [[FRAIdentityModel alloc] initWithDatabase:nil sqlDatabase:nil];
    factory = [[FRAPushMechanismFactory alloc] initWithGateway:nil];
}

- (void)tearDown {
    [mockMessageUtils stopMocking];
    [super tearDown];
}

- (void)testBuildMechanismReturnsNilIfDuplicate {
    OCMStub([mockMessageUtils respondWithEndpoint:[OCMArg any]
                                     base64Secret:[OCMArg any]
                                        messageId:[OCMArg any]
                                             data:[OCMArg any]
                                          handler:[OCMArg any]]);
    NSURL *qrUrl = [NSURL URLWithString:@"pushauth://push/forgerock:demo3?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMT1hbWxiY29va2ll&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=ForgeRock"];
    [factory buildMechanism:qrUrl database:nil identityModel:identityModel error:nil];
    
    NSError *error;
    FRAMechanism *duplicateMechanism = [factory buildMechanism:qrUrl database:nil identityModel:identityModel error:&error];
    
    XCTAssertNil(duplicateMechanism);
    XCTAssertEqual(error.code, FRADuplicateMechanism);
}

@end