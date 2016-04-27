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

#import <Foundation/Foundation.h>

#import "FRAModelObject.h"

@class FRAIdentityDatabase;
@class FRAMechanism;

/*!
 * Identity is responsible for modelling the information that makes up part of a user's identity in
 * the context of logging into that user's account.
 */
@interface FRAIdentity : FRAModelObject

/*!
 * Name of the Identity Provider (IdP) that issued this identity.
 */
@property (copy, nonatomic, readonly) NSString *issuer;
/*!
 * Name of this identity.
 */
@property (copy, nonatomic, readonly) NSString *accountName;
/*!
 * URL pointing to an image (such as a logo) that represents the issuer of this identity.
 */
@property (copy, nonatomic, readonly) NSURL *image;

/*!
 * The Mechanisms assigned to the Identity. Maybe empty.
 */
@property (getter=mechanisms, nonatomic, readonly) NSArray<FRAMechanism *> *mechanisms;

#pragma mark -
#pragma mark Lifecycle

/*!
 * Prevent external use of super class' initWithDatabase: method.
 */
- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database __unavailable;

/*!
 * Creates a new identity object with the provided property values.
 */
- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database accountName:(NSString *)accountName issuer:(NSString *)issuer image:(NSURL *)image;

/*!
 * Creates a new identity object with the provided property values.
 */
+ (instancetype)identityWithDatabase:(FRAIdentityDatabase *)database accountName:(NSString *)accountName issuer:(NSString *)issuer image:(NSURL *)image;

#pragma mark -
#pragma mark Mechanism Functions

/*!
 * Returns mechanism of the specified type if one has been registered to this identity.
 *
 * @param aClass The type of mechanism to look for.
 * @return The mechanism object, or nil if no such mechanism has been registered.
 */
- (FRAMechanism *)mechanismOfClass:(Class)aClass;

/*!
 * When a new Mechanism is created, it will assigned to the Identity via
 * this call.
 *
 * @param mechanism The new mechanism to add to this identity.
 */
- (void)addMechanism:(FRAMechanism *)mechanism;

/*!
 * Removes the Mechanism, only if it was assigned to this Identity.
 *
 * @param mechanism The mechanism to remove from the identity.
 */
- (void)removeMechanism:(FRAMechanism *)mechanism;

@end
