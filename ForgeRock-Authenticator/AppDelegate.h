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
 * Portions Copyright 2013 Nathaniel McCallum, Red Hat
 */

/*!
 * Primary delegate to which iOS application events are delegated.
 *
 * @see ForgeRock-Authenticator/main.m (grouped under 'Supporting Files' in Xcode)
 */
@interface AppDelegate : UIResponder <UIApplicationDelegate>

/*!
 * The window used to present the app's visual content on the device's main screen.
 * @see UIApplicationDelegate
 */
@property (strong, nonatomic) UIWindow *window;

/*!
 * Magic method for bootstrapping Typhoon dependency injection.
 *
 * @see https://github.com/appsquickly/Typhoon/wiki/AppDelegate-Integration
 */
- (id)initialFactory;

@end
