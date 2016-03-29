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
 *
 * Portions Copyright 2014 Nathaniel McCallum, Red Hat
 */

#import "FRAOathMechanismCell.h"

@implementation FRAOathMechanismCell {
    NSTimer* timer;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self == nil) {
        return nil;
    }
    self.layer.cornerRadius = 2.0f;
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self == nil) {
        return nil;
    }
    self.layer.cornerRadius = 2.0f;
    return self;
}

- (BOOL)bind:(FRAOathMechanism*)mechanism {
    self.state = nil;

    if (mechanism == nil) {
        return NO;
    }
    unichar tmp[mechanism.digits];
    for (NSUInteger i = 0; i < sizeof(tmp) / sizeof(unichar); i++) {
        tmp[i] = [self.placeholder.text characterAtIndex:0];
    }

    self.image.url = mechanism.owner.image;
    self.mechanismId = mechanism.uid;
    self.placeholder.text = [NSString stringWithCharacters:tmp length:sizeof(tmp) / sizeof(unichar)];
    self.outer.hidden = ![mechanism.type isEqualToString:@"totp"];
    self.issuer.text = mechanism.owner.issuer;
    self.label.text = mechanism.owner.accountName;
    self.code.text = @"";

    return YES;
}

- (void)timerCallback:(NSTimer*)timer {
    NSString* str = self.state.currentCode;
    if (str == nil) {
        self.state = nil;
        return;
    }

    self.inner.progress = self.state.currentProgress;
    self.outer.progress = self.state.totalProgress;
    self.code.text = str;
}

- (void)setState:(FRAOathCode *)state {
    if (_state == state) {
        return;
    }

    if (state == nil) {
        [UIView animateWithDuration:0.5f animations:^{
            self.placeholder.alpha = 1.0f;
            self.inner.alpha = 0.0f;
            self.outer.alpha = 0.0f;
            self.image.alpha = 1.0f;
            self.code.alpha = 0.0f;
        } completion:^(BOOL finished) {
            self.outer.progress = 0.0f;
            self.inner.progress = 0.0f;
            self.code.text = @"";
        }];

        if (self->timer != nil) {
            [self->timer invalidate];
            self->timer = nil;
        }
    } else if (self->timer == nil) {
        self->timer = [NSTimer scheduledTimerWithTimeInterval: 0.1 target: self
                                               selector: @selector(timerCallback:)
                                               userInfo: nil repeats: YES];

        // Setup the UI for progress.
        [UIView animateWithDuration:0.5f animations:^{
            self.placeholder.alpha = 0.0f;
            self.inner.alpha = 1.0f;
            self.outer.alpha = 1.0f;
            self.image.alpha = 0.1f;
            self.code.alpha = 1.0f;
        }];
    }

    _state = state;
}

@end
