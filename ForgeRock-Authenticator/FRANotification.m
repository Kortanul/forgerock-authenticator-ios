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

#import "FRADateUtils.h"
#import "FRAIdentityDatabase.h"
#import "FRAMessageUtils.h"
#import "FRAModelObjectProtected.h"
#import "FRANotification.h"
#import "FRAPushMechanism.h"

/*!
 * All notifications are expected to be able to transition from the initial state
 * of pending, to the final state of approved or denied.
 */
@implementation FRANotification {
    NSDateFormatter *formatter;
    BOOL _approved;
    BOOL _pending;
}

@synthesize approved = _approved;
@synthesize pending = _pending;

- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel messageId:(NSString *)messageId challenge:(NSString *)challenge timeReceived:(NSDate *)timeReceived timeToLive:(NSTimeInterval)timeToLive loadBalancerCookieData:(NSString *)loadBalancerCookie pending:(BOOL)pendingState approved:(BOOL)approvedState {
    self = [super initWithDatabase:database identityModel:identityModel];
    if (self) {
        _pending = pendingState;
        _approved = approvedState;
        
        _messageId = messageId;
        _challenge = challenge;
        _timeReceived = timeReceived;
        _timeToLive = timeToLive;
        _timeExpired = [timeReceived dateByAddingTimeInterval:timeToLive];
        _loadBalancerCookie = loadBalancerCookie;
    }
    return self;
}

- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel messageId:(NSString *)messageId challenge:(NSString *)challenge timeReceived:(NSDate *)timeReceived timeToLive:(NSTimeInterval)timeToLive loadBalancerCookieData:(NSString *)loadBalancerCookie{
    return [self initWithDatabase:database identityModel:identityModel messageId:messageId challenge:challenge timeReceived:timeReceived timeToLive:timeToLive loadBalancerCookieData:loadBalancerCookie pending:YES approved:NO];
}

+ (instancetype)notificationWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel messageId:(NSString *)messageId challenge:(NSString *)challenge timeReceived:(NSDate *)timeReceived timeToLive:(NSTimeInterval)timeToLive loadBalancerCookieData:(NSString *)loadBalancerCookie pending:(BOOL)pendingState approved:(BOOL)approvedState{
    return [[FRANotification alloc] initWithDatabase:database identityModel:identityModel messageId:messageId challenge:challenge timeReceived:timeReceived timeToLive:timeToLive loadBalancerCookieData:loadBalancerCookie pending:pendingState approved:approvedState];
}

+ (instancetype)notificationWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel messageId:(NSString *)messageId challenge:(NSString *)challenge timeReceived:(NSDate *)timeReceived timeToLive:(NSTimeInterval)timeToLive loadBalancerCookieData:(NSString *)loadBalancerCookie{
    return [[FRANotification alloc] initWithDatabase:database identityModel:identityModel messageId:messageId challenge:challenge timeReceived:timeReceived timeToLive:timeToLive loadBalancerCookieData:loadBalancerCookie pending:YES approved:NO];
}

- (NSString *)age {
    return [[[FRADateUtils alloc] init] ageOfEventTime:self.timeReceived];
}

- (BOOL)approveWithHandler:(void (^)(NSInteger, NSError *))handler error:(NSError *__autoreleasing*)error {
    return [self sendAuthenticationResponse:YES handler:handler error:error];
}

- (BOOL)denyWithHandler:(void (^)(NSInteger, NSError *))handler error:(NSError *__autoreleasing*)error {
    return [self sendAuthenticationResponse:NO handler:handler error:error];
}

- (BOOL)sendAuthenticationResponse:(BOOL)approved handler:(void (^)(NSInteger, NSError *))handler error:(NSError *__autoreleasing*)error {
    _approved = approved;
    _pending = NO;
    if ([self isStored]) {
        if (![self.database updateNotification:self error:error]) {
            return NO;
        }
        FRAPushMechanism *mechanism = (FRAPushMechanism *)self.parent;
        if (mechanism) {
            NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
            data[@"response"] = [FRAMessageUtils generateChallengeResponse:self.challenge secret:mechanism.secret];
            if (!approved) {
                data[@"deny"] = @YES;
            }
            [FRAMessageUtils respondWithEndpoint:mechanism.authEndpoint
                                    base64Secret:mechanism.secret
                                       messageId:self.messageId
                                    loadBalancerCookieData:self.loadBalancerCookie
                                            data:data
                                         handler:handler];
        }
    }
    return YES;
}

- (BOOL)isPending {
    return _pending && ![self isExpired];
}

- (BOOL)isExpired {
    return _pending && [[NSDate date] timeIntervalSinceDate:_timeExpired] > 0;
}

- (BOOL)isApproved {
    return !_pending && _approved;
}

- (BOOL)isDenied {
    return !_pending && !_approved;
}

@end
