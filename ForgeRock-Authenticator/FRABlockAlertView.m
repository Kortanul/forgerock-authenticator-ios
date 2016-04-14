//
//  FRABlockAlertView.m
//  ForgeRock
//
//  Created by Craig McDonnell on 19/04/2016.
//  Copyright © 2016 ForgeRock. All rights reserved.
//

#import "FRABlockAlertView.h"

@interface FRABlockAlertView () <UIAlertViewDelegate>

@end

@implementation FRABlockAlertView

#pragma mark -
#pragma mark UIAlertView

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    self.callback(self.numberOfButtons - 1 - buttonIndex);
}

#pragma mark -
#pragma mark FRABlockAlertView

- (void)setCallback:(void (^)(NSInteger))callback {
    _callback = callback;
    if (self.delegate == nil) {
        self.delegate = self;
    }
}

@end
