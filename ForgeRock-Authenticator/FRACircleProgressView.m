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

#import "FRACircleProgressView.h"

@implementation FRACircleProgressView

#pragma mark -
#pragma mark UIView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self == nil) {
        return nil;
    }
    self.progress = 0.0;
    self.backgroundColor = [UIColor clearColor];
    return self;
}

#pragma mark -
#pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self == nil) {
        return nil;
    }
    self.progress = 0.0;
    self.backgroundColor = [UIColor clearColor];
    return self;
}

#pragma mark -
#pragma mark UIView

- (void)drawRect:(CGRect)xxx {
    CGFloat progress = self.progress;
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGFloat radius = MAX(MIN(self.bounds.size.height / 2.0, self.bounds.size.width / 2.0) - 4, 1);
    CGFloat radians = MAX(MIN(progress * 2 * M_PI, 2 * M_PI), 0);

    UIColor* lightGrey = [UIColor colorWithRed:238.0/255.0 green:238.0/255.0 blue:238.0/255.0 alpha:1.0];
    
    // draw progress using specified progressColor
    UIBezierPath* progressPath = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:-M_PI_2 endAngle:radians-M_PI_2 clockwise:YES];
    [self.progressColor setStroke];
    [progressPath setLineWidth:4.0];
    [progressPath stroke];
    
    // draw remainder of circle in light grey
    UIBezierPath* fullCirclePath = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:radians-M_PI_2 endAngle:(2 * M_PI) - M_PI_2 clockwise:YES];
    [lightGrey setStroke];
    [fullCirclePath setLineWidth:4.0];
    [fullCirclePath stroke];
}

#pragma mark -
#pragma mark FRACircleProgressView (public)

- (void)setProgress:(float)progress {
    _progress = progress;
    [self setNeedsDisplay];
}

@end
