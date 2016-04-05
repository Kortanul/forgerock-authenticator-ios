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

#import "FRATokenCodeViewController.h"
#import "FRAIdentityDatabase.h"

@implementation FRATokenCodeViewController {
    FRAIdentityDatabase* database;
    NSTimer* timer;
}

+ (instancetype)controllerForView:(id<FRATokenCodeView>)view withMechanism:(FRAOathMechanism*)mechanism {
    return [[FRATokenCodeViewController alloc] initForView:view withMechanism:mechanism];
}

- (instancetype)initForView:(id<FRATokenCodeView>)view withMechanism:(FRAOathMechanism*)mechanism {
    if (self = [super init]) {
        _view = view;
        _mechanism = mechanism;
        database = [FRAIdentityDatabase singleton];
        [self initView];
    }
    return self;
}

- (void)initView {
    if ([_mechanism.type isEqualToString:@"totp"]) {
        if (!timer) {
            timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerCallback:) userInfo:nil repeats:YES];
        }
    } else if ([_mechanism.type isEqualToString:@"hotp"]) {
        if (timer) {
            [timer invalidate];
            timer = nil;
        }
    }
    [self showHideElements];
    [self updateCodeAndProgress];
}

- (void)showHideElements {
    if (self.isEditing) {
        [UIView animateWithDuration:0.5f animations:^{
            self.view.totpCodeProgress.alpha = 0.0f;
            self.view.hotpRefreshButton.alpha = 0.0f;
        }];
    } else {
        if ([_mechanism.type isEqualToString:@"totp"]) {
            [UIView animateWithDuration:0.5f animations:^{
                self.view.totpCodeProgress.alpha = 1.0f;
                self.view.hotpRefreshButton.alpha = 0.0f;
            }];
        } else if ([_mechanism.type isEqualToString:@"hotp"]) {
            [UIView animateWithDuration:0.5f animations:^{
                self.view.totpCodeProgress.alpha = 0.0f;
                self.view.hotpRefreshButton.alpha = 1.0f;
            } completion:^(BOOL finished) {
                self.view.totpCodeProgress.progress = 0.0f;
            }];
        }
    }
}

- (void)timerCallback:(NSTimer*)timer {
    [self updateCodeAndProgress];
}

- (void)updateCodeAndProgress {
    UIColor* seaGreen = [UIColor colorWithRed:48.0/255.0 green:160.0/255.0 blue:157.0/255.0 alpha:1.0];
    UIColor* dashboardRed = [UIColor colorWithRed:169.0/255.0 green:68.0/255.0 blue:66.0/255.0 alpha:1.0];

    if ([_mechanism.type isEqualToString:@"totp"] && !self.isEditing) {
        if (!_mechanism.code) {
            [_mechanism generateNextCode];
        }
        float progress = _mechanism.code.progress;
        if (progress == 1.0) {
            [_mechanism generateNextCode];
            progress = _mechanism.code.progress;
        }
        
        UIColor* color = seaGreen;
        if (progress > 0.9f) {
            color = dashboardRed;
        }
        
        self.view.totpCodeProgress.progress = progress;
        self.view.totpCodeProgress.progressColor = color;
        self.view.code.textColor = color;
    } else {
        self.view.code.textColor = seaGreen;
    }
    
    NSString* codeValue = [@"" stringByPaddingToLength:_mechanism.digits withString:@"●" startingAtIndex:0];
    if (_mechanism.code && !self.isEditing) {
        codeValue = _mechanism.code.value;
    }
    NSUInteger midPoint = codeValue.length / 2;
    NSString* firstHalf = [codeValue substringToIndex:midPoint];
    NSString* secondHalf = [codeValue substringFromIndex:midPoint];
    self.view.code.text = [NSString stringWithFormat:@"%@ %@", firstHalf, secondHalf];
}

- (void)setEditing:(BOOL)editing {
    _editing = editing;
    [self showHideElements];
    [self updateCodeAndProgress];
}

- (void)didTouchUpInside {
    if (!self.isEditing) {
        if (!_mechanism.code) {
            // if no code has been generated, allow the first to be created by touching anywhere within the cell;
            // once the first code has been generated, the refresh button must be used
            [self generateNextCode];
        } else {
            // otherwise, if a code has already been displayed, then copy it to the clipboard
            NSString* codeValue = _mechanism.code.value;
            if (codeValue != nil) {
                [[UIPasteboard generalPasteboard] setString:codeValue];
            }
        }
    }
}

- (void)generateNextCode {
    if (!self.isEditing) {
        [_mechanism generateNextCode];
        [database updateMechanism:_mechanism];
        [self updateCodeAndProgress];
    }
}

@end
