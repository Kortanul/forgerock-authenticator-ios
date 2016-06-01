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
#import "FRAFMDatabaseConnectionHelper.h"
#import "FRAHMACAlgorithm.h"
#import "FRAIdentity.h"
#import "FRAModelObjectProtected.h"
#import "FRAModelsFromDatabase.h"
#import "FRANotification.h"
#import "FRAOathMechanism.h"
#import "FRAPushMechanism.h"
#import "FRASerialization.h"

/*!
*/
@implementation FRAModelsFromDatabase

/*!
 * The parsing logic operates as follows:
 * 
 * Perform SQL query to fetch all Identities, Mechanisms and Notifications where each
 * Identity may have multiple associated Mechanisms and PushMechanisms may have multiple
 * associated Notifications.
 *
 * The function will re-use matching Identities and Push Mechanisms as appropriate.
 *
 * TODO: Split into smaller functions.
 */
+ (NSArray<FRAIdentity*> *)getAllIdentitiesFrom:(FRAFMDatabaseConnectionHelper *)sqlDatabase including:(FRAIdentityDatabase *)identityDatabase identityModel:(FRAIdentityModel *)identityModel catchingErrorsWith:(NSError *__autoreleasing *)error {
    
    NSString *sql = [FRAFMDatabaseConnectionHelper readSchema:@"read_all" withError:error];
    if (!sql) {
        return nil;
    }
    
    // Open Database
    FMDatabase *database;
    @try {
        database = [sqlDatabase getConnectionWithError:error];
        if (!database) {
            return nil;
        }
        
        // Perform update
        FMResultSet *results = [database executeQuery:sql];
        if (!results) {
            [FRAError createErrorForLastFailure:database withError:error];
            return nil;
        }
        
        // Output rows for debugging purposes.
        // TODO: Sanitise data.
        NSLog(@"Reading all rows from the database:");
        
        NSMutableArray* identities = [[NSMutableArray alloc] init];
        
        int row = 0;
        while ([results next]) {
            // Identity
            NSString *issuer = [FRASerialization nullToEmpty:[results stringForColumn:@"issuer"]];
            NSString *accountName = [FRASerialization nullToEmpty:[results stringForColumn:@"accountName"]];
            NSString *imageURL = [FRASerialization nullToEmpty:[results stringForColumn:@"imageURL"]];
            NSString *bgColor = [FRASerialization nullToEmpty:[results stringForColumn:@"bgColor"]];
            // Mechanism
            NSString *type = [FRASerialization nullToEmpty:[results stringForColumn:@"type"]];
            NSInteger version = [results intForColumn:@"version"];
            NSString *mechanismUID = [FRASerialization nullToEmpty:[results stringForColumn:@"mechanismUID"]];
            NSString *optionsJSON = [FRASerialization nullToEmpty:[results stringForColumn:@"options"]];
            // Notification
            NSString *timeReceived = [FRASerialization nullToEmpty:[results stringForColumn:@"timeReceived"]];
            NSString *timeExpired = [FRASerialization nullToEmpty:[results stringForColumn:@"timeExpired"]];
            NSString *data = [FRASerialization nullToEmpty:[results stringForColumn:@"data"]];
            int pending = [results intForColumn:@"pending"];
            int approved = [results intForColumn:@"approved"];
            
            
            NSLog(@"[%d] %@  %@  %@  %@  %@  %ld  %@  %@  %@  %d  %d",
                  row,
                  issuer,
                  accountName,
                  imageURL,
                  bgColor,
                  type,
                  (long)version,
                  mechanismUID,
                  timeReceived,
                  timeExpired,
                  pending,
                  approved);
            row++;
            
            // Create an Identity
            FRAIdentity* newIdentity = [FRAIdentity
                                        identityWithDatabase:identityDatabase
                                        identityModel:identityModel
                                        accountName:accountName
                                        issuer:issuer
                                        image:[[NSURL alloc]initWithString:imageURL]
                                        backgroundColor:bgColor];
            
            // Check if we already have generated this identity, in which case re-use.
            BOOL add = true;
            for (FRAIdentity *identity in identities) {
                if ([newIdentity.issuer isEqualToString:identity.issuer] && [newIdentity.accountName isEqualToString:identity.accountName]) {
                    newIdentity = identity;
                    add = false;
                    break;
                }
            }
            
            if (add) {
                [identities addObject:newIdentity];
            }
            
            // Formatter for parsing numbers from Strings.
            NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
            numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
            
            // Create the Mechanism
            if ([type  isEqualToString:@"hotp"] || [type  isEqualToString:@"totp"]) {
                
                // TODO: Null checking on errors.
                
                // Options Map is a String to String mapping stored in JSON.
                NSDictionary *optionsMap;
                if (![FRASerialization deserializeJSON:optionsJSON intoDictionary:&optionsMap error:error]) {
                    return nil;
                }
                
                // Secret Key - Base 64 encoded bytes
                NSString *secretValue = [optionsMap objectForKey:OATH_MECHANISM_SECRET];
                NSData* secret = [FRASerialization deserializeBytes:secretValue];
                
                // Algorithm - String enumeration
                NSString *algorithmValue = [optionsMap objectForKey:OATH_MECHANISM_ALGORITHM];
                CCHmacAlgorithm algorithm = [FRAHMACAlgorithm fromString:algorithmValue];
                
                // Digits - String value of Integer
                NSString *digitsValue = [optionsMap objectForKey:OATH_MECHANISM_DIGITS];
                int digits = [[numberFormatter numberFromString:digitsValue] intValue];
                
                // Period - String value of unsigned Integer
                NSString *periodValue = [optionsMap objectForKey:OATH_MECHANISM_PERIOD];
                u_int32_t period = [[numberFormatter numberFromString:periodValue] unsignedIntValue];
                
                // Counter - String value of unsigned Long Long
                NSString *counterValue = [optionsMap objectForKey:OATH_MECHANISM_COUNTER];
                u_int64_t counter = [[numberFormatter numberFromString:counterValue] unsignedLongLongValue];
                
                FRAOathMechanism *newMechanism = [FRAOathMechanism
                                                  oathMechanismWithDatabase:identityDatabase
                                                  identityModel:identityModel
                                                  type:type
                                                  usingSecretKey:secret
                                                  andHMACAlgorithm:algorithm
                                                  withKeyLength:digits
                                                  andEitherPeriod:period
                                                  orCounter:counter];
                
                // Note: We are not de-duplicating OATH Mechanism becuase they will not be duplicated in the SQL results.
                if (![newIdentity addMechanism:newMechanism error:error]) {
                    return nil;
                }
                
            } else if ([type isEqualToString:@"push"]) {
                
                // Options Map is a String to String mapping stored in JSON.
                NSDictionary *optionsMap;
                if (![FRASerialization deserializeJSON:optionsJSON intoDictionary:&optionsMap error:error]) {
                    return nil;
                }
                
                // Secret stored as String (Base64?)
                NSString *secretValue = [optionsMap objectForKey:PUSH_MECHANISM_SECRET];
                
                // Auth Endpoint as string
                NSString *authEndpointValue = [optionsMap objectForKey:PUSH_MECHANISM_AUTH_END_POINT];
                
                // Version as string
                NSString *versionString = [optionsMap objectForKey:PUSH_MECHANISM_VERSION];
                NSInteger version = [[numberFormatter numberFromString:versionString] integerValue];
                
                
                FRAPushMechanism *newMechanism = [FRAPushMechanism pushMechanismWithDatabase:identityDatabase
                                                                               identityModel:identityModel
                                                                                authEndpoint:authEndpointValue
                                                                                      secret:secretValue
                                                                                     version:version
                                                                         mechanismIdentifier:mechanismUID];
                
                
                // Check to see if we already have this PushMechanism present, otherwise add it in.
                BOOL add = true;
                for (FRAMechanism *mechanism in newIdentity.mechanisms) {
                    if ([mechanism isKindOfClass:[FRAPushMechanism class]]) {
                        FRAPushMechanism *pushMechanism = (FRAPushMechanism *)mechanism;
                        if ([pushMechanism.mechanismUID isEqualToString:newMechanism.mechanismUID]) {
                            newMechanism = pushMechanism;
                            add = false;
                            break;
                        }
                    }
                }
                
                if (add) {
                    if (![newIdentity addMechanism:newMechanism error:error]) {
                        return nil;
                    }
                }

                // If we have a notification, parse and create the Notification for the Push Mechanism.
                // Note: Notifications can only currently exist for PushMechanisms.
                if (timeReceived != nil && [timeReceived length] > 0) {
                    
                    // Time stamp of the notification
                    NSDate *received = [NSDate dateWithTimeIntervalSince1970:[timeReceived doubleValue]];

                    
                    // Data map
                    NSDictionary *dataMap;
                    if (![FRASerialization deserializeJSON:data intoDictionary:&dataMap error:error]) {
                        return nil;
                    }
                    
                    // Data: Message ID
                    NSString *messageId = [dataMap valueForKey:NOTIFICATION_MESSAGE_ID];

                    // Data: Challenge
                    NSString *challenge = [[NSString alloc] initWithData:[FRASerialization deserializeBytes:[dataMap valueForKey:NOTIFICATION_PUSH_CHALLENGE]] encoding:NSUTF8StringEncoding];
                    
                    // Data: TTL
                    NSTimeInterval ttl = [[dataMap valueForKey:NOTIFICATION_TIME_TO_LIVE] doubleValue];
                    
                    FRANotification *notification = [FRANotification notificationWithDatabase:identityDatabase
                                                                                identityModel:identityModel
                                                                                    messageId:messageId
                                                                                    challenge:challenge
                                                                                 timeReceived:received
                                                                                   timeToLive:ttl
                                                                                      pending:pending
                                                                                     approved:approved];
                    
                    if (![newMechanism addNotification:notification error:error]) {
                        return nil;
                    }
                }
                
            } else {
                @throw [FRAError createIllegalStateException:@"Invalid mechanism"];
            }
        }
        
        // As we have read the objects from the database, marked them as stored.
        for (FRAIdentity* identity in identities) {
            identity.stored = YES;
            for (FRAMechanism *mechanism in identity.mechanisms) {
                mechanism.stored = YES;
                for (FRANotification *notification in mechanism.notifications) {
                    notification.stored = YES;
                }
            }
        }

        
        return identities;
    }
    @finally {
        [sqlDatabase closeConnectionToDatabase:database];
    }
}

@end