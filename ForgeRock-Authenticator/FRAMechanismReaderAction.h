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

@class FRAUriMechanismReader;

/*!
 * View controller for adding mechanisms using a mechanism reader.
 */
@interface FRAMechanismReaderAction : NSObject {
    @protected
    FRAUriMechanismReader *_mechanismReader;
}

/*!
 * Init controller.
 *
 * @param mechanismReader The mechanism reader.
 *
 * @return The initialized controller or nil if initialization failed.
 */
- (instancetype)initWithMechanismReader:(FRAUriMechanismReader *)mechanismReader;

/*!
 * Read mechanism details from a code.
 *
 * @param code The code with the mechanism details.
 * @param view The current view.
 * 
 * @return YES if the code is read, otherwise NO.
 */
- (BOOL)read:(NSString *)code view:(UIView *)view;

@end