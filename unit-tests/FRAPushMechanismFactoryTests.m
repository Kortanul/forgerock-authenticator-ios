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
#import "FRAidentity.h"
#import "FRAMessageUtils.h"
#import "FRAPushMechanism.h"
#import "FRAPushMechanismFactory.h"

static NSInteger const RESPOND_WITH_ENDPOINT_HANDLER_CALLBACK_PARAMETER_INDEX = 7;
static NSString * const DEVICE_ID = @"device id";

@interface FRAPushMechanismFactoryTests : XCTestCase

@end

@implementation FRAPushMechanismFactoryTests {
    FRAIdentityModel *identityModel;
    FRAPushMechanismFactory *factory;
    id mockMessageUtils;
    id mockGateway;
}

- (void)setUp {
    [super setUp];
    mockMessageUtils = OCMClassMock([FRAMessageUtils class]);
    mockGateway = OCMClassMock([FRANotificationGateway class]);
    OCMStub(((FRANotificationGateway *)mockGateway).deviceToken).andReturn(DEVICE_ID);
    identityModel = [[FRAIdentityModel alloc] initWithDatabase:nil sqlDatabase:nil];
    factory = [[FRAPushMechanismFactory alloc] initWithGateway:mockGateway];
}

- (void)tearDown {
    [mockMessageUtils stopMocking];
    [mockGateway stopMocking];
    [super tearDown];
}

- (void)testParseSetsImageUrlOnIdentity {
    OCMStub([mockMessageUtils respondWithEndpoint:[OCMArg any]
                                     base64Secret:[OCMArg any]
                                        messageId:[OCMArg any]
                           loadBalancerCookieData:[OCMArg any]
                                             data:[OCMArg any]
                                          handler:[OCMArg any]]);
    NSURL *qrUrl = [NSURL URLWithString:@"pushauth://push/forgerock:demo3?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr"];
    
    FRAPushMechanism *mechanism = (FRAPushMechanism *)[factory buildMechanism:qrUrl database:nil identityModel:identityModel error:nil];
    
    FRAIdentity *identity = mechanism.parent;
    XCTAssertEqualObjects([identity.image absoluteString], @"http://seattlewriter.com/wp-content/uploads/2013/01/weight-watchers-small.gif");
}

- (void)testMechanismIsRemovedIfFailedToRespond {
    OCMStub([mockMessageUtils respondWithEndpoint:[OCMArg any]
                                     base64Secret:[OCMArg any]
                                        messageId:[OCMArg any]
                           loadBalancerCookieData:[OCMArg any]
                                             data:[OCMArg any]
                                          handler:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        void (^callback)(NSInteger, NSError *);
        [invocation getArgument:&callback atIndex:RESPOND_WITH_ENDPOINT_HANDLER_CALLBACK_PARAMETER_INDEX];
        
        callback(404, nil);
    });
    NSURL *qrUrl = [NSURL URLWithString:@"pushauth://push/forgerock:demo3?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr"];
    
    FRAPushMechanism *mechanism = (FRAPushMechanism *)[factory buildMechanism:qrUrl database:nil identityModel:identityModel error:nil];
    
    XCTAssertNil([identityModel mechanismWithId:mechanism.mechanismUID]);
}

- (void)testIdentityIsRemovedIfFailedToRespondAndIdentityHasNoOtherMechanism {
    OCMStub([mockMessageUtils respondWithEndpoint:[OCMArg any]
                                     base64Secret:[OCMArg any]
                                        messageId:[OCMArg any]
                           loadBalancerCookieData:[OCMArg any]
                                             data:[OCMArg any]
                                          handler:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        void (^callback)(NSInteger, NSError *);
        [invocation getArgument:&callback atIndex:RESPOND_WITH_ENDPOINT_HANDLER_CALLBACK_PARAMETER_INDEX];
        
        callback(404, nil);
    });
    NSURL *qrUrl = [NSURL URLWithString:@"pushauth://push/forgerock:demo3?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr"];
    
    [factory buildMechanism:qrUrl database:nil identityModel:identityModel error:nil];
    
    XCTAssertNil([identityModel identityWithIssuer:@"ForgeRock" accountName:@"demo3"]);
}

