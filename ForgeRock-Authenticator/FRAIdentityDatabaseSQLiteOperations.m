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

#import "FMDatabase.h"
#import "FRAError.h"
#import "FRAHMACAlgorithm.h"
#import "FRAIdentity.h"
#import "FRAIdentityDatabaseSQLiteOperations.h"
#import "FRAMechanism.h"
#import "FRANotification.h"
#import "FRAOathCode.h"
#import "FRAOathMechanism.h"
#import "FRAPushMechanism.h"
#import "FRAFMDatabaseConnectionHelper.h"
#import "FRASerialization.h"

@implementation FRAIdentityDatabaseSQLiteOperations {
    FRAFMDatabaseConnectionHelper *sqlDatabase;
}

#pragma mark -
#pragma Life cycle Functions

- (instancetype)initWithDatabase:(FRAFMDatabaseConnectionHelper *)database {
    self = [super init];
    if (self) {
        sqlDatabase = database;
    }
    return self;
}

#pragma mark -
#pragma SQL Functions

- (BOOL)performStatement:(NSString *)schema withValues:(NSArray *)values error:(NSError * __autoreleasing *)error {
    // Get schema
    NSString *sql = [FRAFMDatabaseConnectionHelper readSchema:schema withError:error];
    if (sql == nil) {
        return NO;
    }
    
    // Open Database
    FMDatabase *database;
    @try {
        database = [sqlDatabase getConnectionWithError:error];
        if (database == nil) {
            return NO;
        }
        
        // Perform update
        BOOL result = [database executeUpdate:sql values:values error:error];
        NSLog(@"Result: %@\nValues: %@\nSQL: %@", result ? @"YES" : @"NO", values, sql);
        return result;
    }
    @finally {
        [sqlDatabase closeConnectionToDatabase:database];
    }
}

#pragma mark -
#pragma mark Identity Functions

- (BOOL)insertIdentity:(FRAIdentity *)identity error:(NSError *__autoreleasing *)error {
    NSMutableArray *arguments = [[NSMutableArray alloc] init];
    // Issuer
    [arguments addObject:[FRASerialization nonNilString:identity.issuer]];
    
    // Account Name
    [arguments addObject:[FRASerialization nonNilString:identity.accountName]];
    
    // Image URL
    if (identity.image) {
        NSURL *imageUrl = identity.image;
        [arguments addObject:[imageUrl absoluteString]];
    } else {
        [arguments addObject:[NSNull null]];
    }
    
    // Background Color
    if (identity.backgroundColor) {
        [arguments addObject:identity.backgroundColor];
    } else {
        [arguments addObject:[NSNull null]];
    }
    
    return [self performStatement:@"insert_identity" withValues:arguments error:error];
}

- (BOOL)deleteIdentity:(FRAIdentity *)identity error:(NSError *__autoreleasing *)error {
    NSMutableArray* arguments = [[NSMutableArray alloc] init];
    
    // Issuer
    [arguments addObject:[FRASerialization nonNilString:identity.issuer]];
    
    // Account Name
    [arguments addObject:[FRASerialization nonNilString:identity.accountName]];
    
    return [self performStatement:@"delete_identity" withValues:arguments error:error];
}

#pragma mark -
#pragma mark Mechanism Functions

