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

#import "FRAAccountTableViewCell.h"

@implementation FRAAccountTableViewCell

#pragma mark -
#pragma mark UIView

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _notificationsBadge = [[M13BadgeView alloc] initWithFrame:CGRectMake(0, 0, 24.0, 24.0)];
        // add _notificationsBadge to _firstMechanismIcon in awakeFromNib as _firstMechanismIcon isn't yet set
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [_firstMechanismIcon addSubview:_notificationsBadge];
}

#pragma mark -
#pragma mark UITableViewCell

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    // hide mechanism icons while parent table view is being edited
    float mechanismIconsAlpha = editing ? 0.0f : 1.0f;
    if (animated) {
        [UIView animateWithDuration:0.5f animations:^{
            _firstMechanismIcon.alpha = mechanismIconsAlpha;
            _secondMechanismIcon.alpha = mechanismIconsAlpha;
        }];
    } else {
        _firstMechanismIcon.alpha = mechanismIconsAlpha;
        _secondMechanismIcon.alpha = mechanismIconsAlpha;
    }
}

#pragma mark -
#pragma mark FRAAccountTableViewCell (public)

- (void)updateForModelObject:(FRAIdentity*)identity {
    //  _image = ... // TODO: Use URLImageView
    _issuer.text = identity.issuer;
    _accountName.text = identity.accountName;
    _notificationsBadge.text = @"1";
    [self layoutIfNeeded];
}

@end
