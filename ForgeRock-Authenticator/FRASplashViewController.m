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

#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

#import "FRAAccountsTableViewController.h"
#import "FRAError.h"
#import "FRAIdentityModel.h"
#import "FRASplashEvents.h"
#import "FRASplashViewController.h"


static NSString * const FRAAccountsViewControllerStoryboardIdentifier = @"AccountsViewController";

// Used for monitoring the rate property on the AVPlayer
static NSString * const AVPLAYER_RATE = @"rate";


@interface FRASplashViewController ()

@end


@implementation FRASplashViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Ensures background color and video first frame are equal.
    self.view.backgroundColor = [UIColor whiteColor];
    
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // If we have some Identities already, do not show the splash screen.
    if (![self.identityModel isEmpty]) {
        [self proceed];
        return;
    }
    
    NSURL *videoURL;
    NSBundle *bundle = [NSBundle mainBundle];
    if (bundle) {
        NSString *path = [bundle pathForResource:@"splashvideo" ofType:@"mp4"];
        if (path == nil) {
            [self proceed];
            return;
        }
        videoURL = [NSURL fileURLWithPath:path];
    }
    
    // Configure the video player
    AVPlayer *player = [AVPlayer playerWithURL:videoURL];
    player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
    [player addObserver:self forKeyPath:AVPLAYER_RATE options:NSKeyValueObservingOptionNew context:NULL];
    
    // Prepare the view which will contain the video player
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.backgroundColor = (__bridge CGColorRef _Nullable)(self.view.backgroundColor);
    playerLayer.frame = self.view.bounds;
    
    // Requests the video fills the display area, no scaling.
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;

    [self.view.layer addSublayer:playerLayer];
    
    [player play];
}

/*!
 * Listener to respond to changes from the video player.
 * 
 * Tracking the "rate" status of the video playback is the recommended way to determine
 * when the video has completed playback.
 *
 * Once playback is complete, or there is an error transition to the next view.
 */
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context {

    if (![keyPath isEqualToString:AVPLAYER_RATE]) {
        return;
    }

    AVPlayer *player = (AVPlayer *)object;
    float rate = [change[NSKeyValueChangeNewKey] floatValue];
    
    BOOL ready = player.currentItem.status == AVPlayerItemStatusReadyToPlay;
    BOOL complete = ready && rate == 0;
    BOOL error = player.currentItem.error != nil;
    
    if (complete || error) {
        [player removeObserver:self forKeyPath:AVPLAYER_RATE];
        [self proceed];
    }
}

-(void)proceed {
    UIApplication *application = [UIApplication sharedApplication];
    UIViewController *rootViewController = application.delegate.window.rootViewController;
    UIStoryboard *storyboard = rootViewController.storyboard;
    UIViewController *accountsViewController = [storyboard instantiateViewControllerWithIdentifier:FRAAccountsViewControllerStoryboardIdentifier];
    application.delegate.window.rootViewController = accountsViewController;
    [[NSNotificationCenter defaultCenter] postNotificationName:FRASplashScreenDidFinish object:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