- (void)testIdentityIsNotRemovedIfFailedToRespondButIdentityHasOtherMechanisms {
    OCMExpect([mockMessageUtils respondWithEndpoint:[OCMArg any]
                                       base64Secret:[OCMArg any]
                                          messageId:[OCMArg any]
                             loadBalancerCookieData:[OCMArg any]
                                               data:[OCMArg any]
                                            handler:[OCMArg any]]);
    NSURL *successfulQr = [NSURL URLWithString:@"pushauth://push/forgerock:demo3?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI&s=dGhlbGVnZW5kb2ZsdW5h=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=0efccfa7-c4ac-4fa4-99ef-b425027f03f7&issuer=Rm9yZ2Vyb2Nr"];
    [factory buildMechanism:successfulQr database:nil identityModel:identityModel error:nil];
    
    OCMExpect([mockMessageUtils respondWithEndpoint:[OCMArg any]
                                       base64Secret:[OCMArg any]
                                          messageId:[OCMArg any]
                             loadBalancerCookieData:[OCMArg any]
                                               data:[OCMArg any]
                                            handler:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        void (^callback)(NSInteger, NSError *);
        [invocation getArgument:&callback atIndex:RESPOND_WITH_ENDPOINT_HANDLER_CALLBACK_PARAMETER_INDEX];
        
        callback(404, nil);
    });
    NSURL *unsuccessfulQr = [NSURL URLWithString:@"pushauth://push/forgerock:demo3?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr"];
    [factory buildMechanism:unsuccessfulQr database:nil identityModel:identityModel error:nil];
    
    XCTAssertNotNil([identityModel identityWithIssuer:@"Forgerock" accountName:@"demo3"]);
}

- (void)testBuildMechanismReturnsNilIfDuplicate {
    OCMStub([mockMessageUtils respondWithEndpoint:[OCMArg any]
                                     base64Secret:[OCMArg any]
                                        messageId:[OCMArg any]
                           loadBalancerCookieData:[OCMArg any]
                                             data:[OCMArg any]
                                          handler:[OCMArg any]]);
    NSURL *qrUrl = [NSURL URLWithString:@"pushauth://push/forgerock:demo3?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMT1hbWxiY29va2ll&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr"];
    [factory buildMechanism:qrUrl database:nil identityModel:identityModel error:nil];
    
    NSError *error;
    FRAMechanism *duplicateMechanism = [factory buildMechanism:qrUrl database:nil identityModel:identityModel error:&error];
    
    XCTAssertNil(duplicateMechanism);
    XCTAssertEqual(error.code, FRADuplicateMechanism);
}

- (void)testBuildMechanismReturnsNilIfNoDeviceId {
    id gateway = OCMClassMock([FRANotificationGateway class]);
    OCMStub(((FRANotificationGateway *)gateway).deviceToken).andReturn(@"");
    FRAPushMechanismFactory *mechanismFactory = [[FRAPushMechanismFactory alloc] initWithGateway:gateway];
    OCMStub([mockMessageUtils respondWithEndpoint:[OCMArg any]
                                     base64Secret:[OCMArg any]
                                        messageId:[OCMArg any]
                           loadBalancerCookieData:[OCMArg any]
                                             data:[OCMArg any]
                                          handler:[OCMArg any]]);
    NSURL *qrUrl = [NSURL URLWithString:@"pushauth://push/forgerock:demo3?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMT1hbWxiY29va2ll&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr"];

    NSError *error;
    FRAMechanism *mechanism = [mechanismFactory buildMechanism:qrUrl database:nil identityModel:identityModel error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAMissingDeviceId);
}

- (void)testBuildMechanismReturnsNilIfNoSecret {
    OCMStub([mockMessageUtils respondWithEndpoint:[OCMArg any]
                                     base64Secret:[OCMArg any]
                                        messageId:[OCMArg any]
                           loadBalancerCookieData:[OCMArg any]
                                             data:[OCMArg any]
                                          handler:[OCMArg any]]);
    NSURL *qrUrl = [NSURL URLWithString:@"pushauth://push/forgerock:demo3?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI&s=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr"];
    
    NSError *error;
    FRAPushMechanism *mechanism = (FRAPushMechanism *)[factory buildMechanism:qrUrl database:nil identityModel:identityModel error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAMissingMechanismInfo);
}

