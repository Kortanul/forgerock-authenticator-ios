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
 * Portions Copyright 2013 Nathaniel McCallum, Red Hat
 */

#import "CircleProgressView.h"

@implementation CircleProgressView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self == nil) {
        return nil;
    }
    self.hollow = false;
    self.clockwise = true;
    self.threshold = 0;
    self.progress = 0.0;
    self.backgroundColor = [UIColor clearColor];
    return self;
}

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self == nil) {
        return nil;
    }
    self.hollow = false;
    self.clockwise = true;
    self.threshold = 0;
    self.progress = 0.0;
    self.backgroundColor = [UIColor clearColor];
    return self;
}

- (void)setHollow:(BOOL)hollow {
    _hollow = hollow;
    [self setNeedsDisplay];
}

- (void)setClockwise:(BOOL)clockwise {
    _clockwise = clockwise;
    [self setNeedsDisplay];
}

- (void)setThreshold:(float)threshold {
    _threshold = threshold;
    [self setNeedsDisplay];
}

- (void)setProgress:(float)progress {
    _progress = progress;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)xxx {
    CGFloat progress = self.clockwise ? self.progress : (1.0f - self.progress);
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGFloat radius = MAX(MIN(self.bounds.size.height / 2.0, self.bounds.size.width / 2.0) - 4, 1);
    CGFloat radians = MAX(MIN(progress * 2 * M_PI, 2 * M_PI), 0);

    UIColor* color = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    if (self.threshold < 0 && self.progress < fabsf(self.threshold)) {
        color = [UIColor colorWithRed:1.0 green:self.progress * (1 / fabsf(self.threshold)) blue:0.0 alpha:1.0];
    } else if (self.threshold > 0 && self.progress > self.threshold) {
        color = [UIColor colorWithRed:1.0 green:(1 - self.progress) * (1 / (1 - self.threshold)) blue:0.0 alpha:1.0];
    }
    
    UIBezierPath* path = [UIBezierPath bezierPathWithArcCenter:center radius:radius
                             startAngle:-M_PI_2 endAngle:radians-M_PI_2 clockwise:self.clockwise];
    if (self.hollow) {
        [color setStroke];
        [path setLineWidth:3.0];
        [path stroke];
    } else {
        [color setFill];
        [path addLineToPoint:center];
        [path addClip];
        UIRectFill(self.bounds);
    }
}

@end
