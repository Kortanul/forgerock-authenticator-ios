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

#import "FRAIdentityDatabase.h"
#import "FRANotification.h"
#import "FRANotificationsTableViewController.h"
#import "FRANotificationViewController.h"
#import "FRANotificationTableViewCell.h"
#import "FRAPushMechanism.h"

NSString * const FRANotificationsTableViewControllerStoryboardIdentifer = @"NotificationsTableViewController";
NSString * const FRANotificationsTableViewControllerShowNotificationsSegue = @"showNotificationSegue";

static const NSInteger NUMBER_OF_SECTIONS = 2;
static const NSInteger PENDING_SECTION_INDEX = 0;
static const NSInteger COMPLETED_SECTION_INDEX = 1;

/*!
 * Private interface.
 */
@interface FRANotificationsTableViewController ()

/*!
 * Timer for updating age of notifications.
 */
@property (strong, nonatomic) NSTimer *timer;

@end

@implementation FRANotificationsTableViewController

#pragma mark -
#pragma mark UIViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleIdentityDatabaseChanged:) name:FRAIdentityDatabaseChangedNotification object:nil];
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerCallback:) userInfo:nil repeats:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.timer invalidate];
    self.timer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:FRANotificationsTableViewControllerShowNotificationsSegue]) {
        FRANotificationViewController *controller = (FRANotificationViewController *)segue.destinationViewController;
        NSArray *selection = [self.tableView indexPathsForSelectedRows];
        NSIndexPath *indexPath = [selection objectAtIndex:0];
        controller.notification = [[self pendingNotifications] objectAtIndex:indexPath.row];
    }
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return NUMBER_OF_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == PENDING_SECTION_INDEX) {
        return [self pendingNotifications].count;
    } else {
        return [self completedNotifications].count;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == PENDING_SECTION_INDEX ? @"" : @"COMPLETED";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UIColor* seaGreen = [UIColor colorWithRed:48.0/255.0 green:160.0/255.0 blue:157.0/255.0 alpha:1.0];
    UIColor* dashboardRed = [UIColor colorWithRed:169.0/255.0 green:68.0/255.0 blue:66.0/255.0 alpha:1.0];
    
    static NSString *CellIdentifier = @"NotificationCell";

    if (indexPath.section == PENDING_SECTION_INDEX) {
        FRANotificationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        FRANotification *notification = [[self pendingNotifications] objectAtIndex:indexPath.row];
        
        cell.status.text = @"Pending";
        cell.image.image = [[UIImage imageNamed:@"PendingIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.image.tintColor = [UIColor grayColor];
        cell.time.text = [notification age];
        
        // enable selection/segue from pending notifications
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        [cell setUserInteractionEnabled:YES];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        return cell;
        
    } else if (indexPath.section == COMPLETED_SECTION_INDEX) {
        FRANotificationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        FRANotification *notification = [[self completedNotifications] objectAtIndex:indexPath.row];
        
        if (notification.isApproved) {
            cell.status.text = @"Approved";
            cell.image.image = [[UIImage imageNamed:@"ApprovedIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.image.tintColor = seaGreen;
        } else if (notification.isDenied) {
            cell.status.text = @"Denied";
            cell.image.image = [[UIImage imageNamed:@"DeniedIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.image.tintColor = dashboardRed;
        } else if (notification.isExpired) {
            cell.status.text = @"Expired";
            cell.image.image = [[UIImage imageNamed:@"DeniedIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.image.tintColor = dashboardRed;
        }
        cell.time.text = [notification age];
        
        // don't enable selection/segue from completed notifications
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell setUserInteractionEnabled:NO];
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        return cell;
        
    } else {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
}

#pragma mark -
#pragma mark UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == PENDING_SECTION_INDEX) {
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

- (NSArray *)pendingNotifications {
    NSMutableArray *pendingNotifications = [NSMutableArray array];
    for (FRANotification *notification in [self.pushMechanism notifications]) {
        if (notification.isPending) {
            [pendingNotifications addObject:notification];
        }
    }
    [self sortNotifications:pendingNotifications];
    return pendingNotifications;
}

/*!
 * Sorts notifications in reverse chronological order.
 */
- (void)sortNotifications:(NSMutableArray *)notifications {
    [notifications sortUsingComparator:^NSComparisonResult(FRANotification* first, FRANotification* second) {
        return [second.timeReceived compare:first.timeReceived];
    }];
}

- (NSArray *)completedNotifications {
    NSMutableArray *completedNotifications = [NSMutableArray array];
    for (FRANotification *notification in [self.pushMechanism notifications]) {
        if (!notification.isPending) {
            [completedNotifications addObject:notification];
        }
    }
    [self sortNotifications:completedNotifications];
    return completedNotifications;
}

- (void)handleIdentityDatabaseChanged:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)timerCallback:(NSTimer*)timer {
    [self.tableView reloadData];
}

@end
