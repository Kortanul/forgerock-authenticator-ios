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
#import "FRAOathMechanism.h"
#import "FRAOathMechanismTableViewCell.h"
#import "FRAOathMechanismTableViewController.h"
#import "FRAPushMechanism.h"

@implementation FRAAccountTableViewController

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Show issuer logo in circle
    _image.layer.cornerRadius = _image.frame.size.width / 2;
    _image.clipsToBounds = YES;
    
    // Bind identity model to UI
    //  _image = ... // TODO: Use UIImageView+AFNetworking category provided by AFNetworking
    _issuer.text = _identity.issuer;
    _accountName.text = _identity.accountName;
    
    // Bind controller to OATH mechanism table view cell defined in storyboard - let controller bind model
    // TODO: Update OATH controller so that it can handle nil
    if ([self hasRegisteredOathMechanism]) {
        _tokenTableViewCell.delegate = [FRAOathMechanismTableViewController controllerForView:_tokenTableViewCell withMechanism:[self oathMechanism] withIdentityModel:self.identityModel];
    }

    // TODO: Bind controller to push mechanism table view cell defined in storyboard - let controller bind model
    // Prevent M13BadgeView from attempting to position itself, position should be set by storyboard constraints
    self.notificationsBadge.verticalAlignment = M13BadgeViewVerticalAlignmentNone;
    self.notificationsBadge.horizontalAlignment = M13BadgeViewHorizontalAlignmentNone;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self updateNotificationsCount];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleIdentityDatabaseChanged:) name:FRAIdentityDatabaseChangedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    // TODO: Lookup FRAMechanismTableCellController for indexPath
    //       If a mechanism controller exists, delegate to method with same signature
    if ([self hasOathMechanismAtIndexPath:indexPath]) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [_tokenTableViewCell.delegate didTouchUpInside];
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
    // TODO: Lookup FRAMechanismTableCellController for indexPath
    //       If a mechanism controller exists but its mechanism is nil, return 0 for height
    if ([self hasOathMechanismAtIndexPath:indexPath] && ![self hasRegisteredOathMechanism]) {
        return 0; // hide the cell if OATH mechanism not registered
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
    // TODO: Lookup FRAMechanismTableCellController for indexPath
    //       If a mechanism controller exists perform deletion logic but remain agnostic regarding specific type of mechanism
    if ([self hasOathMechanismAtIndexPath:indexPath]) {
        FRAOathMechanism* mechanism = _tokenTableViewCell.delegate.mechanism;
        if (mechanism) {
            FRABlockAlertView* alertView = [[FRABlockAlertView alloc]
                                            initWithTitle:@"Removing this will NOT turn off 2-step verification"
                                            message:[NSString stringWithFormat:@"This may prevent you from logging into your %@ account.", self.identity.issuer]
                                            delegate:nil
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@"Delete", nil];
            alertView.callback = ^(NSInteger offset) {
                if (offset == 0) {
                    
                    // TODO: If this is the only mechanism registered to the parent identity, then
                    //       navigate back to the accounts screen and with an instruction to remove
                    //       the identity
                    
                    // Remove the mechanism
                    [mechanism.parent removeMechanism:mechanism];
                    // Remove the mechanism cell from the UI
                    [self.tableView beginUpdates];
                    _tokenTableViewCell.hidden = YES;
                    [self.tableView endUpdates];
                    [tableView reloadData];
                    // TODO: Only set _tokenTableViewCell.delegate.mechanism = nil but keep controller (delegate)
                    _tokenTableViewCell.delegate.view = nil;
                    _tokenTableViewCell.delegate = nil;
                    // Navigate back to the accounts screen if the account was deleted
                    
                    if (![mechanism.parent isStored]) {
                        [self.navigationController popViewControllerAnimated:YES];
                    }
                }
            };
            [alertView show];
        }
    }
}

#pragma mark -
#pragma mark FRAAccountTableViewController (private)

- (BOOL)hasOathMechanismAtIndexPath:(NSIndexPath*)indexPath {
    return indexPath.row == 1;
}

- (BOOL)hasNotificationsMechanismAtIndexPath:(NSIndexPath*)indexPath {
    return indexPath.row == 2;
}

- (void)updateNotificationsCount {
    FRAPushMechanism *mechanism = [self pushMechanism];
    NSInteger count = mechanism ? mechanism.notifications.count : 0;
    self.notificationsBadge.text = [NSString stringWithFormat:@"%ld", (long) count];
}

- (BOOL)hasMechanismAtIndexPath:(NSIndexPath*)indexPath {
    return [self hasOathMechanismAtIndexPath:indexPath] || [self hasNotificationsMechanismAtIndexPath:indexPath];
}

- (BOOL)hasRegisteredOathMechanism {
    return [self oathMechanism] != nil;
}

- (FRAOathMechanism*)oathMechanism {
    NSArray* mechanisms = [_identity mechanisms];
    for (NSObject* mechanism in mechanisms) {
        if ([mechanism isKindOfClass:[FRAOathMechanism class]]) {
            return (FRAOathMechanism*) mechanism;
        }
    }
    return nil;
}

- (FRAPushMechanism*)pushMechanism {
    NSArray* mechanisms = [_identity mechanisms];
    for (NSObject* mechanism in mechanisms) {
        if ([mechanism isKindOfClass:[FRAPushMechanism class]]) {
            return (FRAPushMechanism*) mechanism;
        }
    }
    return nil;
}

- (void)handleIdentityDatabaseChanged:(NSNotification *)notification {
    NSLog(@"database changed notification received by account table view controller");
    [self updateNotificationsCount];
}

@end
