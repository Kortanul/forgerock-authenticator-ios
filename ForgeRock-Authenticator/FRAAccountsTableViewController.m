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
#import "FRAAccountTableViewController.h"
#import "FRAAccountTableViewCell.h"
#import "FRAIdentityDatabase.h"
#import "FRAIdentity.h"

@interface FRAAccountsTableViewController ()

- (FRAIdentity *)identityForCell:(FRAAccountTableViewCell*)cell;

@end


@implementation FRAAccountsTableViewController {
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showAccountSegue"]) {
        FRAAccountTableViewController* controller = (FRAAccountTableViewController*)segue.destinationViewController;
        NSArray* selection = [self.tableView indexPathsForSelectedRows];
        NSIndexPath* indexPath = [selection objectAtIndex:0];
        FRAAccountTableViewCell* cell = (FRAAccountTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        controller.identity = [self identityForCell:cell];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Present accounts as a flat list not broken down into sections
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [database identities].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"AccountCell";
    FRAAccountTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    FRAIdentity* identity = (FRAIdentity*) [[database identities] objectAtIndex:indexPath.row];
    [cell updateForModelObject:identity];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Only offer delete option when in edit mode (disables swipe to delete)
    if (self.tableView.editing) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        FRAAccountTableViewCell* cell = (FRAAccountTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
        FRAIdentity* identity = [self identityForCell:cell];
        if (identity) {
            [database removeIdentityWithId:identity.uid];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
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

- (FRAIdentity *)identityForCell:(FRAAccountTableViewCell*)cell {
    if (cell == nil) {
        return nil;
    }
    return [database identityWithId:cell.identityId];
}

@end
