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
#import "FRAIdentityModel.h"
#import "FRAMechanismFactory.h"
#import "FRANotification.h"
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
    [[[self assembly] notificationGateway] application:application didFinishLaunchingWithOptions:launchOptions];
    [self populateWithDummyData];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleIdentityDatabaseChanged:) name:FRAIdentityDatabaseChangedNotification object:nil];
    [self updateNotificationsCount];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[[self assembly] notificationGateway] applicationDidBecomeActive:application];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[[self assembly] notificationGateway] applicationDidEnterBackground:application];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark UIApplicationDelegate - handling remote notifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[[self assembly] notificationGateway] application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [[[self assembly] notificationGateway] application:application didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[[self assembly] notificationGateway] application:application didReceiveRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    [[[self assembly] notificationGateway] application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler {
    [[[self assembly] notificationGateway] application:application handleActionWithIdentifier:identifier forRemoteNotification:userInfo completionHandler:completionHandler];
}

#pragma mark -
#pragma mark UIApplicationDelegate - opening a URL-specified resource

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // Create mechanism from URL
    FRAMechanismFactory* factory = [[self assembly] mechanismFactory];
    FRAMechanism* mechanism = [factory parseFromURL:url];
    if (mechanism == nil) {
        return NO;
    }
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

- (FRAApplicationAssembly *) assembly {
    return (FRAApplicationAssembly*) [TyphoonComponentFactory defaultFactory];
}

- (void)populateWithDummyData {
    FRAMechanismFactory *factory = [[self assembly] mechanismFactory];
    FRAIdentityDatabase *database = [[self assembly] identityDatabase];
    
    [factory parseFromURL:[NSURL URLWithString:@"otpauth://totp/Umbrella-Corp:Alice?secret=ZIFYT2GJ5UDGYCBYJ777PFBPSM======&issuer=Umbrella-Corp&digits=6&period=30"]];
    
    [factory parseFromURL:[NSURL URLWithString:@"otpauth://hotp/Umbrella-Corp:Adam?secret=IJQWIZ3FOIQUEYLE&issuer=Umbrella-Corp&counter=0"]];
    
    FRAIdentity* bob = [FRAIdentity identityWithDatabase:database accountName:@"demo" issuer:@"Forgerock" image:nil];
    FRAPushMechanism* pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database];
    [bob addMechanism:pushMechanism];
    [pushMechanism addNotification:[[FRANotification alloc] initWithDatabase:database]];
    [pushMechanism addNotification:[[FRANotification alloc] initWithDatabase:database]];
    [[[self assembly] identityModel] addIdentity:bob];
}

- (void)handleIdentityDatabaseChanged:(NSNotification *)notification {
    NSLog(@"database changed notification received by app delegate");
    [self updateNotificationsCount];
}

- (void)updateNotificationsCount {
    NSInteger notificationsCount = 0;
    for (FRAIdentity *identity in [[[self assembly] identityModel] identities]) {
        for (FRAMechanism* mechanism in identity.mechanisms) {
            notificationsCount += mechanism.notifications.count;
        }
    }
    [UIApplication sharedApplication].applicationIconBadgeNumber = notificationsCount;
}

@end
