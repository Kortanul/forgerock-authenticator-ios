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

@class FRAIdentityDatabase;

/*!
 * Base class for Authenticator data model types.
 */
@interface FRAModelObject : NSObject

/*!
 * The storage ID of this object.
 */
@property (nonatomic, readonly) NSInteger uid;

#pragma mark -
#pragma mark Lifecycle

// TODO: Create FRAModelObjectSubclass.h private header file that includes protected database property and init methods?

/*!
 * Prevent use of default init method.
 */
- (instancetype)init __unavailable;

/*!
 * Init method.
 *
 * @param database The database to which this object can be persisted.
 * @return The initialized object or nil if initialization failed.
 */
- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database;

/**
 * Check whether or not this object has been persisted to the FRAIdentityDatabase.
 * NB. This method only indicates whether or not a record exists with this object's uid, it does
 * not indicate whether or not this object is dirty and has unsaved changes.
 *
 * @return YES if this object has been saved to FRAIdentityDatabase; NO otherwise.
 */
- (BOOL)isStored;

@end
