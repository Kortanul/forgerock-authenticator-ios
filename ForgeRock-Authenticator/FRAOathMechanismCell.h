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

#import "CircleProgressView.h"
#import "FRAOathMechanism.h"
#import "FRAOathCode.h"
#import "URLImageView.h"

/*!
 * UI element for interaction with OATH authentication mechanism in collection view.
 */
@interface FRAOathMechanismCell : UICollectionViewCell

/*!
 * The storage ID of the OATH mechanism shown by this cell.
 */
@property (nonatomic) NSInteger mechanismId;
/*!
 * Value object encapsulating state relating to an OATH code.
 */
@property (strong, nonatomic) FRAOathCode* state;
/*!
 * The image view in which the issuer logo will be displayed.
 */
@property (weak, nonatomic) IBOutlet URLImageView *image;
/*!
 * The label in which the OATH code will be displayed.
 */
@property (weak, nonatomic) IBOutlet UILabel *code;
/*!
 * The label in which the name of the issuer (identity provider) will be displayed.
 */
@property (weak, nonatomic) IBOutlet UILabel *issuer;
/*!
 * The label in which the account name will be displayed.
 */
@property (weak, nonatomic) IBOutlet UILabel *label;
/*!
 * The label in which the OATH code placeholder will be displayed when no code is shown.
 */
@property (weak, nonatomic) IBOutlet UILabel *placeholder;
/*!
 * The outer circle showing time remaining for the currently displayed series of time-based OATH codes.
 */
@property (weak, nonatomic) IBOutlet CircleProgressView *outer;
/*!
 * The inner circle showing time remaining for the currently displayed time-based OATH code.
 */
@property (weak, nonatomic) IBOutlet CircleProgressView *inner;

- (BOOL)bind:(FRAOathMechanism*)mechanism;

@end
