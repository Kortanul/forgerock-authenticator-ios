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

#import "FRAIdentityDatabase.h"
#import "FRAIdentity.h"
#import "FRAIdentityModel.h"
#import "FRAPushMechanismFactory.h"
#import "FRAUriMechanismReader.h"

@interface FRAPushMechanismTests : XCTestCase

@end

@implementation FRAPushMechanismTests {
    FRAUriMechanismReader* factory;
    id mockDatabase;
    id mockIdentityModel;
}

- (void)setUp {
    [super setUp];
    mockDatabase = OCMClassMock([FRAIdentityDatabase class]);
    mockIdentityModel = OCMClassMock([FRAIdentityModel class]);
    factory = [[FRAUriMechanismReader alloc] initWithDatabase:mockDatabase identityModel:mockIdentityModel];
    [factory addMechanismFactory:[[FRAPushMechanismFactory alloc] init]];
}

- (void)testParseSetImageUrlOnIdentity {
    NSString* qrString = @"pushauth://push/forgerock:demo3?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMT1hbWxiY29va2ll&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=ForgeRock";
    
    FRAIdentity* identity = [[factory parseFromString:qrString] parent];
    
    XCTAssertEqualObjects([identity.image absoluteString], @"http://seattlewriter.com/wp-content/uploads/2013/01/weight-watchers-small.gif");
}

@end