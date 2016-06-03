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

#import "FRAAlertController.h"
#import "FRAError.h"
#import "FRAIdentity.h"
#import "FRAUriMechanismReader.h"
#import "FRAMechanismReaderAction.h"

@implementation FRAMechanismReaderAction

#pragma mark -
#pragma mark Lifecyle

- (instancetype)initWithMechanismReader:(FRAUriMechanismReader *)mechanismReader{
    self = [super init];
    if (self) {
        _mechanismReader = mechanismReader;
    }
    return self;
}

#pragma mark -
#pragma mark Public Methods

- (BOOL)read:(NSString *)code error:(NSError *__autoreleasing*)error {
    // TODO: Handle error
    FRAMechanism *mechanism = [_mechanismReader parseFromString:code error:error];
    
    if (mechanism) {
        return YES;
    }
    
    if (error && (*error).code == FRADuplicateMechanism) {
        FRAIdentity *identity = [(*error).userInfo valueForKey:@"identity"];
        FRAMechanism *duplicateMechanism = [(*error).userInfo valueForKey:@"mechanism"];
        void(^handler)(NSInteger) = [self duplicateMechanismCallback:code identity:identity mechanism:duplicateMechanism error:error];
        [FRAAlertController showAlert:*error handler:handler];
        return YES;
    }
    
    return NO;
}

#pragma mark -
#pragma mark Private Methods

/*!
 * Generates a duplicate mechanism callback which once confirmed will remove the duplicate mechanism and re-parse the URL to add in the mechanism.
 * @param code The code with the mechanism details.
 * @param identity The identity the mechanism is added to.
 * @param mechanism The duplicate mechanism.
 * @return The callback block.
 */
- (void(^)(NSInteger))duplicateMechanismCallback:(NSString *)code identity:(FRAIdentity *)identity mechanism:(FRAMechanism *)mechanism error:(NSError *__autoreleasing*) error {
    return ^(NSInteger selection) {
        const NSInteger okButton = 0;
        if (selection == okButton) {
            BOOL successfullyRemoved =[identity removeMechanism:mechanism error:error];
            // TODO: handle error
            if (successfullyRemoved) {
                [_mechanismReader parseFromString:code error:error];
            }
        }
    };
}

@end