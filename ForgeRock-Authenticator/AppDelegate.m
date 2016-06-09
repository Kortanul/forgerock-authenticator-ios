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

#import "AppDelegate.h"
#import "FRAApplicationAssembly.h"
#import "FRAError.h"
#import "FRAIdentity.h"
#import "FRAIdentityDatabase.h"
#import "FRAIdentityModel.h"
#import "FRAMechanismReaderAction.h"
#import "FRAUriMechanismReader.h"
#import "FRANotification.h"
#import "FRANotificationGateway.h"
#import "FRAOathMechanism.h"
#import "FRAPushMechanism.h"


@implementation AppDelegate

#pragma mark -
#pragma mark UIApplicationDelegate - application lifecycle state changes

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"application:willFinishLaunchingWithOptions:%@", launchOptions);
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[[self assembly] notificationGateway] application:application didFinishLaunchingWithOptions:launchOptions];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleIdentityDatabaseChanged:) name:FRAIdentityDatabaseChangedNotification object:nil];
    [self updateNotificationsCount];
    NSLog(@"application:didFinishLaunchingWithOptions\n%@", launchOptions);
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"applicationWillTerminate:");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark UIApplicationDelegate - handling remote notifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"application:didRegisterForRemoteNotificationsWithDeviceToken:");
    [[[self assembly] notificationGateway] application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"application:didFailToRegisterForRemoteNotificationsWithError:");
    [[[self assembly] notificationGateway] application:application didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"application:didReceiveRemoteNotification:");
    [[[self assembly] notificationGateway] application:application didReceiveRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    NSLog(@"application:didReceiveRemoteNotification:fetchCompletionHandler:");
    [[[self assembly] notificationGateway] application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
}

#pragma mark -
#pragma mark UIApplicationDelegate - opening a URL-specified resource

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    NSLog(@"application:openURL:sourceApplication:annotation:");
    // Create mechanism from URL
    @autoreleasepool {
        NSError *error;
        FRAMechanismReaderAction *mechanismReaderAction = [[self assembly] mechanismReaderAction];
        BOOL result = [mechanismReaderAction read:url.absoluteString error:&error];
        if (result) {
            // Reload the view
            [self.window.rootViewController loadView];
        }
        
        return result;
    }
}

#pragma mark -
#pragma mark AppDelegate (private)

- (id)initialFactory {
    TyphoonComponentFactory *factory = [[TyphoonBlockComponentFactory alloc] initWithAssembly:[FRAApplicationAssembly assembly]];
    [factory makeDefault];
    return factory;
}

- (FRAApplicationAssembly *)assembly {
    return (FRAApplicationAssembly *) [TyphoonComponentFactory defaultFactory];
}

- (void)handleIdentityDatabaseChanged:(NSNotification *)notification {
    NSLog(@"database changed: %@", notification.userInfo);
    [self updateNotificationsCount];
}

- (void)updateNotificationsCount {
    [UIApplication sharedApplication].applicationIconBadgeNumber = [[[self assembly] identityModel] pendingNotificationsCount];
}

@end
