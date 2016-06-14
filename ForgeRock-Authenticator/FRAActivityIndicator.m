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

#import "FRAActivityIndicator.h"

@interface FRAActivityIndicator ()

@property (strong, nonatomic) UIBlurEffect *blurEffect;
@property (strong, nonatomic) UIVisualEffectView *vibrancyView;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) UILabel *label;

@end

@implementation FRAActivityIndicator

#pragma mark -
#pragma mark Lifecyle

- (instancetype)init:(NSString *)message {
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.vibrancyView = [[UIVisualEffectView alloc] initWithEffect:[UIVibrancyEffect effectForBlurEffect:self.blurEffect]];
    self = [super initWithEffect:self.blurEffect];
    if (self) {
        [self setUp:message];
    }
    return self;
}

- (void)setUp:(NSString *)message {
    self.label = [[UILabel alloc] init];
    self.label.text = message;
    [self.contentView addSubview:self.vibrancyView];
    [self.vibrancyView.contentView addSubview:self.activityIndicator];
    [self.vibrancyView.contentView addSubview:self.label];
    [self.activityIndicator startAnimating];
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    
    if (self.superview) {
        CGFloat width = self.superview.frame.size.width / 1.5;
        CGFloat height = (CGFloat)50.0;
        self.frame = CGRectMake(self.superview.frame.size.width / 2 - width / 2,
                                self.superview.frame.size.height / 2 - height / 2,
                                width,
                                height);
        self.vibrancyView.frame = self.bounds;
        
        CGFloat activityIndicatorSize = (CGFloat)40;
        self.activityIndicator.frame = CGRectMake(5, height / 2 - activityIndicatorSize / 2,
                                                  activityIndicatorSize,
                                                  activityIndicatorSize);
        
        self.layer.cornerRadius = 8.0;
        self.layer.masksToBounds = true;
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.frame = CGRectMake(activityIndicatorSize + 5, 0, width - activityIndicatorSize - 15, height);
        self.label.textColor = [UIColor grayColor];
        self.label.font = [UIFont systemFontOfSize:16];
    }
}

@end