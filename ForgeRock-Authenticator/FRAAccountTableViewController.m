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

#import "FRAAccountTableViewController.h"
#import "FRAIdentityDatabase.h"
#import "FRAOathMechanism.h"
#import "FRAAccountSettingsTableViewController.h"

@interface FRAAccountTableViewController ()

- (BOOL)hasRegisteredOathMechanism;

@end

@implementation FRAAccountTableViewController {
    FRAIdentityDatabase* database;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    database = [FRAIdentityDatabase singleton];
    //  _image = ... // TODO: Use URLImageView
    _issuer.text = _identity.issuer;
    _accountName.text = _identity.accountName;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showAccountSettingsSegue"]) {
        FRAAccountSettingsTableViewController* controller = (FRAAccountSettingsTableViewController*)segue.destinationViewController;
        controller.identity = _identity;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == 0 && indexPath.row == 0) {
        // prevent "selection" of account header row
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else if (indexPath.section == 1 && indexPath.row == 0) {
        // prevent "selection" of grey spacer row
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if (cell == self.tokenTableViewCell && ![self hasRegisteredOathMechanism]) {
        return 0; // hide the cell if OATH mechanism not registered
    } else {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

- (BOOL)hasRegisteredOathMechanism {
    NSArray* mechanisms = [database mechanismsWithOwner:_identity];
    for (NSObject* mechanism in mechanisms) {
        if ([mechanism isKindOfClass:[FRAOathMechanism class]]) {
            return YES;
        }
    }
    return NO;
}


@end
