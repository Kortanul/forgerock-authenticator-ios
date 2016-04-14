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
#import "FRAAccountTableViewCell.h"
#import "FRAAccountTableViewController.h"
#import "FRABlockAlertView.h"
#import "FRAIdentity.h"
#import "FRAIdentityDatabase.h"

@implementation FRAAccountsTableViewController;

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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
        controller.identity = [self identityAtIndexPath:indexPath];
    }
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Present accounts as a flat list not broken down into sections
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_database identities].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"AccountCell";
    FRAAccountTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    [cell updateForModelObject:[self identityAtIndexPath:indexPath]];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {

        FRAIdentity* identity = [self identityAtIndexPath:indexPath];
        FRABlockAlertView* alertView = [[FRABlockAlertView alloc]
                                        initWithTitle:@"Removing this account will NOT turn off 2-step verification"
                                        message:[NSString stringWithFormat:@"This may prevent you from logging into your %@ account.", identity.issuer]
                                        delegate:nil
                                        cancelButtonTitle:@"Cancel"
                                        otherButtonTitles:@"Delete", nil];
        alertView.callback = ^(NSInteger offset) {
            if (offset == 0) {
                [_database removeIdentityWithId:identity.uid];
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        };
        [alertView show];
    }
}

#pragma mark -
#pragma mark UITableViewDelegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Only offer delete option when in edit mode (disables swipe to delete)
    if (self.tableView.editing) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
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

#pragma mark -
#pragma mark FRAAccountsTableViewController (private)

- (FRAIdentity *)identityAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *sortedIdentities = [[_database identities] sortedArrayUsingComparator:^NSComparisonResult(FRAIdentity* first, FRAIdentity* second) {
        NSComparisonResult comparisonResult = [first.issuer caseInsensitiveCompare:second.issuer];
        if (comparisonResult == NSOrderedSame) {
            comparisonResult = [first.accountName caseInsensitiveCompare:second.accountName];
        }
        return comparisonResult;
    }];
    return [sortedIdentities objectAtIndex:indexPath.row];
}

@end
