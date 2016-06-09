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

#import <XCTest/XCTest.h>

#import "FRAHotpOathMechanism.h"
#import "FRAIdentityModel.h"
#import "FRAOathMechanismFactory.h"
#import "FRAPushMechanism.h"
#import "FRAPushMechanismFactory.h"
#import "FRATotpOathMechanism.h"
#import "FRAUriMechanismReader.h"

@interface FRAUriMechanismReaderTests : XCTestCase

@end

@implementation FRAUriMechanismReaderTests {
    FRAIdentityModel *identityModel;
    FRAUriMechanismReader *reader;
}

- (void)setUp {
    [super setUp];
    identityModel = [[FRAIdentityModel alloc] initWithDatabase:nil sqlDatabase:nil];
    reader = [[FRAUriMechanismReader alloc] initWithDatabase:nil identityModel:identityModel];
    FRAPushMechanismFactory *pushMechanismFactory = [[FRAPushMechanismFactory alloc] initWithGateway:nil];
    FRAOathMechanismFactory *oathMechanismFactory = [[FRAOathMechanismFactory alloc] init];
    [reader addMechanismFactory:pushMechanismFactory];
    [reader addMechanismFactory:oathMechanismFactory];
}

- (void)testReaderCanParsePushMechanism {
    NSURL *qrUrl = [NSURL URLWithString:@"pushauth://push/forgerock:demo3?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMT1hbWxiY29va2ll&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=ForgeRock"];
    
    FRAPushMechanism *mechanism = (FRAPushMechanism *)[reader parseFromURL:qrUrl error:nil];
    
    XCTAssertNotNil(mechanism);
    XCTAssertEqual([mechanism class], [FRAPushMechanism class]);
}

- (void)testReaderCanParseHotpOathMechanism {
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://hotp/Forgerock:demo?secret=IJQWIZ3FOIQUEYLE&issuer=Forgerock&counter=0"];
    
    FRAHotpOathMechanism *mechanism = (FRAHotpOathMechanism *)[reader parseFromURL:qrUrl error:nil];
    
    XCTAssertNotNil(mechanism);
    XCTAssertEqual([mechanism class], [FRAHotpOathMechanism class]);
}

- (void)testReaderCanParseTotpOathMechanism {
    NSURL *qrUrl = [NSURL URLWithString:@"otpauth://totp/ForgeRock:demo?secret=EE3PFF5BM6GHVRNZIBBQWBNRLQ======&issuer=ForgeRock&digits=8&period=30"];
    
    FRATotpOathMechanism *mechanism = (FRATotpOathMechanism *)[reader parseFromURL:qrUrl error:nil];
    
    XCTAssertNotNil(mechanism);
    XCTAssertEqual([mechanism class], [FRATotpOathMechanism class]);
}

@end