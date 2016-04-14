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

#import "FRABlockActionSheet.h"

@interface FRABlockActionSheet () <UIActionSheetDelegate>

@end

@implementation FRABlockActionSheet

#pragma mark -
#pragma mark UIActionSheet

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    self.callback(self.numberOfButtons - 1 - buttonIndex);
}

#pragma mark -
#pragma mark FRABlockActionSheet

- (void)setCallback:(void (^)(NSInteger))callback {
    _callback = callback;
    if (self.delegate == nil) {
        self.delegate = self;
    }
}

@end
