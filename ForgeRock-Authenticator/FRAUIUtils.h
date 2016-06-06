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

/*!
 * Utility class for common UI functions.
 */
@interface FRAUIUtils : NSObject

/*!
 * Assigns image at imageUrl to UIImageView object. The download process is handled asynchronously and the ForgeRock
 * logo is used as a placeholder while the actual logo is downloaded. The downloaded image will be cached.
 *
 * @param image    The UIImageView to update.
 * @param imageUrl The URL of the image to download. If imageUrl is nil, then the ForgeRock logo will be displayed.
 */
+ (void)setImage:(UIImageView *)image fromIssuerLogoURL:(NSURL *)imageUrl;

/*!
 * Sets the background color of the UIView object from backgroundColor. If backgroundColor is nil then the default
 * background color of #519387 is used.
 *
 * @param view            The UIView to update.
 * @param backgroundColor The RGB hex encoded background color. If nil, then the default #519387 is used.
 */
+ (void)setView:(UIView *)view issuerBackgroundColor:(NSString *)backgroundColor;

@end
