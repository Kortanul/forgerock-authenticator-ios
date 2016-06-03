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

@class FRAIdentityDatabase;
@class FRAIdentityModel;

/*!
 * Base class for Authenticator data model types.
 */
@interface FRAModelObject : NSObject {
    @protected
    FRAIdentityModel *_identityModel;
}

/*!
 * Indicates whether this model object has been persisted to the database.
 * YES indicates it has been stored, NO indicates it has not yet been stored.
 *
 * NB: This property only indicates whether or not a record has been persisted. It 
 * does not indicate whether or not this object is dirty and has unsaved changes.
 */
@property (nonatomic, readonly, getter=isStored) BOOL stored;

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
 * @param identityModel The identity model which contains the list of identities.
 * @return The initialized object or nil if initialization failed.
 */
- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel;

@end
