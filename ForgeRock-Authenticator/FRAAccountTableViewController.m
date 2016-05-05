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
#import "FRABlockAlertView.h"
#import "FRAIdentityDatabase.h"
#import "FRANotificationsTableViewController.h"
#import "FRAOathMechanism.h"
#import "FRAOathMechanismTableViewCell.h"
#import "FRAOathMechanismTableViewCellController.h"
#import "FRAPushMechanism.h"

/*! row index of static cell defining UI for OATH mechanism (cell is hidden if no such mechanism is registered) */
static const NSInteger OATH_MECHANISM_ROW_INDEX = 1;
/*! row index of static cell defining UI for push mechanism (cell is hidden if no such mechanism is registered) */
static const NSInteger PUSH_MECHANISM_ROW_INDEX = 2;


@implementation FRAAccountTableViewController

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Show issuer logo in circle
    self.image.layer.cornerRadius = self.image.frame.size.width / 2;
    self.image.clipsToBounds = YES;
    
    // Bind identity model to UI
    //  _image = ... // TODO: Use UIImageView+AFNetworking category provided by AFNetworking
    self.issuer.text = self.identity.issuer;
    self.accountName.text = self.identity.accountName;
    
    if ([self identityHasOathMechanism]) {
        self.oathTableViewCell.delegate = [FRAOathMechanismTableViewCellController
                controllerWithView:self.oathTableViewCell mechanism:[self oathMechanism]];
    }
    
    if ([self identityHasPushMechanism]) {
        self.pushTableViewCell.delegate = [FRAPushMechanismTableViewCellController
                controllerWithView:self.pushTableViewCell mechanism:[self pushMechanism]];
    }
    [self reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
    [self.oathTableViewCell.delegate viewWillAppear:animated];
    [self.pushTableViewCell.delegate viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleIdentityDatabaseChanged:) name:FRAIdentityDatabaseChangedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.oathTableViewCell.delegate viewWillDisappear:animated];
    [self.pushTableViewCell.delegate viewWillDisappear:animated];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showNotificationsSegue"]) {
        FRANotificationsTableViewController *controller = (FRANotificationsTableViewController *)segue.destinationViewController;
        controller.pushMechanism = [self pushMechanism];
    }
}

#pragma mark -
#pragma mark UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    // only indent mechanisms when in edit mode as only mechanisms can be deleted
    return [self hasMechanismAtIndexPath:indexPath];
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

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (indexPath.row == OATH_MECHANISM_ROW_INDEX) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.oathTableViewCell.delegate didTouchUpInside];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Only offer delete option on mechanism rows when in edit mode (disables swipe to delete)
    if (self.tableView.editing && [self hasMechanismAtIndexPath:indexPath]) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == OATH_MECHANISM_ROW_INDEX && ![self identityHasOathMechanism]) {
        return 0; // hide the cell if OATH mechanism not registered
    } else if (indexPath.row == PUSH_MECHANISM_ROW_INDEX && ![self identityHasPushMechanism]) {
        return 0; // hide the cell if push mechanism not registered
    } else {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

#pragma mark -
#pragma mark UITableViewDataSource

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) {
        return;
    }
    
    FRAMechanism *mechanism = [self mechanismAtIndexPath:indexPath];
    
    if (mechanism) {
        FRABlockAlertView *alertView =
                [[FRABlockAlertView alloc]
                 initWithTitle:@"Removing this will NOT turn off 2-step verification"
                 message:[NSString stringWithFormat:@"This may prevent you from logging into your %@ account.", self.identity.issuer]
                 delegate:nil
                 cancelButtonTitle:@"Cancel"
                 otherButtonTitles:@"Delete", nil];
        alertView.callback = ^(NSInteger offset) {
            const NSInteger deleteButton = 0;
            if (offset == deleteButton) {
                [self deleteMechanism:mechanism];
            }
            [self setEditing:NO animated:YES];
        };
        [alertView show];
    }
}

#pragma mark -
#pragma mark FRAAccountTableViewController (private)

- (BOOL)hasMechanismAtIndexPath:(NSIndexPath*)indexPath {
    return indexPath.row == OATH_MECHANISM_ROW_INDEX || indexPath.row == PUSH_MECHANISM_ROW_INDEX;
}

- (BOOL)identityHasOathMechanism {
    return [self oathMechanism] != nil;
}

- (BOOL)identityHasPushMechanism {
    return [self pushMechanism] != nil;
}

- (FRAOathMechanism *)oathMechanism {
    return (FRAOathMechanism *)[self.identity mechanismOfClass:[FRAOathMechanism class]];
}

- (FRAPushMechanism *)pushMechanism {
    return (FRAPushMechanism *)[self.identity mechanismOfClass:[FRAPushMechanism class]];
}

- (FRAMechanism *)mechanismAtIndexPath:(NSIndexPath *)indexPath {
    FRAMechanism *mechanism = nil;
    if (indexPath.row == OATH_MECHANISM_ROW_INDEX) {
        mechanism = [self oathMechanism];
    } else if (indexPath.row == PUSH_MECHANISM_ROW_INDEX) {
        mechanism = [self pushMechanism];
    }
    return mechanism;
}

- (void)deleteMechanism:(FRAMechanism *)mechanism {
    FRAIdentity *parent = mechanism.parent;
    if ([parent mechanisms].count == 1) {
        // If this is the only mechanism registered to the identity, then remove the identity itself
        // (after navigating back to the accounts screen so that it's removal can be animated)
        [self.navigationController popViewControllerAnimated:YES];
        [self.identityModel removeIdentity:parent];
    } else {
        // If the parent identity has other mechanisms registered to it, then just remove this mechanism
        // and leave the UI updates to be triggered in response to the database change event handler
        [mechanism.parent removeMechanism:mechanism];
    }
}

- (void)handleIdentityDatabaseChanged:(NSNotification *)notification {
    [self reloadData];
}

- (void)reloadData {
    [self.tableView beginUpdates];
    
    if ([self identityHasOathMechanism]) {
        self.oathTableViewCell.hidden = NO;
        if (self.oathTableViewCell.delegate) {
            self.oathTableViewCell.delegate =
                    [FRAOathMechanismTableViewCellController controllerWithView:self.oathTableViewCell mechanism:[self oathMechanism]];
        }
        [self.oathTableViewCell.delegate reloadData];
    } else {
        self.oathTableViewCell.hidden = YES;
        self.oathTableViewCell.delegate.view = nil;
        self.oathTableViewCell.delegate = nil;
    }
    
    if ([self identityHasPushMechanism]) {
        self.pushTableViewCell.hidden = NO;
        if (self.pushTableViewCell.delegate) {
            self.pushTableViewCell.delegate =
            [FRAPushMechanismTableViewCellController controllerWithView:self.pushTableViewCell mechanism:[self pushMechanism]];
        }
        [self.pushTableViewCell.delegate reloadData];
    } else {
        self.pushTableViewCell.hidden = YES;
        self.pushTableViewCell.delegate.view = nil;
        self.pushTableViewCell.delegate = nil;
    }
    
    [self.tableView endUpdates];
}

@end
