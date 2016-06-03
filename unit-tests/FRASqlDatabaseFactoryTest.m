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

static NSString * const PATH = @"/database/path";

@interface FRAFMDatabaseFactoryTest : XCTestCase

@end

@implementation FRAFMDatabaseFactoryTest {
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

- (void)testCreateDatabaseReturnsNilIfNoDatabaseAtPath {
    OCMStub([mockDatabase databaseWithPath:PATH]).andReturn(nil);
    FRAFMDatabaseFactory *factory = [[FRAFMDatabaseFactory alloc] init];
    NSError *error;
    FMDatabase *database = [factory createDatabaseFor:PATH withError:&error];
    
    XCTAssertNil(database);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects([error.userInfo valueForKey:NSFilePathErrorKey], PATH);
}

- (void)testCreateDatabaseReturnsDatabaseAtPath {
    OCMStub([mockDatabase databaseWithPath:PATH]).andReturn(mockDatabase);
    FRAFMDatabaseFactory *factory = [[FRAFMDatabaseFactory alloc] init];
    
    FMDatabase *database = [factory createDatabaseFor:PATH withError:nil];
    
    XCTAssertEqual(database, mockDatabase);
}

@end