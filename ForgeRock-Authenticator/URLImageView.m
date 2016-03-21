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

#import "URLImageView.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation URLImageView

- (void)setUrl:(NSURL *)url {
    _url = url;

    if (url.isFileURL) {
        self.image = [UIImage imageWithContentsOfFile:url.path];
        return;
    }

    if ([url.scheme isEqualToString:@"assets-library"]) {
        ALAssetsLibrary* al = [[ALAssetsLibrary alloc] init];
        [al assetForURL:url
            resultBlock:^(ALAsset *asset) {
                ALAssetRepresentation *rep = [asset defaultRepresentation];
                @autoreleasepool {
                    CGImageRef iref = [rep fullScreenImage];
                    if (iref) {
                        UIImage *image = [UIImage imageWithCGImage:iref];
                        self.image = image;
                        iref = nil;
                    }
                }
            }
           failureBlock:nil];
        return;
    }
}

@end
