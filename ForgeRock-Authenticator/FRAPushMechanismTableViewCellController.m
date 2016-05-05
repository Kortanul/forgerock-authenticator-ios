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

#import "FRAPushMechanismTableViewCell.h"
#import "FRAPushMechanismTableViewCellController.h"
#import "FRAPushMechanism.h"

@implementation FRAPushMechanismTableViewCellController

+ (instancetype)controllerWithView:(FRAPushMechanismTableViewCell *)view mechanism:(FRAPushMechanism *)mechanism {
    return [[FRAPushMechanismTableViewCellController alloc] initWithView:view mechanism:mechanism];
}

- (instancetype)initWithView:(FRAPushMechanismTableViewCell *)tableViewCell mechanism:(FRAPushMechanism *)mechanism {
    if (self = [super init]) {
        _tableViewCell = tableViewCell;
        _mechanism = mechanism;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self showHideElements];
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)showHideElements {
    if (self.isEditing) {
        [UIView animateWithDuration:0.4f animations:^{
            self.tableViewCell.notificationsBadge.alpha = 0.0f;
        }];
    } else {
        [UIView animateWithDuration:0.4f animations:^{
            self.tableViewCell.notificationsBadge.alpha = 1.0f;
        }];
    }
}

- (void)setEditing:(BOOL)editing {
    [super setEditing:editing];
    [self showHideElements];
}

- (void)reloadData {
    self.tableViewCell.notificationsBadge.text = [NSString stringWithFormat:@"%ld", (long)[self.mechanism pendingNotificationsCount]];
}

@end