- (BOOL)insertMechanism:(FRAMechanism *)mechanism error:(NSError *__autoreleasing *)error {
    NSMutableArray *arguments = [[NSMutableArray alloc] init];
    
    FRAIdentity *parent = mechanism.parent;
    
    // idIssuer
    [arguments addObject:[FRASerialization nonNilString:parent.issuer]];
    
    // idAccountName
    [arguments addObject:[FRASerialization nonNilString:parent.accountName]];
    
    // mechanismUID - Special case for PushMechanism
    if ([mechanism isKindOfClass:[FRAOathMechanism class]]) {
        [arguments addObject:[NSNull null]];
    } else if ([mechanism isKindOfClass:[FRAPushMechanism class]]) {
        FRAPushMechanism* pushMechanism = (FRAPushMechanism*)mechanism;
        [arguments addObject:[FRASerialization nonNilString:pushMechanism.mechanismUID]];
    } else {
        @throw [FRAError createIllegalStateException:@"Unrecognised class of Mechanism"];
    }
    
    // type
    NSString *type;
    if ([mechanism isKindOfClass:[FRAOathMechanism class]]) {
        FRAOathMechanism *oathMechanism = (FRAOathMechanism *)mechanism;
        type = oathMechanism.type;
    } else if ([mechanism isKindOfClass:[FRAPushMechanism class]]) {
        FRAPushMechanism *pushMechanism = (FRAPushMechanism *)mechanism;
        type = pushMechanism.type;
    } else {
        @throw [FRAError createIllegalStateException:@"Unrecognised class of Mechanism"];
    }
    [arguments addObject:[FRASerialization nonNilString:type]];

    // Version
    NSInteger version;
    if ([mechanism isKindOfClass:[FRAOathMechanism class]]) {
        FRAOathMechanism *oathMechanism = (FRAOathMechanism *)mechanism;
        version = oathMechanism.version;
    } else if ([mechanism isKindOfClass:[FRAPushMechanism class]]) {
        FRAPushMechanism *pushMechanism = (FRAPushMechanism *)mechanism;
        version = pushMechanism.version;
    } else {
        @throw [FRAError createIllegalStateException:@"Unrecognised class of Mechanism"];
    }
    [arguments addObject:[NSNumber numberWithInteger:version]];
    
    // Options
    NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
    if ([mechanism isKindOfClass:[FRAOathMechanism class]]) {
        FRAOathMechanism *oathMechanism = (FRAOathMechanism *)mechanism;
        
        // Secret Key
        NSString *base64Key = [FRASerialization serializeBytes:oathMechanism.secretKey];
        [options setObject:[FRASerialization nonNilString:base64Key] forKey:OATH_MECHANISM_SECRET];
        
        // Algorithm
        NSString *algorithm = [FRAHMACAlgorithm asString:oathMechanism.algorithm];
        [options setObject:[FRASerialization nonNilString:algorithm] forKey:OATH_MECHANISM_ALGORITHM];

        // Digits
        NSString *digitsString = [[NSNumber numberWithUnsignedInteger:oathMechanism.digits] stringValue];
        [options setObject:[FRASerialization nonNilString:digitsString] forKey:OATH_MECHANISM_DIGITS];
        
        // Period
        NSString *periodString = [[NSNumber numberWithUnsignedInteger:oathMechanism.period] stringValue];
        [options setObject:[FRASerialization nonNilString:periodString] forKey:OATH_MECHANISM_PERIOD];
        
        // Counter
        NSString *counterString = [[NSNumber numberWithUnsignedLongLong:oathMechanism.counter] stringValue];
        [options setObject:[FRASerialization nonNilString:counterString] forKey:OATH_MECHANISM_COUNTER];
        
    } else if ([mechanism isKindOfClass:[FRAPushMechanism class]]) {
        
        FRAPushMechanism *pushMechanism = (FRAPushMechanism *)mechanism;
        
        // Secret Key as String
        [options setObject:[FRASerialization nonNilString:pushMechanism.secret] forKey:PUSH_MECHANISM_SECRET];
        
        // Auth Endpoint as String
        [options setObject:[FRASerialization nonNilString:pushMechanism.authEndpoint] forKey:PUSH_MECHANISM_AUTH_END_POINT];
        
        // Version integer as String
        NSString *versionString = [[NSNumber numberWithInteger:pushMechanism.version] stringValue];
        [options setObject:[FRASerialization nonNilString:versionString] forKey:PUSH_MECHANISM_VERSION];
        
    } else {
        @throw [FRAError createIllegalStateException:@"Unrecognised class of Mechanism"];
    }
    
    // Convert options to JSON
    NSString *jsonString;
    if (![FRASerialization serializeMap:options intoString:&jsonString error:error]) {
        return NO;
    }
    [arguments addObject:jsonString];

    return [self performStatement:@"insert_mechanism" withValues:arguments error:error];
}

