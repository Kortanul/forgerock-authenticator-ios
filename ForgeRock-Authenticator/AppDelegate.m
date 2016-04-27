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
#import "FRAIdentity.h"
#import "FRAIdentityDatabase.h"
#import "FRAMechanismFactory.h"
#import "FRANotificationGateway.h"
#import "FRAOathMechanism.h"
#import "FRAPushMechanism.h"


@implementation AppDelegate

#pragma mark -
#pragma mark UIApplicationDelegate - application lifecycle state changes

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[self notificationGateway] application:application didFinishLaunchingWithOptions:launchOptions];
    [self populateWithDummyData];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[self notificationGateway] applicationDidBecomeActive:application];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[self notificationGateway] applicationDidEnterBackground:application];
}

#pragma mark -
#pragma mark UIApplicationDelegate - handling remote notifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[self notificationGateway] application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [[self notificationGateway] application:application didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[self notificationGateway] application:application didReceiveRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    [[self notificationGateway] application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler {
    [[self notificationGateway] application:application handleActionWithIdentifier:identifier forRemoteNotification:userInfo completionHandler:completionHandler];
}

#pragma mark -
#pragma mark UIApplicationDelegate - opening a URL-specified resource

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // Create mechanism from URL
    FRAMechanismFactory* factory = [self mechanismFactory];
    FRAMechanism* mechanism = [factory parseFromURL:url];
    if (mechanism == nil) {
        return NO;
    }
    // Save the mechanism
    [[self identityDatabase] addMechanism:mechanism];
    // Reload the view
    [self.window.rootViewController loadView];
    return YES;
}

#pragma mark -
#pragma mark AppDelegate (private)

- (id)initialFactory {
    TyphoonComponentFactory *factory = [[TyphoonBlockComponentFactory alloc] initWithAssembly:[FRAApplicationAssembly assembly]];
    [factory makeDefault];
    return factory;
}

- (FRAIdentityDatabase*)identityDatabase {
    FRAApplicationAssembly* assembly = (FRAApplicationAssembly*) [TyphoonComponentFactory defaultFactory];
    return [assembly identityDatabase];
}

- (FRAMechanismFactory*)mechanismFactory {
    FRAApplicationAssembly* assembly = (FRAApplicationAssembly*) [TyphoonComponentFactory defaultFactory];
    return [assembly mechanismFactory];
}

- (FRANotificationGateway*)notificationGateway {
    FRAApplicationAssembly* assembly = (FRAApplicationAssembly*) [TyphoonComponentFactory defaultFactory];
    return [assembly notificationGateway];
}

- (void)populateWithDummyData {
    FRAMechanismFactory* factory = [self mechanismFactory];
    
    FRAMechanism* oathMechanism = [factory parseFromURL:[NSURL URLWithString:@"otpauth://totp/Forgerock:Alice?secret=ZIFYT2GJ5UDGYCBYJ777PFBPSM======&issuer=Forgerock&digits=6&period=30"]];
    if (oathMechanism != nil) {
        [[self identityDatabase] addMechanism:oathMechanism];
    }
    
    FRAIdentity* identity = oathMechanism.parent;
    
    FRAPushMechanism* pushMechanism = [[FRAPushMechanism alloc] init];
    [identity addMechanism:pushMechanism];
}

@end
