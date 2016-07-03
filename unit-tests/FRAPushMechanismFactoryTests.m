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
#import "FRAIdentity.h"
#import "FRAIdentityDatabase.h"
#import "FRAIdentityDatabaseSQLiteOperations.h"
#import "FRAMessageUtils.h"
#import "FRAModelsFromDatabase.h"
#import "FRAPushMechanism.h"
#import "FRAPushMechanismFactory.h"

static NSInteger const RESPOND_WITH_ENDPOINT_HANDLER_CALLBACK_PARAMETER_INDEX = 7;
static NSString * const DEVICE_ID = @"device id";

@interface FRAPushMechanismFactoryTests : XCTestCase

@end

@implementation FRAPushMechanismFactoryTests {
    FRAIdentityDatabase *identityDatabase;
    FRAIdentityModel *identityModel;
    FRAPushMechanismFactory *factory;
    id mockMessageUtils;
    id mockGateway;
    id mockDatabaseOperations;
    id mockModelsFromDatabase;
}

- (void)setUp {
    [super setUp];
    mockModelsFromDatabase = OCMClassMock([FRAModelsFromDatabase class]);
    OCMStub([mockModelsFromDatabase allIdentitiesWithDatabase:[OCMArg any] identityDatabase:[OCMArg any] identityModel:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(@[]);
    mockMessageUtils = OCMClassMock([FRAMessageUtils class]);
    mockGateway = OCMClassMock([FRANotificationGateway class]);
    OCMStub(((FRANotificationGateway *)mockGateway).deviceToken).andReturn(DEVICE_ID);
    mockDatabaseOperations = OCMClassMock([FRAIdentityDatabaseSQLiteOperations class]);
    OCMStub([mockDatabaseOperations insertIdentity:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([mockDatabaseOperations insertMechanism:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(YES);
    identityDatabase = [[FRAIdentityDatabase alloc] initWithSqlOperations:mockDatabaseOperations];
    identityModel = [[FRAIdentityModel alloc] initWithDatabase:identityDatabase sqlDatabase:nil];
    factory = [[FRAPushMechanismFactory alloc] initWithGateway:mockGateway];
}

- (void)tearDown {
    [mockMessageUtils stopMocking];
    [mockGateway stopMocking];
    [mockDatabaseOperations stopMocking];
    [mockModelsFromDatabase stopMocking];
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
    
    FRAPushMechanism *mechanism = (FRAPushMechanism *)[factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:nil];
    
    FRAIdentity *identity = mechanism.parent;
    XCTAssertEqualObjects([identity.image absoluteString], @"http://seattlewriter.com/wp-content/uploads/2013/01/weight-watchers-small.gif");
}

- (void)testMechanismIsCreatedEvenIfImageIsMissing {
    OCMStub([mockMessageUtils respondWithEndpoint:[OCMArg any]
                                     base64Secret:[OCMArg any]
                                        messageId:[OCMArg any]
                           loadBalancerCookieData:[OCMArg any]
                                             data:[OCMArg any]
                                          handler:[OCMArg any]]);
    NSURL *qrUrl = [NSURL URLWithString:@"pushauth://push/forgerock:demo3?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr"];
    
    FRAPushMechanism *mechanism = (FRAPushMechanism *)[factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:nil];
    
    XCTAssertNotNil(mechanism);
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
    
    FRAPushMechanism *mechanism = (FRAPushMechanism *)[factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:nil];
    
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
    
    [factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:nil];
    
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
    [factory buildMechanism:successfulQr database:identityDatabase identityModel:identityModel handler:nil error:nil];
    
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
    [factory buildMechanism:unsuccessfulQr database:identityDatabase identityModel:identityModel handler:nil error:nil];
    
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
    [factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:nil];
    
    NSError *error;
    FRAMechanism *duplicateMechanism = [factory buildMechanism:qrUrl database:nil identityModel:identityModel handler:nil error:&error];
    
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
    FRAMechanism *mechanism = [mechanismFactory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:&error];
    
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
    FRAPushMechanism *mechanism = (FRAPushMechanism *)[factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAInvalidQRCode);
}

- (void)testBuildMechanismReturnsNilIfInvalidSecret {
    OCMStub([mockMessageUtils respondWithEndpoint:[OCMArg any]
                                     base64Secret:[OCMArg any]
                                        messageId:[OCMArg any]
                           loadBalancerCookieData:[OCMArg any]
                                             data:[OCMArg any]
                                          handler:[OCMArg any]]);
    NSURL *qrUrl = [NSURL URLWithString:@"pushauth://push/ForgeRock:Bob?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cHM6Ly91cGxvYWQud2lraW1lZGlhLm9yZy93aWtpcGVkaWEvY29tbW9ucy90aHVtYi81LzUzL0dvb2dsZV8lMjJHJTIyX0xvZ28uc3ZnLzEwMjRweC1Hb29nbGVfJTIyRyUyMl9Mb2dvLnN2Zy5wbmc&b=FF00FF&r=aHR0cDovL2V4YW1wbGUuY29t&s=bsrb4udv4zCZ%20T8oydh06YhVGmvBROSoR8vAJ4ZLjYl4&c=uu8HIjTm6tqzxw_pyhuDLtP38XxqBE0XmbMduJ4HmmU&l=YW1sYmNvb2tpZT0wMQ&m=49e99acb-1af1-467b-960b-ae4f4be6b8711467293481948&issuer=Rm9yZ2VSb2Nr"];
    
    NSError *error;
    FRAPushMechanism *mechanism = (FRAPushMechanism *)[factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAInvalidQRCode);
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
    FRAPushMechanism *mechanism = (FRAPushMechanism *)[factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAInvalidQRCode);
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
    FRAPushMechanism *mechanism = (FRAPushMechanism *)[factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAInvalidQRCode);
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
    FRAPushMechanism *mechanism = (FRAPushMechanism *)[factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAInvalidQRCode);
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
    FRAPushMechanism *mechanism = (FRAPushMechanism *)[factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAInvalidQRCode);
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
    FRAPushMechanism *mechanism = (FRAPushMechanism *)[factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:&error];
    
    XCTAssertNil(mechanism);
    XCTAssertEqual(error.code, FRAInvalidQRCode);
}

- (void)testErrorCodeIsSetToNetworkFailureIfCantContactServer {
    NSError *error = [[NSError alloc] init];
    OCMStub([mockMessageUtils respondWithEndpoint:[OCMArg any]
                                     base64Secret:[OCMArg any]
                                        messageId:[OCMArg any]
                           loadBalancerCookieData:[OCMArg any]
                                             data:[OCMArg any]
                                          handler:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        void (^callback)(NSInteger, NSError *);
        [invocation getArgument:&callback atIndex:RESPOND_WITH_ENDPOINT_HANDLER_CALLBACK_PARAMETER_INDEX];
        
        callback(404, error);
    });
    NSURL *qrUrl = [NSURL URLWithString:@"pushauth://push/forgerock:demo3?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr"];
    
    [factory buildMechanism:qrUrl
                   database:identityDatabase
              identityModel:identityModel
                    handler:^(BOOL result, NSError *error) {
                        XCTAssertEqual(error.code, FRANetworkFailure);
                        XCTAssertNotNil([error.userInfo valueForKey:NSUnderlyingErrorKey]);
                    }
                      error:nil];
}

- (void)testBuildMechanismReturnsNilIfCantSaveIdentityInDatabase {
    FRAIdentityDatabaseSQLiteOperations *databaseOperations = OCMClassMock([FRAIdentityDatabaseSQLiteOperations class]);
    OCMStub([databaseOperations insertIdentity:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(NO);
    identityDatabase = [[FRAIdentityDatabase alloc] initWithSqlOperations:databaseOperations];
    identityModel = [[FRAIdentityModel alloc] initWithDatabase:identityDatabase sqlDatabase:nil];
    OCMStub([mockMessageUtils respondWithEndpoint:[OCMArg any]
                                     base64Secret:[OCMArg any]
                                        messageId:[OCMArg any]
                           loadBalancerCookieData:[OCMArg any]
                                             data:[OCMArg any]
                                          handler:[OCMArg any]]);
    NSURL *qrUrl = [NSURL URLWithString:@"pushauth://push/forgerock:demo3?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMT1hbWxiY29va2ll&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr"];
    
    FRAPushMechanism *mechanism = (FRAPushMechanism *)[factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:nil];
    
    XCTAssertNil(mechanism);
}

- (void)testBuildMechanismReturnsNilIfCantSaveMechanismInDatabase {
    FRAIdentityDatabaseSQLiteOperations *databaseOperations = OCMClassMock([FRAIdentityDatabaseSQLiteOperations class]);
    OCMStub([databaseOperations insertIdentity:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([databaseOperations insertMechanism:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(NO);
    identityDatabase = [[FRAIdentityDatabase alloc] initWithSqlOperations:databaseOperations];
    identityModel = [[FRAIdentityModel alloc] initWithDatabase:identityDatabase sqlDatabase:nil];
    OCMStub([mockMessageUtils respondWithEndpoint:[OCMArg any]
                                     base64Secret:[OCMArg any]
                                        messageId:[OCMArg any]
                           loadBalancerCookieData:[OCMArg any]
                                             data:[OCMArg any]
                                          handler:[OCMArg any]]);
    NSURL *qrUrl = [NSURL URLWithString:@"pushauth://push/forgerock:demo3?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI&s=dA18Iph3slIUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMT1hbWxiY29va2ll&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr"];

    FRAPushMechanism *mechanism = (FRAPushMechanism *)[factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:nil];
    
    XCTAssertNil(mechanism);
}

- (void)testBuildMechanismWhenSecretHasUrlEncodedCharactersCreatesMechanism {
    OCMStub([mockMessageUtils respondWithEndpoint:[OCMArg any]
                                     base64Secret:[OCMArg any]
                                        messageId:[OCMArg any]
                           loadBalancerCookieData:[OCMArg any]
                                             data:[OCMArg any]
                                          handler:[OCMArg any]]);
    NSURL *qrUrl = [NSURL URLWithString:@"pushauth://push/forgerock:demo3?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI&s=dA18Iph3sl_IUDVuRc5+3y7nv9NLGnPksH66d3jIF6uE=&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMQ==&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr"];
    
    FRAPushMechanism *mechanism = (FRAPushMechanism *)[factory buildMechanism:qrUrl database:identityDatabase identityModel:identityModel handler:nil error:nil];
    
    XCTAssertNotNil(mechanism);
}

@end