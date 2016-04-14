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

#import <Foundation/Foundation.h>

/*!
 * Subclass of UIActionSheet that accepts a block for handling button clicks rather than requiring a UIActionSheetDelegate.
 *
 * When the project's minimum supported version of iOS moves up to 8, UIAlertController can be used in favour of this class.
 */
@interface FRABlockActionSheet : UIActionSheet

/*!
 * Block that is invoked when the UIActionSheetDelegate actionSheet:clickedButtonAtIndex: method is called.
 * @param offset The index of the button that was clicked.
 */
@property (nonatomic, copy) void (^callback)(NSInteger offset);

@end