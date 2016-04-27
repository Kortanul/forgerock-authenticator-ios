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
#import "FRAIdentityModel.h"
#import "FRAIdentity.h"
#import "FRANotification.h"
#import "FRAOathMechanism.h"
#import "FRAPushMechanism.h"

@interface FRAAccountsTableViewControllerTests : XCTestCase

@end

@implementation FRAAccountsTableViewControllerTests {

    FRAAccountsTableViewController *accountsController;
    FRAIdentityModel *mockIdentityModel;

}

- (void)setUp {
    [super setUp];
    
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
    accountsController = [storyboard instantiateViewControllerWithIdentifier:@"AccountsTableController"];
    [accountsController loadViewIfNeeded]; // force IBOutlets etc to be initialized
    XCTAssertNotNil(accountsController.view);
}

- (void)tearDown {
    [super tearDown];
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
    FRAIdentity *firstIdentity = [FRAIdentity identityWithDatabase:nil accountName:@"Alice" issuer:@"Issuer_1" image:nil];
    FRAIdentity *secondIdentity = [FRAIdentity identityWithDatabase:nil accountName:@"Bob" issuer:@"Issuer_1" image:nil];
    FRAIdentity *thirdIdentity = [FRAIdentity identityWithDatabase:nil accountName:@"Alice" issuer:@"Issuer_2" image:nil];
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
    FRAIdentity *identity = [FRAIdentity identityWithDatabase:nil accountName:@"Alice" issuer:@"Issuer" image:nil];
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:nil];
    [pushMechanism addNotification:[[FRANotification alloc] initWithDatabase:nil]];
    [pushMechanism addNotification:[[FRANotification alloc] initWithDatabase:nil]];
    [identity addMechanism:pushMechanism];
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

// FIXME: testShowsTokenIconWithoutBadgeForOathMechanism
//- (void)testShowsTokenIconWithoutBadgeForOathMechanism {
//    // Given
//    FRAIdentity *identity = [FRAIdentity identityWithDatabase:nil accountName:@"Alice" issuer:@"Issuer" image:nil];
//    FRAOathMechanism *oathMechanism = [[FRAOathMechanism alloc] init];
//    [identity addMechanism:oathMechanism];
//    XCTAssertNotNil([identity mechanismOfClass:[FRAOathMechanism class]]);
//    NSArray* identities = @[identity];
//    OCMStub([mockIdentityModel identities]).andReturn(identities);
//    
//    // When
//    FRAAccountTableViewCell *cell = [self cellForRow:0];
//    
//    // Then
//    XCTAssertFalse(cell.firstMechanismIcon.hidden);
//    XCTAssertTrue(cell.secondMechanismIcon.hidden);
//    XCTAssertEqualObjects(cell.notificationsBadge.text, @"0");
//    XCTAssertTrue(cell.notificationsBadge.hidesWhenZero);
//}

// FIXME: testCanShowOathMechanismAndPushMechanism
//- (void)testCanShowOathMechanismAndPushMechanism {
//    // Given
//    FRAIdentity *identity = [FRAIdentity identityWithDatabase:nil accountName:@"Alice" issuer:@"Issuer" image:nil];
//    FRAOathMechanism *oathMechanism = [[FRAOathMechanism alloc] init];
//    [identity addMechanism:oathMechanism];
//    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:nil];
//    [pushMechanism addNotification:[[FRANotification alloc] init]];
//    [identity addMechanism:pushMechanism];
//    XCTAssertNotNil([identity mechanismOfClass:[FRAOathMechanism class]]);
//    XCTAssertNotNil([identity mechanismOfClass:[FRAPushMechanism class]]);
//    NSArray* identities = @[identity];
//    OCMStub([mockIdentityModel identities]).andReturn(identities);
//    
//    // When
//    FRAAccountTableViewCell *cell = [self cellForRow:0];
//    
//    // Then
//    XCTAssertFalse(cell.firstMechanismIcon.hidden);
//    XCTAssertFalse(cell.secondMechanismIcon.hidden);
//    XCTAssertEqualObjects(cell.notificationsBadge.text, @"1");
//    XCTAssertTrue(cell.notificationsBadge.hidesWhenZero);
//}

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
