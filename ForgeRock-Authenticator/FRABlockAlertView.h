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
 * Portions Copyright 2014 Nathaniel McCallum, Red Hat
 */

/*!
 * Subclass of UIAlertView that accepts a block for handling button clicks rather than requiring a UIAlertViewDelegate.
 *
 * When the project's minimum supported version of iOS moves up to 8, UIAlertController can be used in favour of this class.
 */
@interface FRABlockAlertView : UIAlertView

/*!
 * Convenience method for initializing a block alert view.
 *
 * @param title The string that appears in the receiver’s title bar.
 * @param message Descriptive text that provides more details than the title.
 * @param delegate The receiver’s delegate or nil if it doesn’t have a delegate.
 * @param cancelButtonTitle The title of the cancel button or nil if there is no cancel button.
 * @param otherButtonTitle The title of another button.
 * @param handler The handler to be invoked when one of the buttons is clicked.
 *
 * @return Newly initialized block alert view.
 */
- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitle:(NSString *)otherButtonTitle handler:(void (^)(NSInteger))handler;

@end
