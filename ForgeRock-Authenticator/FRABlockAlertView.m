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

#import "FRABlockAlertView.h"

@interface FRABlockAlertView () <UIAlertViewDelegate>

@end

@implementation FRABlockAlertView {
    void(^callback)(NSInteger);
}

#pragma mark -
#pragma mark UIAlertView

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitle:(NSString *)otherButtonTitle handler:(void (^)(NSInteger))handler {
    self = [super initWithTitle:title message:message delegate:(delegate ? delegate : self) cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitle, nil];
    if (self) {
        callback = handler;
    }
    return self;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (callback) {
        callback(self.numberOfButtons - 1 - buttonIndex);
    }
}

@end
