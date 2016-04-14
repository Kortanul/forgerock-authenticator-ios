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
#import "FRAIdentityDatabase.h"
#import "FRAIdentity.h"

@interface FRAAccountsTableViewControllerTests : XCTestCase

@end

@implementation FRAAccountsTableViewControllerTests

FRAAccountsTableViewController* accountsController;
FRAIdentityDatabase* mockIdentityDatabase;

- (void)setUp {
    [super setUp];
    
    // create a mock instance of the identity database
    mockIdentityDatabase = OCMClassMock([FRAIdentityDatabase class]);
    
    // patch Typhoon assembly to mock account controller database dependency
    FRAApplicationAssembly* assembly = (FRAApplicationAssembly*) [TyphoonComponentFactory defaultFactory];
    TyphoonPatcher* patcher = [[TyphoonPatcher alloc] init];
    [patcher patchDefinitionWithSelector:@selector(identityDatabase) withObject:^id{
        return mockIdentityDatabase;
    }];
    [assembly attachDefinitionPostProcessor:patcher];
    
    // load accounts controller from storyboard
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    accountsController = [storyboard instantiateViewControllerWithIdentifier:@"AccountsTableController"];
    [accountsController loadViewIfNeeded]; // force IBOutlets etc to be initialized
    XCTAssertNotNil(accountsController.view);
}

- (void)tearDown {
    [super tearDown];
}

- (void)testHasNoCellsWhenDatabaseIsEmpty {
    // Given
    OCMStub([mockIdentityDatabase identities]).andReturn(@[]);
    
    // When
    NSInteger sections = [accountsController numberOfSectionsInTableView:accountsController.tableView];
    NSInteger rows = [accountsController tableView:accountsController.tableView numberOfRowsInSection:0];
    
    // Then
    XCTAssertEqual(sections, 1);
    XCTAssertEqual(rows, 0);
}

- (void)testHasOneCellPerDatabaseIdentitySortedByIssuerThenAccountName {
    // Given
    FRAIdentity* firstIdentity = [FRAIdentity identityWithAccountName:@"Alice" issuedBy:@"Issuer_1" withImage:nil];
    FRAIdentity* secondIdentity = [FRAIdentity identityWithAccountName:@"Bob" issuedBy:@"Issuer_1" withImage:nil];
    FRAIdentity* thirdIdentity = [FRAIdentity identityWithAccountName:@"Alice" issuedBy:@"Issuer_2" withImage:nil];
    NSArray* identities = @[secondIdentity, thirdIdentity, firstIdentity]; // NB. Identities aren't sorted
    OCMStub([mockIdentityDatabase identities]).andReturn(identities);

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

- (FRAAccountTableViewCell*)cellForRow:(NSInteger)row {
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    return (FRAAccountTableViewCell*) [accountsController tableView:accountsController.tableView cellForRowAtIndexPath:indexPath];
}

- (void)assertCellForRow:(NSInteger)row isShowingIdentity:(FRAIdentity*)identity {
    FRAAccountTableViewCell* cell = [self cellForRow:row];
    XCTAssertEqualObjects(identity.issuer, cell.issuer.text);
    XCTAssertEqualObjects(identity.accountName, cell.accountName.text);
}

@end
