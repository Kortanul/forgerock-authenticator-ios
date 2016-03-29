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

#import "FRAAccountsTableViewController.h"
#import "FRAAccountSettingsTableViewController.h"
#import "FRAAccountSettingTableViewCell.h"
#import "FRAIdentityDatabase.h"
#import "FRAOathMechanism.h"

@interface FRAAccountSettingsTableViewController ()

- (FRAOathMechanism *)mechanismForCell:(FRAAccountSettingTableViewCell*)cell;
- (void)returnToAccountsScreen;

@end

@implementation FRAAccountSettingsTableViewController {
    FRAIdentityDatabase* database;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    database = [FRAIdentityDatabase singleton];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Present mechanisms as a flat list not broken down into sections
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        // section showing list of mechanisms
        return [database mechanismsWithOwner:_identity].count;
    } else {
        // section showing delete button when in edit mode
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        // section showing list of mechanisms
        static NSString *CellIdentifier = @"AccountSettingCell";
        FRAAccountSettingTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        NSArray* mechanisms = [database mechanismsWithOwner:_identity];
        FRAOathMechanism* mechanism = (FRAOathMechanism*)[mechanisms objectAtIndex:indexPath.row];
        cell.mechanismId = mechanism.uid;
        if ([mechanism isKindOfClass:[FRAOathMechanism class]]) {
            cell.title.text = @"Tokens";
        } else {
            cell.title.text = @"Unknown";
        }
        return cell;
        
    } else {
        // section showing delete button when in edit mode
        static NSString *CellIdentifier = @"AccountRemovalCell";
        return [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 || self.tableView.editing) {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    } else {
        return 0;
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];

    // populate this array with the NSIndexPath's of the rows you want to add/remove
    NSMutableArray *indexPaths = [NSMutableArray new];
    [indexPaths addObject:[NSIndexPath indexPathForItem:0 inSection:1]];
    
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Only offer delete option when in edit mode (disables swipe to delete)
    if (indexPath.section == 0 && self.tableView.editing) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        FRAAccountSettingTableViewCell* cell = (FRAAccountSettingTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
        FRAOathMechanism* mechanism = [self mechanismForCell:cell];
        if (mechanism) {
            [database removeMechanismWithId:mechanism.uid];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            if (![database identityWithId:mechanism.owner.uid]) {
                // Go back to accounts screen if this was the last mechanism and the account has been removed
                [self returnToAccountsScreen];
            }
        }
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // make table cell separator lines full width (normally, they leave a ~10% gap at the left edge)
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

-(void)viewDidLayoutSubviews {
    // make table cell separator lines full width (normally, they leave a ~10% gap at the left edge)
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (FRAOathMechanism *)mechanismForCell:(FRAAccountSettingTableViewCell*)cell {
    if (cell == nil) {
        return nil;
    }
    return [database mechanismWithId:cell.mechanismId];
}

- (IBAction)deleteAccountPressed:(id)sender {
    [database removeIdentityWithId:_identity.uid];
    [self returnToAccountsScreen];
}

- (void)returnToAccountsScreen {
    NSMutableArray *allViewControllers = [NSMutableArray arrayWithArray:[self.navigationController viewControllers]];
    for (UIViewController *aViewController in allViewControllers) {
        if ([aViewController isKindOfClass:[FRAAccountsTableViewController class]]) {
            [self.navigationController popToViewController:aViewController animated:YES];
        }
    }
}


@end