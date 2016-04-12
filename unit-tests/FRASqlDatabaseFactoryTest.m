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
#import "FRAFMDatabaseFactory.h"

static NSString * const Path = @"/database/path";

@interface FRAFMDatabaseFactoryTest : XCTestCase

@end

@implementation FRAFMDatabaseFactoryTest {
    id mockDatabase;
    id mockError;
}

- (void)setUp {
    [super setUp];
    mockDatabase = OCMClassMock([FMDatabase class]);
    mockError = OCMClassMock([FRAError class]);
}

- (void)tearDown {
    [mockDatabase stopMocking];
    [mockError stopMocking];
    [super tearDown];
}

- (void)testCreateDatabaseReturnsNilIfNoDatabaseAtPath {
    OCMStub([mockDatabase databaseWithPath:Path]).andReturn(nil);
    FRAFMDatabaseFactory *factory = [FRAFMDatabaseFactory new];
    
    FMDatabase *database = [factory createDatabaseFor:Path withError:nil];
    
    XCTAssertNil(database);
    OCMVerify([mockError createErrorForFilePath:Path withReason:@"Could not open database" withError:nil]);
}

- (void)testCreateDatabaseReturnsDatabaseAtPath {
    OCMStub([mockDatabase databaseWithPath:Path]).andReturn(mockDatabase);
    FRAFMDatabaseFactory *factory = [FRAFMDatabaseFactory new];
    
    FMDatabase *database = [factory createDatabaseFor:Path withError:nil];
    
    XCTAssertEqual(database, mockDatabase);
}

@end