- (BOOL)deleteMechanism:(FRAMechanism *)mechanism error:(NSError *__autoreleasing *)error {
    NSMutableArray *arguments = [[NSMutableArray alloc] init];
    
    FRAIdentity *parent = mechanism.parent;
    
    // Issuer
    [arguments addObject:[FRASerialization nonNilString:parent.issuer]];
    
    // Account Name
    [arguments addObject:[FRASerialization nonNilString:parent.accountName]];
    
    // Type
    NSString *type;
    if ([mechanism isKindOfClass:[FRAOathMechanism class]]) {
        FRAOathMechanism *oathMechanism = (FRAOathMechanism *)mechanism;
        type = oathMechanism.type;
    } else if ([mechanism isKindOfClass:[FRAPushMechanism class]]) {
        FRAPushMechanism *pushMechanism = (FRAPushMechanism *)mechanism;
        type = pushMechanism.type;
    } else {
        @throw [FRAError createIllegalStateException:@"Unrecognised class of Mechanism"];
    }
    [arguments addObject:[FRASerialization nonNilString:type]];
    
    return [self performStatement:@"delete_mechanism" withValues:arguments error:error];
}

- (BOOL)updateMechanism:(FRAMechanism *)mechanism error:(NSError *__autoreleasing *)error {
    return [self insertMechanism:mechanism error:error];
}

#pragma mark -
#pragma mark Notification Functions

- (BOOL)insertNotification:(FRANotification *)notification error:(NSError *__autoreleasing *)error {
    NSMutableArray* arguments = [[NSMutableArray alloc] init];
    
    FRAMechanism *parent = notification.parent;
    // mechanismUID
    NSString *mechanismUID;
    if ([parent isKindOfClass:[FRAOathMechanism class]]) {
        mechanismUID = nil;
    } else if ([parent isKindOfClass:[FRAPushMechanism class]]) {
        FRAPushMechanism *pushMechanism = (FRAPushMechanism *)parent;
        mechanismUID = pushMechanism.mechanismUID;
    } else {
        @throw [[NSException alloc] initWithName:@"Illegal State" reason:@"Unrecognised class of Mechanism" userInfo:nil];
    }
    [arguments addObject:[FRASerialization nonNilString:mechanismUID]];
    
    // timeReceived
    [arguments addObject:[FRASerialization nonNilDate:notification.timeReceived]];
    
    // timeExpired
    [arguments addObject:[FRASerialization nonNilDate:notification.timeExpired]];
    
    // Data Json Map
    NSMutableDictionary *dataMap = [[NSMutableDictionary alloc] init];
    
    // Data: Message ID
    [dataMap setObject:notification.messageId forKey:NOTIFICATION_MESSAGE_ID];
    
    // Data: Push Challenge
    [dataMap setObject:notification.challenge forKey:NOTIFICATION_PUSH_CHALLENGE];
    
    // Data: Time to Live
    NSString *ttlString = [NSString stringWithFormat:@"%f", notification.timeToLive];
    [dataMap setObject:ttlString forKey:NOTIFICATION_TIME_TO_LIVE];
    
    // Convert map to JSON
    NSString *jsonString;
    if (![FRASerialization serializeMap:dataMap intoString:&jsonString error:error]) {
        return NO;
    }
    [arguments addObject:jsonString];
    
    // pending
    [arguments addObject:[NSNumber numberWithBool:[notification isPending]]];
    
    // approved
    [arguments addObject:[NSNumber numberWithBool:[notification isApproved]]];
    
    return [self performStatement:@"insert_notification" withValues:arguments error:error];
}

- (BOOL)deleteNotification:(FRANotification *)notification error:(NSError *__autoreleasing *)error {
    NSMutableArray *arguments = [[NSMutableArray alloc] init];
    
    FRAMechanism *parent = notification.parent;
    
    // mechanismUID
    NSString *mechanismUID;
    if ([parent isKindOfClass:[FRAOathMechanism class]]) {
        mechanismUID = nil;
    } else if ([parent isKindOfClass:[FRAPushMechanism class]]) {
        FRAPushMechanism *pushMechanism = (FRAPushMechanism *)parent;
        mechanismUID = pushMechanism.mechanismUID;
    } else {
        @throw [[NSException alloc] initWithName:@"Illegal State" reason:@"Unrecognised class of Mechanism" userInfo:nil];
    }
    [arguments addObject:[FRASerialization nonNilString:mechanismUID]];
    
    // timeReceived
    [arguments addObject:[FRASerialization nonNilDate:notification.timeReceived]];
    
    return [self performStatement:@"delete_notification" withValues:arguments error:error];
}

- (BOOL)updateNotification:(FRANotification *)notification error:(NSError *__autoreleasing *)error {
    return [self insertNotification:notification error:error];
}


@end
