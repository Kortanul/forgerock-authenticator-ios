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

#import "FRAQRScanViewController.h"
#import "FRAIdentityDatabase.h"
#import "FRAMechanism.h"
#import "FRAMechanismFactory.h"
#import "FRAIdentity.h"

@implementation FRAQRScanViewController

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.session = [[AVCaptureSession alloc] init];
    AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    NSError* error = nil;
    AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (input == nil) {
        [self.navigationController popViewControllerAnimated:TRUE];
        return;
    }
    [self.session addInput:input];

    AVCaptureVideoPreviewLayer* preview = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    preview.frame = self.view.layer.bounds;
    [self.view.layer addSublayer:preview];

    [self.session startRunning];
}

- (void)viewDidAppear:(BOOL)animated {
    /* NOTE: We start output processing in viewDidAppear() to avoid a
     * race condition when the QR code is scanned before the view appears. */
    AVCaptureMetadataOutput* output = [[AVCaptureMetadataOutput alloc] init];
    [self.session addOutput:output];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
}

#pragma mark -
#pragma mark UINavigationController

-(BOOL)hidesBottomBarWhenPushed {
    return YES;
}

#pragma mark -
#pragma mark AVCaptureOutput

- (void)captureOutput:(AVCaptureOutput*)captureOutput didOutputMetadataObjects:(NSArray*)metadataObjects fromConnection:(AVCaptureConnection*) connection {
    for (AVMetadataObject *metadata in metadataObjects) {
        if ([metadata.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            NSString* qrcode = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
            if (qrcode == nil) {
                continue;
            }
            NSLog(@"Read QR URL: %@", qrcode);

            FRAMechanism* mechanism = [_mechanismFactory parseFromString:qrcode];
            
            if (mechanism != nil) {
                NSString* issuer = [[mechanism parent] issuer];
                NSString* accountName = [[mechanism parent] accountName];

                FRAIdentity* identity = [_database identityWithIssuer:issuer accountName:accountName];
                // Identity may not exist yet.
                if (identity == nil) {
                    [_database addIdentity:[mechanism parent]];
                }
                [_database addMechanism:mechanism];
            }
            [self.session stopRunning];
            if (self.popover == nil) {
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                [self.popover dismissPopoverAnimated:YES];
            }
            return;
        }
    }
}

@end
