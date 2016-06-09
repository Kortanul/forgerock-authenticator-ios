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

#import "FRAHotpOathMechanism.h"
#import "FRATotpOathMechanism.h"
#import "FRAOathMechanismTableViewCellController.h"
#import "FRABlockActionSheet.h"
#import "FRAOathMechanismTableViewCell.h"
#import "FRAIdentityModel.h"
#import "FRAOathCode.h"

/*!
 * Private interface.
 */
@interface FRAOathMechanismTableViewCellController ()

/*!
 * Timer for updating TOTP progress indicator and generating next code in sequence.
 */
@property (strong, nonatomic) NSTimer *progressAnimationTimer;

@end

@implementation FRAOathMechanismTableViewCellController

+ (instancetype)controllerWithView:(FRAOathMechanismTableViewCell*)view mechanism:(FRAMechanism *)mechanism {
    return [[FRAOathMechanismTableViewCellController alloc] initWithView:view mechanism:mechanism];
}

- (instancetype)initWithView:(FRAOathMechanismTableViewCell*)view mechanism:(FRAMechanism *)mechanism {
    if (self = [super init]) {
        _tableViewCell = view;
        _mechanism = mechanism;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([self.mechanism isKindOfClass:[FRATotpOathMechanism class]]) {
        [self startProgressAnimationTimer];
    } else if ([self.mechanism isKindOfClass:[FRAHotpOathMechanism class]]) {
        [self stopProgressAnimationTimer];
    }
    [self showHideElements];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopProgressAnimationTimer];
}

- (void)showHideElements {
    if (self.isEditing) {
        [UIView animateWithDuration:0.5f animations:^{
            self.tableViewCell.totpCodeProgress.alpha = 0.0f;
            self.tableViewCell.hotpRefreshButton.alpha = 0.0f;
        }];
    } else {
        if ([self.mechanism isKindOfClass:[FRATotpOathMechanism class]]) {
            [UIView animateWithDuration:0.5f animations:^{
                self.tableViewCell.totpCodeProgress.alpha = 1.0f;
                self.tableViewCell.hotpRefreshButton.alpha = 0.0f;
            }];
        } else if ([self.mechanism isKindOfClass:[FRAHotpOathMechanism class]]) {
            [UIView animateWithDuration:0.5f animations:^{
                self.tableViewCell.totpCodeProgress.alpha = 0.0f;
                self.tableViewCell.hotpRefreshButton.alpha = 1.0f;
            } completion:^(BOOL finished) {
                self.tableViewCell.totpCodeProgress.progress = 0.0f;
            }];
        }
    }
}

- (void)timerCallback:(NSTimer*)timer {
    if ([self.mechanism isKindOfClass:[FRATotpOathMechanism class]]) {
        FRATotpOathMechanism *mechanism = (FRATotpOathMechanism *)self.mechanism;
        if ((!mechanism.code) || [mechanism hasExpired]) {
            // TODO: Handle error
            @autoreleasepool {
                NSError* error;
                [mechanism generateNextCode:&error];
            }
        }
    } else if ([self.mechanism isKindOfClass:[FRAHotpOathMechanism class]]) {
        FRAHotpOathMechanism *mechanism = (FRAHotpOathMechanism *)self.mechanism;
        if ((!mechanism.code)) {
            // TODO: Handle error
            @autoreleasepool {
                NSError* error;
                [mechanism generateNextCode:&error];
            }
        }
    }
    
    [self reloadData];
}

- (void)setEditing:(BOOL)editing {
    [super setEditing:editing];
    [self showHideElements];
    [self reloadData];
}

- (void)didTouchUpInside {
    if (!self.isEditing) {
        if (![self mechanismCode]) {
            // if no code has been generated, allow the first to be created by touching anywhere within the cell;
            // once the first code has been generated, the refresh button must be used
            [self generateNextCode];
        } else {
            // otherwise, if a code has already been displayed, then offer to copy it to the clipboard
            FRABlockActionSheet *actionSheet = [[FRABlockActionSheet alloc]
                                                initWithTitle:nil
                                                delegate:nil
                                                cancelButtonTitle:@"Cancel"
                                                destructiveButtonTitle:nil
                                                otherButtonTitles:@"Copy", nil];
            actionSheet.callback = ^(NSInteger offset) {
                if (offset == 1) {
                    NSString* codeValue = [self mechanismCode];
                    if (codeValue) {
                        [[UIPasteboard generalPasteboard] setString:codeValue];
                    }
                }
            };
            [actionSheet showFromRect:self.view.frame inView:self.view animated:YES];
        }
    }
}

- (NSString *)mechanismCode {
    return (FRAHotpOathMechanism *)self.mechanism ? ((FRAHotpOathMechanism *)self.mechanism).code : ((FRATotpOathMechanism *)self.mechanism).code;
}

- (NSInteger)mechanismCodeLength {
    return (FRAHotpOathMechanism *)self.mechanism ? ((FRAHotpOathMechanism *)self.mechanism).codeLength : ((FRATotpOathMechanism *)self.mechanism).codeLength;
}

- (void)generateNextCode {
    if (!self.isEditing) {
        // TODO: Handle error
        @autoreleasepool {
            NSError* error;
            if ([[self mechanism] isKindOfClass:[FRAHotpOathMechanism class]]) {
                [(FRAHotpOathMechanism *)self.mechanism generateNextCode:&error];
            } else if ([[self mechanism] isKindOfClass:[FRATotpOathMechanism class]]) {
                [(FRATotpOathMechanism *)self.mechanism generateNextCode:&error];
            }
        }
    }
}

- (void)reloadData {
    UIColor *seaGreen = [UIColor colorWithRed:48.0/255.0 green:160.0/255.0 blue:157.0/255.0 alpha:1.0];
    UIColor *dashboardRed = [UIColor colorWithRed:169.0/255.0 green:68.0/255.0 blue:66.0/255.0 alpha:1.0];
    UIColor *color = seaGreen;
    
    // Set font color for code and (if totp-based) the progress indicator
    if ([self.mechanism isKindOfClass:[FRATotpOathMechanism class]] && !self.isEditing) {
        FRATotpOathMechanism *mechanism = (FRATotpOathMechanism *)[self mechanism];
        float progress = mechanism.progress;
        if (progress > 0.9f) {
            color = dashboardRed;
        }
        self.tableViewCell.totpCodeProgress.progress = progress;
        self.tableViewCell.totpCodeProgress.progressColor = color;
        self.tableViewCell.code.textColor = color;
    } else {
        self.tableViewCell.code.textColor = color;
    }
    
    // Set the code text
    NSString* codeValue = [@"" stringByPaddingToLength:[self mechanismCodeLength] withString:@"●" startingAtIndex:0];
    NSString *mechanismCode = [self mechanismCode];
    if (mechanismCode && !self.isEditing) {
        codeValue = mechanismCode;
    }
    NSUInteger midPoint = codeValue.length / 2;
    NSString *firstHalf = [codeValue substringToIndex:midPoint];
    NSString *secondHalf = [codeValue substringFromIndex:midPoint];
    self.tableViewCell.code.text = [NSString stringWithFormat:@"%@ %@", firstHalf, secondHalf];
}

- (void)startProgressAnimationTimer {
    if (!self.progressAnimationTimer) {
        self.progressAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerCallback:) userInfo:nil repeats:YES];
    }
}

- (void)stopProgressAnimationTimer {
    [self.progressAnimationTimer invalidate];
    self.progressAnimationTimer = nil;
}

@end
