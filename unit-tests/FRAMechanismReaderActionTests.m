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
#import <XCTest/XCTest.h>

#import "FRABlockAlertView.h"
#import "FRAFMDatabaseConnectionHelper.h"
#import "FRAIdentity.h"
#import "FRAIdentityDatabase.h"
#import "FRAIdentityDatabaseSQLiteOperations.h"
#import "FRAMechanismReaderAction.h"
#import "FRAMessageUtils.h"
#import "FRAPushMechanism.h"
#import "FRAPushMechanismFactory.h"
#import "FRAUriMechanismReader.h"

static NSInteger const ALERT_HANDLER_CALLBACK_PARAMETER_INDEX = 7;
static NSInteger const ALERT_CANCEL_SELECTION = 1;
static NSInteger const ALERT_OK_SELECTION = 0;
static NSString * const DEVICE_ID = @"device id";

@interface FRAMechanismReaderActionTests : XCTestCase

@end

@implementation FRAMechanismReaderActionTests {
    id mockSQLiteOperations;
    id mockMessageUtils;
    id mockAlertView;
    id mockGateway;
    FRAIdentityDatabase *identityDatabase;
    FRAIdentityModel *identityModel;
    FRAUriMechanismReader *mechanismReader;
    FRAMechanismReaderAction *action;
}

- (void)setUp {
    [super setUp];
    mockMessageUtils = OCMClassMock([FRAMessageUtils class]);
    OCMStub([mockMessageUtils respondWithEndpoint:[OCMArg any]
                                     base64Secret:[OCMArg any]
                                        messageId:[OCMArg any]
                           loadBalancerCookieData:[OCMArg any]
                                             data:[OCMArg any]
                                          handler:[OCMArg any]]);
    mockSQLiteOperations = OCMClassMock([FRAIdentityDatabaseSQLiteOperations class]);
    OCMStub([mockSQLiteOperations insertIdentity:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([mockSQLiteOperations insertMechanism:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([mockSQLiteOperations deleteIdentity:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([mockSQLiteOperations deleteMechanism:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(YES);
    mockAlertView = OCMClassMock([FRABlockAlertView class]);
    OCMStub([mockAlertView alloc]).andReturn(mockAlertView);
    identityDatabase = [[FRAIdentityDatabase alloc] initWithSqlOperations:mockSQLiteOperations];
    identityModel = [[FRAIdentityModel alloc] initWithDatabase:identityDatabase sqlDatabase:nil];
    mechanismReader = [[FRAUriMechanismReader alloc] initWithDatabase:identityDatabase identityModel:identityModel];
    mockGateway = OCMClassMock([FRANotificationGateway class]);
    OCMStub(((FRANotificationGateway *)mockGateway).deviceToken).andReturn(DEVICE_ID);
    [mechanismReader addMechanismFactory:[[FRAPushMechanismFactory alloc] initWithGateway:mockGateway]];
    action = [[FRAMechanismReaderAction alloc] initWithMechanismReader:mechanismReader];
}

- (void)tearDown {
    [mockSQLiteOperations stopMocking];
    [mockMessageUtils stopMocking];
    [mockAlertView stopMocking];
    [mockGateway stopMocking];
    [super tearDown];
}

- (void)testReadAddsIdentityAndMechanismToIdentityModel {
    NSString *qrCode = @"pushauth://push/forgerock:demo3?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI&s=qrcodesecret&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMT1hbWxiY29va2ll&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr";
    
    @autoreleasepool {
        NSError *error;
        [action read:qrCode error:&error];
    }
    
    [self assertOnlyOneMechanismRegisteredWithSharedSecret:@"qrcodesecret"];
}

- (void)testReadDoesntAddMechanismIfDuplicateAndUserCancels {
    [self whenAttemptingToRegisterDuplicateMechanismUserChoosesToCancel:YES];
    
    [self attemptToRegisterDuplicateMechanism];
    
    [self assertOnlyOneMechanismRegisteredWithSharedSecret:@"firstcodesecret"];
}

- (void)testReadDoesntAddMechanismIfDuplicateAndUserAccepts {
    [self whenAttemptingToRegisterDuplicateMechanismUserChoosesToCancel:NO];
    
    [self attemptToRegisterDuplicateMechanism];
    
    [self assertOnlyOneMechanismRegisteredWithSharedSecret:@"secondcodesecret"];
}

- (void)whenAttemptingToRegisterDuplicateMechanismUserChoosesToCancel:(BOOL)cancel {
    OCMStub([mockAlertView initWithTitle:[OCMArg any] message:[OCMArg any] delegate:[OCMArg any] cancelButtonTitle:[OCMArg any] otherButtonTitle:[OCMArg any] handler:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        void (^callback)(NSInteger);
        [invocation getArgument:&callback atIndex:ALERT_HANDLER_CALLBACK_PARAMETER_INDEX];
        callback(cancel ? ALERT_CANCEL_SELECTION : ALERT_OK_SELECTION);
    });
}

- (void)attemptToRegisterDuplicateMechanism {
    NSString *firstCode = @"pushauth://push/forgerock:demo3?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI&s=firstcodesecret&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMT1hbWxiY29va2ll&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr";
    NSString *secondCode = @"pushauth://push/forgerock:demo3?a=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249YXV0aGVudGljYXRl&image=aHR0cDovL3NlYXR0bGV3cml0ZXIuY29tL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDEzLzAxL3dlaWdodC13YXRjaGVycy1zbWFsbC5naWY&b=ff00ff&r=aHR0cDovL2FtcWEtY2xvbmU2OS50ZXN0LmZvcmdlcm9jay5jb206ODA4MC9vcGVuYW0vanNvbi9wdXNoL3Nucy9tZXNzYWdlP19hY3Rpb249cmVnaXN0ZXI&s=secondcodesecret&c=Yf66ojm3Pm80PVvNpljTB6X9CUhgSJ0WZUzB4su3vCY=&l=YW1sYmNvb2tpZT0wMT1hbWxiY29va2ll&m=9326d19c-4d08-4538-8151-f8558e71475f1464361288472&issuer=Rm9yZ2Vyb2Nr";
    @autoreleasepool {
        NSError *error;
        [action read:firstCode error:&error];
        [action read:secondCode error:&error];
    }
}

- (void)assertOnlyOneMechanismRegisteredWithSharedSecret:(NSString *)sharedSecret {
    FRAIdentity *identity = [[identityModel identities] objectAtIndex:0];
    FRAPushMechanism *mechanism = (FRAPushMechanism *)[[identity mechanisms] objectAtIndex:0];
    XCTAssertEqual([identity mechanisms].count, 1);
    XCTAssertNotNil(identity);
    XCTAssertNotNil(mechanism);
    XCTAssertEqualObjects(mechanism.secret, sharedSecret);
}

@end