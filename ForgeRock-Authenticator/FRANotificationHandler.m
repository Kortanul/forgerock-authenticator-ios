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

#import "FRAIdentity.h"
#import "FRAIdentityModel.h"
#import "FRAPushMechanism.h"
#import "FRANotification.h"
#import "FRANotificationHandler.h"

/*!
 * Private interface.
 */
@interface FRANotificationHandler ()

/*!
 * The identity model.
 */
@property (nonatomic, strong, readonly) FRAIdentityModel *identityModel;

@end


@implementation FRANotificationHandler {
    
    FRAIdentityDatabase *_database;
    
}

#pragma mark -
#pragma mark Lifecycle

- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel {
    self = [super init];
    if (self) {
        _database = database;
        _identityModel = identityModel;
    }
    return self;
}

+ (instancetype)handlerWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel {
    return [[FRANotificationHandler alloc] initWithDatabase:database identityModel:identityModel];
}

#pragma mark -
#pragma mark Remote Notifications

- (void)handleRemoteNotification:(NSDictionary *)userInfo {

    NSLog(@"first %@", [userInfo objectForKey:@"first"]);
    NSLog(@"second %@", [userInfo objectForKey:@"second"]);

    // TODO: Read relevant attributes from userInfo (object graph representation of JSON notification)
    //       and populate FRANotification appropriately.

    FRANotification *notification = [[FRANotification alloc] initWithDatabase:_database];

    // Until registration & mechanismIds are implemented, just add the notification to the dummy push mechanism on Alice

    FRAPushMechanism* dummyPushMechanism = nil;
    for (FRAIdentity* identity in [self.identityModel identities]) {
        for (FRAMechanism* mechanism in identity.mechanisms) {
            if ([mechanism isKindOfClass:[FRAPushMechanism class]]) {
                dummyPushMechanism = (FRAPushMechanism *) mechanism;
                break;
            }
        }
        if (dummyPushMechanism) {
            break;
        }
    }
    [dummyPushMechanism addNotification:notification];
}

@end
