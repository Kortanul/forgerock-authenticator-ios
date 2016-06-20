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
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "FRAAccountsTableViewController.h"
#import "FRAAccountTableViewCell.h"
#import "FRAApplicationAssembly.h"
#import "FRAHotpOathMechanism.h"
#import "FRAIdentityModel.h"
#import "FRAIdentity.h"
#import "FRAModelsFromDatabase.h"
#import "FRAModelUtils.h"
#import "FRANotification.h"
#import "FRAPushMechanism.h"
#import "FRATotpOathMechanism.h"

@interface FRAAccountsTableViewControllerTests : XCTestCase

@end

@implementation FRAAccountsTableViewControllerTests {
    FRAAccountsTableViewController *accountsController;
    id mockIdentityModel;
    id mockModelsFromDatabase;
    FRAModelUtils *modelUtils;
}

- (void)setUp {
    [super setUp];
    
    mockModelsFromDatabase = OCMClassMock([FRAModelsFromDatabase class]);
    OCMStub([mockModelsFromDatabase allIdentitiesWithDatabase:[OCMArg any] identityDatabase:[OCMArg any] identityModel:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(@[]);
    
    // create a mock instance of the identity database
    mockIdentityModel = OCMClassMock([FRAIdentityModel class]);
    
    // patch Typhoon assembly to mock account controller database dependency
    FRAApplicationAssembly *assembly = (FRAApplicationAssembly *) [TyphoonComponentFactory defaultFactory];
    TyphoonPatcher *patcher = [[TyphoonPatcher alloc] init];
    [patcher patchDefinitionWithSelector:@selector(identityModel) withObject:^id{
        return mockIdentityModel;
    }];
    [assembly attachDefinitionPostProcessor:patcher];
    
    // load accounts controller from storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    accountsController = [storyboard instantiateViewControllerWithIdentifier:@"AccountsTableViewController"];
    [self simulateLoadingOfView];
    
    modelUtils = [[FRAModelUtils alloc] init];
    
}

- (void)tearDown {
    [self simulateUnloadingOfView];
    [mockIdentityModel stopMocking];
    [mockModelsFromDatabase stopMocking];
    [super tearDown];
}

- (void)simulateLoadingOfView {
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_8_4) {
        [accountsController view]; // force IBOutlets etc to be initialized
    } else {
        [accountsController loadViewIfNeeded]; // force IBOutlets etc to be initialized
    }
    XCTAssertNotNil(accountsController.view);
}

- (void)simulateUnloadingOfView {
    [accountsController viewWillDisappear:YES];
}

- (void)testHasNoCellsWhenDatabaseIsEmpty {
    // Given
    OCMStub([mockIdentityModel identities]).andReturn(@[]);
    
    // When
    NSInteger sections = [accountsController numberOfSectionsInTableView:accountsController.tableView];
    NSInteger rows = [accountsController tableView:accountsController.tableView numberOfRowsInSection:0];
    
    // Then
    XCTAssertEqual(sections, 1);
    XCTAssertEqual(rows, 0);
}

- (void)testHasOneCellPerDatabaseIdentitySortedByIssuerThenAccountName {
    // Given
    FRAIdentity *firstIdentity = [FRAIdentity identityWithDatabase:nil identityModel:mockIdentityModel accountName:@"Alice" issuer:@"Issuer_1" image:nil backgroundColor:nil];
    FRAIdentity *secondIdentity = [FRAIdentity identityWithDatabase:nil identityModel:mockIdentityModel accountName:@"Bob" issuer:@"Issuer_1" image:nil backgroundColor:nil];
    FRAIdentity *thirdIdentity = [FRAIdentity identityWithDatabase:nil identityModel:mockIdentityModel accountName:@"Alice" issuer:@"Issuer_2" image:nil backgroundColor:nil];
    NSArray *identities = @[secondIdentity, thirdIdentity, firstIdentity]; // NB. Identities aren't sorted
    OCMStub([mockIdentityModel identities]).andReturn(identities);
    
    // When
    NSInteger sections = [accountsController numberOfSectionsInTableView:accountsController.tableView];
    NSInteger rows = [accountsController tableView:accountsController.tableView numberOfRowsInSection:0];
    
    // Then
    XCTAssertEqual(sections, 1);
    XCTAssertEqual(rows, 3);
    [self assertCellForRow:0 isShowingIdentity:firstIdentity];
    [self assertCellForRow:1 isShowingIdentity:secondIdentity];
    [self assertCellForRow:2 isShowingIdentity:thirdIdentity];
}

- (void)testShowsNotificationIconWithBadgeForPushMechanism {
    // Given
    FRAIdentity *identity = [FRAIdentity identityWithDatabase:nil identityModel:nil accountName:@"Alice" issuer:@"Issuer" image:nil backgroundColor:nil];
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:nil identityModel:nil ];

    [pushMechanism addNotification:[self dummyNotification] error:nil];
    [pushMechanism addNotification:[self dummyNotification] error:nil];
    [identity addMechanism:pushMechanism error:nil];
    XCTAssertNotNil([identity mechanismOfClass:[FRAPushMechanism class]]);
    NSArray* identities = @[identity];
    OCMStub([mockIdentityModel identities]).andReturn(identities);
    
    // When
    FRAAccountTableViewCell *cell = [self cellForRow:0];
    
    // Then
    XCTAssertFalse(cell.firstMechanismIcon.hidden);
    XCTAssertTrue(cell.secondMechanismIcon.hidden);
    XCTAssertEqualObjects(cell.notificationsBadge.text, @"2");
}

