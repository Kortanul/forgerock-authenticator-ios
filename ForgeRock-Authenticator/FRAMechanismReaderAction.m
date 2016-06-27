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
#import "FRABlockAlertView.h"
#import "FRAError.h"
#import "FRAIdentity.h"
#import "FRAUriMechanismReader.h"
#import "FRAMechanismReaderAction.h"

@implementation FRAMechanismReaderAction {
    FRAActivityIndicator *activityIndicator;
}

#pragma mark -
#pragma mark Lifecyle

- (instancetype)initWithMechanismReader:(FRAUriMechanismReader *)mechanismReader {
    self = [super init];
    if (self) {
        _mechanismReader = mechanismReader;
    }
    return self;
}

#pragma mark -
#pragma mark Public Methods

- (BOOL)read:(NSString *)code view:(UIView *)view {
    [self showActivityIndicator:view];

    NSError *error;
    FRAMechanism *mechanism = [_mechanismReader parseFromString:code handler:[self mechanismReadCallback] error:&error];
    
    if (mechanism) {
        return YES;
    }
    
    if (error && error.code == FRADuplicateMechanism) {
        [self handleDuplicateMechanism:code error:&error];
        return YES;
    }
    
    [self hideActivityIndicator];
    [self showAlert:error];
    
    return NO;
}

#pragma mark -
#pragma mark Private Methods

/*!
 * Displays the activity indicator and disables the current view.
 *
 * @param view The current view.
 */
- (void)showActivityIndicator:(UIView *)view {
    if (!view) {
        return;
    }
    
    view.userInteractionEnabled = NO;
    activityIndicator = [[FRAActivityIndicator alloc] init:NSLocalizedString(@"qr_code_scan_contact_server", nil)];
    [view addSubview:activityIndicator];
}

/*!
 * Hides the activity indicator and enables the current view.
 */
- (void)hideActivityIndicator {
    activityIndicator.superview.userInteractionEnabled = YES;
    [activityIndicator removeFromSuperview];
}

/*!
 * Handles duplicate mechanism detection.
 *
 * @param code The code with the mechanism details.
 * @param error If an error occurs, upon returns contains an NSError object that describes the problem. If you are not interested in possible errors, you may pass in NULL.
 */
- (void)handleDuplicateMechanism:(NSString *)code error:(NSError *__autoreleasing*)error {
    FRAIdentity *identity = [(*error).userInfo valueForKey:@"identity"];
    FRAMechanism *duplicateMechanism = [(*error).userInfo valueForKey:@"mechanism"];
    FRABlockAlertView *alertView = [[FRABlockAlertView alloc] initWithTitle:NSLocalizedString(@"mechanism_duplicate_title", nil)
                                                                    message:NSLocalizedString(@"mechanism_duplicate_message", nil)
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                                                           otherButtonTitle:NSLocalizedString(@"ok", nil)
                                                                    handler:[self duplicateMechanismCallback:code identity:identity mechanism:duplicateMechanism error:error]];
    [alertView show];
}

/*!
 * Generates a duplicate mechanism callback which once confirmed will remove the duplicate mechanism and re-parse the URL to add in the mechanism.
 *
 * @param code The code with the mechanism details.
 * @param identity The identity the mechanism is added to.
 * @param mechanism The duplicate mechanism.
 * @param error If an error occurs, upon returns contains an NSError object that describes the problem. If you are not interested in possible errors, you may pass in NULL.
 * @return The callback block.
 */
- (void(^)(NSInteger))duplicateMechanismCallback:(NSString *)code identity:(FRAIdentity *)identity mechanism:(FRAMechanism *)mechanism error:(NSError *__autoreleasing*) error {
    return ^(NSInteger selection) {
        const NSInteger okButton = 0;
        if (selection == okButton) {
            BOOL successfullyRemoved =[identity removeMechanism:mechanism error:error];
            if (successfullyRemoved) {
                [_mechanismReader parseFromString:code handler:[self mechanismReadCallback] error:error];
            }
        } else {
            [self hideActivityIndicator];
        }
    };
}

/*!
 * Generates a callback for any asynchronous operation happening when reading a QR code.
 *
 * @return The callback block.
 */
- (void(^)(BOOL, NSError *))mechanismReadCallback {
    return ^(BOOL success, NSError *error) {
        [self hideActivityIndicator];
        if (!success) {
            [self showAlert:error];
        }
    };
}

/*!
 * Displays an alert message to the user.
 *
 * @param error The error to display to the user.
 *
 */
- (void)showAlert:(NSError *)error {
    FRABlockAlertView *alertView = [[FRABlockAlertView alloc] initWithTitle:NSLocalizedString(@"qr_code_scan_error_title", nil)
                                                                    message:[self errorMessage:error]
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                                           otherButtonTitle:nil
                                                                    handler:nil];
    [alertView show];
}

/*!
 * Gets the localized error message to display to the user.
 *
 * @param error The error to display to the user.
 *
 */
- (NSString *)errorMessage:(NSError *)error {
    if (!error) {
        return nil;
    }
    
    switch (error.code) {
        case FRANetworkFailure:
            return NSLocalizedString(@"qr_code_scan_error_network_failure_message", nil);
        case FRAMissingDeviceId:
            return NSLocalizedString(@"qr_code_scan_error_no_device_id_message", nil);
        case FRAInvalidQRCode:
            return NSLocalizedString(@"qr_code_scan_error_invalid_code", nil);
        default:
            return nil;
    }
}

@end