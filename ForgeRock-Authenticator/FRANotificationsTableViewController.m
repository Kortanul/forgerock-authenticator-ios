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

#import "FRANotificationsTableViewController.h"
#import "FRANotificationTableViewCell.h"

@implementation FRANotificationsTableViewController

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Present active notifications in top section and history in bottom section
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Hardcoded for example data
    return section == 0 ? 1 : 10;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"" : @"COMPLETED";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UIColor* seaGreen = [UIColor colorWithRed:48.0/255.0 green:160.0/255.0 blue:157.0/255.0 alpha:1.0];
    UIColor* dashboardRed = [UIColor colorWithRed:169.0/255.0 green:68.0/255.0 blue:66.0/255.0 alpha:1.0];
    
    // TODO: Lookup relevant notification from SQLite DB
    static NSString *CellIdentifier = @"NotificationCell";
    FRANotificationTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if ([self isPendingNotificationAtIndexPath:indexPath]) {
        // enable selection/segue from pending notifications
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        [cell setUserInteractionEnabled:YES];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        cell.status.text = @"Pending";
        cell.image.image = [[UIImage imageNamed:@"PendingIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.image.tintColor = [UIColor grayColor];
        cell.time.text = @"2 min ago";
    } else {
        // only enable selection/segue from pending notifications
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell setUserInteractionEnabled:NO];
        cell.accessoryType = UITableViewCellAccessoryNone;

        if (indexPath.row == 3) {
            cell.status.text = @"Denied";
            cell.image.image = [[UIImage imageNamed:@"DeniedIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.image.tintColor = dashboardRed;
        } else {
            cell.status.text = @"Approved";
            cell.image.image = [[UIImage imageNamed:@"ApprovedIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.image.tintColor = seaGreen;
        }
        if (indexPath.row < 2) {
            cell.time.text = @"Yesterday";
        } else {
            cell.time.text = @"22/3/16";
        }
    }
    [cell layoutIfNeeded];
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isPendingNotificationAtIndexPath:indexPath]) {
        // only enable selection/segue from pending notifications
        return indexPath;
    } else {
        return nil;
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
#pragma mark FRANotificationsTableViewController

- (BOOL)isPendingNotificationAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0;
}

@end
