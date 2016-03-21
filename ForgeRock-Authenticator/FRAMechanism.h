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
@class FRAIdentity;

/*!
 * A mechanism used for authentication.
 * Encapsulates the related settings, as well as an owning Identity
 */
@protocol FRAMechanism <NSObject>

/*!
 * The storage ID of this OATH mechanism.
 */
@property (nonatomic) NSInteger uid;
/*!
 * The version number of this OATH mechanism.
 */
@property (nonatomic, readonly) NSInteger version;
/*!
 * The identity to which this OATH mechanism is registered.
 */
@property (nonatomic, readonly) FRAIdentity* owner;

@end
