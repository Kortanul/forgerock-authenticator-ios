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

#import <UIImageView+AFNetworking.h>

#import "FRAUIUtils.h"

static NSString * const FRA_DEFAULT_BACKGROUND_COLOR = @"#519387";

@implementation FRAUIUtils

+ (void)setImage:(UIImageView *)image fromIssuerLogoURL:(NSURL *)imageUrl {
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:imageUrl
                                                  cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                              timeoutInterval:60];
    [image setImageWithURLRequest:imageRequest
                 placeholderImage:[UIImage imageNamed:@"forgerock-logo.png"]
                          success:nil
                          failure:nil];
}

+ (void)setView:(UIView *)view issuerBackgroundColor:(NSString *)backgroundColor {
    UIColor *color;
    if ([backgroundColor length] == 0) {
        color = [FRAUIUtils convertHexToColor:FRA_DEFAULT_BACKGROUND_COLOR];
    } else {
        color = [FRAUIUtils convertHexToColor:backgroundColor];
    }
    view.backgroundColor = color;
}

+ (UIColor *)convertHexToColor:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSString *hex = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    NSScanner *scanner = [NSScanner scannerWithString:hex];
    [scanner scanHexInt:&rgbValue];
    
    return [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
                           green:((float)((rgbValue & 0x00FF00) >>  8))/255.0 \
                            blue:((float)((rgbValue & 0x0000FF) >>  0))/255.0 \
                           alpha:1.0];
}

@end