- (void)testBuildMechanismReturnsNilIfNoAuthEndpoint {
    OCMStub([mockMessageUtils respondWithEndpoint:[OCMArg any]
                                     base64Secret:[OCMArg any]
                                        messageId:[OCMArg any]
                           loadBalancerCookieData:[OCMArg any]
                                             data:[OCMArg any]
                                          handler:[OCMArg any]]);
    NSURL *qrUrl = [NSURL URLWithString:@"pushauth://push/forgerock:demo3?a=&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMT1hbWxiY29va2ll&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr"];
    
    NSError *error;
    FRAPushMechanism *mechanism = (FRAPushMechanism *)[factory buildMechanism:qrUrl database:nil identityModel:identityModel error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAMissingMechanismInfo);
}

- (void)testBuildMechanismReturnsNilIfNoRegEndpoint {
    OCMStub([mockMessageUtils respondWithEndpoint:[OCMArg any]
                                     base64Secret:[OCMArg any]
                                        messageId:[OCMArg any]
                           loadBalancerCookieData:[OCMArg any]
                                             data:[OCMArg any]
                                          handler:[OCMArg any]]);
    NSURL *qrUrl = [NSURL URLWithString:@"pushauth://push/forgerock:demo3?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMT1hbWxiY29va2ll&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr"];
    
    NSError *error;
    FRAPushMechanism *mechanism = (FRAPushMechanism *)[factory buildMechanism:qrUrl database:nil identityModel:identityModel error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAMissingMechanismInfo);
}

- (void)testBuildMechanismReturnsNilIfNoMessageId {
    OCMStub([mockMessageUtils respondWithEndpoint:[OCMArg any]
                                     base64Secret:[OCMArg any]
                                        messageId:[OCMArg any]
                           loadBalancerCookieData:[OCMArg any]
                                             data:[OCMArg any]
                                          handler:[OCMArg any]]);
    NSURL *qrUrl = [NSURL URLWithString:@"pushauth://push/forgerock:demo3?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMT1hbWxiY29va2ll&m=&issuer=Rm9yZ2Vyb2Nr"];
    
    NSError *error;
    FRAPushMechanism *mechanism = (FRAPushMechanism *)[factory buildMechanism:qrUrl database:nil identityModel:identityModel error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAMissingMechanismInfo);
}

- (void)testBuildMechanismReturnsNilIfNoChallenge {
    OCMStub([mockMessageUtils respondWithEndpoint:[OCMArg any]
                                     base64Secret:[OCMArg any]
                                        messageId:[OCMArg any]
                           loadBalancerCookieData:[OCMArg any]
                                             data:[OCMArg any]
                                          handler:[OCMArg any]]);
    NSURL *qrUrl = [NSURL URLWithString:@"pushauth://push/forgerock:demo3?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=&l=YW1sYmNvb2tpZT0wMT1hbWxiY29va2ll&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr"];
    
    NSError *error;
    FRAPushMechanism *mechanism = (FRAPushMechanism *)[factory buildMechanism:qrUrl database:nil identityModel:identityModel error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAMissingMechanismInfo);
}

- (void)testBuildMechanismReturnsNilIfNoIssuer {
    OCMStub([mockMessageUtils respondWithEndpoint:[OCMArg any]
                                     base64Secret:[OCMArg any]
                                        messageId:[OCMArg any]
                           loadBalancerCookieData:[OCMArg any]
                                             data:[OCMArg any]
                                          handler:[OCMArg any]]);
    NSURL *qrUrl = [NSURL URLWithString:@"pushauth://push/forgerock:demo3?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMT1hbWxiY29va2ll&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer="];
    
    NSError *error;
    FRAPushMechanism *mechanism = (FRAPushMechanism *)[factory buildMechanism:qrUrl database:nil identityModel:identityModel error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAMissingMechanismInfo);
}

@end