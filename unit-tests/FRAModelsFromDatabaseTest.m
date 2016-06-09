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

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "FMDatabase.h"
#import "FRAError.h"
#import "FRAFMDatabaseConnectionHelper.h"
#import "FRAHotpOathMechanism.h"
#import "FRAIdentity.h"
#import "FRAIdentityDatabase.h"
#import "FRAIdentityModel.h"
#import "FRAModelsFromDatabase.h"
#import "FRANotification.h"
#import "FRAPushMechanism.h"
#import "FRATotpOathMechanism.h"

static NSString * const ReadSchema = @"read_all schema";
static NSString * const Issuer = @"issuer";
static NSString * const AccountName = @"account name";
static NSString * const ImageURL = @"image url";
static NSString * const BackgroundColour = @"background color";
static NSString * const HMACOtpType = @"hotp";
static NSString * const TimeOtpType = @"totp";
static NSString * const PushType = @"push";
static NSString * const UnknownType = @"unknown";
static NSString * const Version = @"version";
static NSString * const MechanismUID = @"mechanism uid";
static NSString * const Options = @"{}";
static NSString * const TimeReceived = @"500";
static NSString * const TimeExpired = @"time expired";
static NSString * const Data = @"{\"message_id\":\"message id\", \"push_challenge\":\"challenge_data\",\"time_to_live\":\"60.0\"}";

@interface FRAModelsFromDatabaseTest : XCTestCase

@end

@implementation FRAModelsFromDatabaseTest {
    id mockSqlDatabase;
    id mockIdentityDatabase;
    id mockDatabase;
    id mockQueryResults;
    id mockIdentityModel;
}

- (void)setUp {
    [super setUp];
    mockSqlDatabase = OCMClassMock([FRAFMDatabaseConnectionHelper class]);
    mockIdentityDatabase = OCMClassMock([FRAIdentityDatabase class]);
    mockDatabase = OCMClassMock([FMDatabase class]);
    mockQueryResults = OCMClassMock([FMResultSet class]);
    mockIdentityModel = OCMClassMock([FRAIdentityModel class]);
}

- (void)tearDown {
    [mockSqlDatabase stopMocking];
    [mockIdentityDatabase stopMocking];
    [mockDatabase stopMocking];
    [mockIdentityModel stopMocking];
    [super tearDown];
}

- (void)testGetAllIdentitiesReturnsNilIfCannotGetReadAllSchema {
    
    OCMStub([mockSqlDatabase readSchema:@"read_all" withError:nil]).andReturn(nil);
    
    NSArray<FRAIdentity*>* identities = [FRAModelsFromDatabase getAllIdentitiesFrom:mockSqlDatabase including:mockIdentityDatabase identityModel:mockIdentityModel catchingErrorsWith:nil];
    
    XCTAssertNil(identities);
}

- (void)testGetAllIdentitiesReturnsNilIfCannotGetDatabaseConnection {
    
    OCMStub([mockSqlDatabase readSchema:@"read_all" withError:nil]).andReturn(ReadSchema);
    OCMStub([mockSqlDatabase getConnectionWithError:nil]).andReturn(nil);
    
    NSArray<FRAIdentity*>* identities = [FRAModelsFromDatabase getAllIdentitiesFrom:mockSqlDatabase including:mockIdentityDatabase identityModel:mockIdentityModel catchingErrorsWith:nil];
    
    XCTAssertNil(identities);
}

- (void)testGetAllIdentitiesReturnsNilIfCannotExecuteQueryOnDatabase {
    
    OCMStub([mockSqlDatabase readSchema:@"read_all" withError:[OCMArg anyObjectRef]]).andReturn(ReadSchema);
    OCMStub([mockSqlDatabase getConnectionWithError:[OCMArg anyObjectRef]]).andReturn(mockDatabase);
    OCMStub([mockDatabase executeQuery:ReadSchema]).andReturn(nil);
    NSError *error;

    NSArray<FRAIdentity*>* identities = [FRAModelsFromDatabase getAllIdentitiesFrom:mockSqlDatabase including:mockIdentityDatabase identityModel:mockIdentityModel catchingErrorsWith:&error];
  
    XCTAssertNil(identities);
    XCTAssertNotNil(error);
}

- (void)testGetAllIdentitiesReturnsIdentityWithHMACOneTimePasswordMechanism {
    
    OCMStub([mockSqlDatabase readSchema:@"read_all" withError:nil]).andReturn(ReadSchema);
    OCMStub([mockSqlDatabase getConnectionWithError:nil]).andReturn(mockDatabase);
    OCMStub([mockDatabase executeQuery:ReadSchema]).andReturn(mockQueryResults);
    [self setUpDummyIdentity:HMACOtpType];
    
    NSArray<FRAIdentity*>* identities = [FRAModelsFromDatabase getAllIdentitiesFrom:mockSqlDatabase including:mockIdentityDatabase identityModel:mockIdentityModel catchingErrorsWith:nil];
    
    XCTAssertEqual(identities.count, 1);
    FRAIdentity *identity = [identities objectAtIndex:0];
    XCTAssertEqual(identity.issuer, Issuer);
    XCTAssertEqual(identity.accountName, AccountName);
    XCTAssertEqual(identity.backgroundColor, BackgroundColour);
    XCTAssertEqual(identity.mechanisms.count, 1);
    FRAHotpOathMechanism *mechanism = (FRAHotpOathMechanism *)[identity.mechanisms objectAtIndex:0];
    XCTAssertEqual([mechanism class], [FRAHotpOathMechanism class]);
}

