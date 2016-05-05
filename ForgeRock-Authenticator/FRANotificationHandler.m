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

static NSString const *TTL_KEY = @"timeToLive";
static NSString const *MESSAGE_ID_KEY = @"messageId";
static NSString const *CHALLENGE_KEY = @"challenge";
static NSString const *MECHANISM_UID_KEY = @"mechanismUID";

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

- (void)handleRemoteNotification:(NSDictionary *)messageData {

    NSTimeInterval timeToLive = [[messageData objectForKey:TTL_KEY] doubleValue];
    
    FRANotification *notification = [[FRANotification alloc] initWithDatabase:_database
                                                                    messageId:[messageData objectForKey:MESSAGE_ID_KEY]
                                                                    challenge:[messageData objectForKey:CHALLENGE_KEY]
                                                                 timeReceived:[NSDate date]
                                                                          timeToLive:timeToLive];
    
    NSInteger mechanismId = [[messageData objectForKey:MECHANISM_UID_KEY] intValue];
    FRAMechanism* mechanism = [_identityModel mechanismWithId:mechanismId];
    
    if (mechanism && [mechanism isKindOfClass:[FRAPushMechanism class]]) {
        [mechanism addNotification:notification];
    }
}

@end