- (void)testShowsTokenIconWithoutBadgeForOathMechanism {
    // Given
    FRAIdentity *identity = [FRAIdentity identityWithDatabase:nil
                                                identityModel:nil
                                                  accountName:@"Alice"
                                                       issuer:@"Issuer"
                                                        image:nil
                                              backgroundColor:nil];
    
    FRAHotpOathMechanism *mechanism = [modelUtils demoOathMechanism];
    [identity addMechanism:mechanism error:nil];
    XCTAssertNotNil([identity mechanismOfClass:[FRAHotpOathMechanism class]]);
    NSArray* identities = @[identity];
    OCMStub([mockIdentityModel identities]).andReturn(identities);
    
    // When
    FRAAccountTableViewCell *cell = [self cellForRow:0];
    
    // Then
    XCTAssertFalse(cell.firstMechanismIcon.hidden);
    XCTAssertTrue(cell.secondMechanismIcon.hidden);
    XCTAssertEqualObjects(cell.notificationsBadge.text, @"0");
    XCTAssertTrue(cell.notificationsBadge.hidesWhenZero);
}

- (void)testCanShowOathMechanismAndPushMechanism {
    // Given
    FRAIdentity *identity = [FRAIdentity identityWithDatabase:nil
                                                identityModel:nil
                                                  accountName:@"Alice"
                                                       issuer:@"Issuer"
                                                        image:nil
                                              backgroundColor:nil];
    FRAHotpOathMechanism *mechanism = [modelUtils demoOathMechanism];
    [identity addMechanism:mechanism error:nil];
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:nil identityModel:nil ];
    [pushMechanism addNotification:[self pendingNotification] error:nil];
    [identity addMechanism:pushMechanism error:nil];
    XCTAssertNotNil([identity mechanismOfClass:[FRAHotpOathMechanism class]]);
    XCTAssertNotNil([identity mechanismOfClass:[FRAPushMechanism class]]);
    NSArray* identities = @[identity];
    OCMStub([mockIdentityModel identities]).andReturn(identities);
    
    // When
    FRAAccountTableViewCell *cell = [self cellForRow:0];
    
    // Then
    XCTAssertFalse(cell.firstMechanismIcon.hidden);
    XCTAssertFalse(cell.secondMechanismIcon.hidden);
    XCTAssertEqualObjects(cell.notificationsBadge.text, @"1");
    XCTAssertTrue(cell.notificationsBadge.hidesWhenZero);
}

- (FRANotification *)dummyNotification {
    return [FRANotification notificationWithDatabase:nil
                                       identityModel:nil
                                           messageId:nil
                                           challenge:nil
                                        timeReceived:nil
                                          timeToLive:120.0
                              loadBalancerCookieData:nil];
}

- (FRANotification *)pendingNotification {
    return [FRANotification notificationWithDatabase:nil
                                       identityModel:nil
                                           messageId:@"dummy"
                                           challenge:@"dummy"
                                        timeReceived:[NSDate date]
                                          timeToLive:120.0
                              loadBalancerCookieData:nil];
}

- (FRAAccountTableViewCell *)cellForRow:(NSInteger)row {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    return (FRAAccountTableViewCell*) [accountsController tableView:accountsController.tableView cellForRowAtIndexPath:indexPath];
}

- (void)assertCellForRow:(NSInteger)row isShowingIdentity:(FRAIdentity*)identity {
    FRAAccountTableViewCell *cell = [self cellForRow:row];
    XCTAssertEqualObjects(identity.issuer, cell.issuer.text);
    XCTAssertEqualObjects(identity.accountName, cell.accountName.text);
}

@end