- (void)testGetAllIdentitiesReturnsIdentityWithTimeOneTimePasswordMechanism {
    
    OCMStub([mockSqlDatabase readSchema:@"read_all" withError:nil]).andReturn(ReadSchema);
    OCMStub([mockSqlDatabase getConnectionWithError:nil]).andReturn(mockDatabase);
    OCMStub([mockDatabase executeQuery:ReadSchema]).andReturn(mockQueryResults);
    [self setUpDummyIdentity:TimeOtpType];
    
    NSArray<FRAIdentity*>* identities = [FRAModelsFromDatabase getAllIdentitiesFrom:mockSqlDatabase including:mockIdentityDatabase identityModel:mockIdentityModel catchingErrorsWith:nil];
    
    XCTAssertEqual(identities.count, 1);
    FRAIdentity *identity = [identities objectAtIndex:0];
    XCTAssertEqual(identity.issuer, Issuer);
    XCTAssertEqual(identity.accountName, AccountName);
    XCTAssertEqual(identity.backgroundColor, BackgroundColour);
    XCTAssertEqual(identity.mechanisms.count, 1);
    FRATotpOathMechanism *mechanism = (FRATotpOathMechanism *)[identity.mechanisms objectAtIndex:0];
    XCTAssertEqual([mechanism class], [FRATotpOathMechanism class]);
}

- (void)testGetAllIdentitiesReturnsIdentityWithPushMechanism {
    
    OCMStub([mockSqlDatabase readSchema:@"read_all" withError:nil]).andReturn(ReadSchema);
    OCMStub([mockSqlDatabase getConnectionWithError:nil]).andReturn(mockDatabase);
    OCMStub([mockDatabase executeQuery:ReadSchema]).andReturn(mockQueryResults);
    [self setUpDummyIdentity:PushType];
    
    NSArray<FRAIdentity*>* identities = [FRAModelsFromDatabase getAllIdentitiesFrom:mockSqlDatabase including:mockIdentityDatabase identityModel:mockIdentityModel catchingErrorsWith:nil];
    
    XCTAssertEqual(identities.count, 1);
    FRAIdentity *identity = [identities objectAtIndex:0];
    XCTAssertEqual(identity.issuer, Issuer);
    XCTAssertEqual(identity.accountName, AccountName);
    XCTAssertEqual(identity.backgroundColor, BackgroundColour);
    XCTAssertEqual(identity.mechanisms.count, 1);
    FRAPushMechanism *mechanism = (FRAPushMechanism *)[identity.mechanisms objectAtIndex:0];
    FRANotification *notification = [mechanism.notifications objectAtIndex:0];
    XCTAssertEqualObjects(notification.messageId, @"message id");
    XCTAssertEqualObjects(notification.challenge, @"challenge_data");
    XCTAssertEqualObjects(notification.timeReceived, [NSDate dateWithTimeIntervalSince1970:500]);
    XCTAssertEqual(notification.timeToLive, (NSTimeInterval)60.0);
}

- (void)testGetAllIdentitiesThrowsExceptionForUnknownMechanismType {
    
    OCMStub([mockSqlDatabase readSchema:@"read_all" withError:nil]).andReturn(ReadSchema);
    OCMStub([mockSqlDatabase getConnectionWithError:nil]).andReturn(mockDatabase);
    OCMStub([mockDatabase executeQuery:ReadSchema]).andReturn(mockQueryResults);
    [self setUpDummyIdentity:UnknownType];
    
    XCTAssertThrows([FRAModelsFromDatabase getAllIdentitiesFrom:mockSqlDatabase including:mockIdentityDatabase identityModel:mockIdentityModel catchingErrorsWith:nil]);
}

- (void)setUpDummyIdentity:(NSString *)type {
    OCMExpect([mockQueryResults next]).andReturn(YES);
    OCMStub([mockQueryResults stringForColumn:@"issuer"]).andReturn(Issuer);
    OCMStub([mockQueryResults stringForColumn:@"accountName"]).andReturn(AccountName);
    OCMStub([mockQueryResults stringForColumn:@"imageURL"]).andReturn(ImageURL);
    OCMStub([mockQueryResults stringForColumn:@"bgColor"]).andReturn(BackgroundColour);
    OCMStub([mockQueryResults stringForColumn:@"type"]).andReturn(type);
    OCMStub([mockQueryResults stringForColumn:@"version"]).andReturn(Version);
    OCMStub([mockQueryResults stringForColumn:@"mechanismUID"]).andReturn(MechanismUID);
    OCMStub([mockQueryResults stringForColumn:@"options"]).andReturn(Options);
    OCMStub([mockQueryResults stringForColumn:@"timeReceived"]).andReturn(TimeReceived);
    OCMStub([mockQueryResults stringForColumn:@"timeExpired"]).andReturn(TimeExpired);
    OCMStub([mockQueryResults stringForColumn:@"data"]).andReturn(Data);
    OCMStub([mockQueryResults intForColumn:@"pending"]).andReturn(-1);
    OCMStub([mockQueryResults intForColumn:@"approved"]).andReturn(0);
    OCMExpect([mockQueryResults next]).andReturn(NO);
}

@end