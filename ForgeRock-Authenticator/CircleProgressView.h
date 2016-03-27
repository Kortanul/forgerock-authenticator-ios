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
 * MVC View for elapsed time as a doughnut or filled circle.
 */
@interface CircleProgressView : UIView

/*!
 * Flag for controlling whether the elapsed time is drawn as a doughnut or filled circle.
 */
@property (nonatomic) BOOL hollow;
/*!
 * Flag for controlling whether the elapsed time is grows clockwise or counter-clockwise.
 */
@property (nonatomic) BOOL clockwise;
/*!
 * Normalized value for adjusting color based on progress.
 */
@property (nonatomic) float threshold;
/*!
 * Normalized value for progress.
 */
@property (nonatomic) float progress;

@end
