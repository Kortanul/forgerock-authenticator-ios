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

#import "FRAError.h"
#import "FMDatabase.h"

static NSString * const ERROR_DOMAIN = @"ForgeRockErrorDomain";

@interface FRAErrorTest : XCTestCase

@end

@implementation FRAErrorTest {
    id mockDatabase;
}

- (void)setUp {
    [super setUp];
    mockDatabase = OCMClassMock([FMDatabase class]);
}

- (void)tearDown {
    [mockDatabase stopMocking];
    [super tearDown];
}

- (void)testCreateErrorForLastFailureReturnsErrorWithDomainAndCodeAndUserInfo {
    
    NSString *errorMessage = @"error message";
    int const errorCode = 102;
    
    OCMStub([mockDatabase lastErrorMessage]).andReturn(errorMessage);
    OCMStub([mockDatabase lastErrorCode]).andReturn(errorCode);
    
    NSError *error = [FRAError createErrorForLastFailure:mockDatabase];
    
    XCTAssertEqualObjects(error.domain, ERROR_DOMAIN);
    XCTAssertEqual(error.code, errorCode);
    XCTAssertEqualObjects([error.userInfo valueForKey:NSLocalizedDescriptionKey], errorMessage);
}

- (void)testCreateErrorForLastFailureWhenNoDatabaseReturnsError {
    
    NSError *error = [FRAError createErrorForLastFailure:nil];
    
    XCTAssertEqualObjects(error.domain, ERROR_DOMAIN);
    XCTAssertEqual(error.code, -1);
    XCTAssertEqualObjects([error.userInfo valueForKey:NSLocalizedDescriptionKey], @"nil");
}

- (void)testCreateErrorForFilePathReturnsErrorWithDomainAndCodeAndUserInfo {
    
    NSString *reason = @"error reason";
    NSString *filePath = @"/file/path";
    NSError *error = [FRAError createErrorForFilePath:filePath reason:reason];
    
    XCTAssertEqualObjects(error.domain, ERROR_DOMAIN);
    XCTAssertEqual(error.code, 1000);
    XCTAssertEqualObjects([error.userInfo valueForKey:NSLocalizedDescriptionKey], reason);
    XCTAssertEqualObjects([error.userInfo valueForKey:NSFilePathErrorKey], filePath);
}

- (void)testCreateErrorWithReasonCodeAndUserInfoReturnsCorrectError {
    
    NSString *reason = @"error reason";
    enum FRAErrorCodes errorCode = FRAApplicationError;
    NSDictionary *userInfo = @{ @"other" : @"data" };
    
    NSError *error = [FRAError createError:reason code:errorCode userInfo:userInfo];
    
    XCTAssertEqual(error.code, errorCode);
    XCTAssertEqualObjects([error.userInfo valueForKey:NSLocalizedDescriptionKey], reason);
    XCTAssertEqualObjects([error.userInfo valueForKey:@"other"], @"data");
}

@end