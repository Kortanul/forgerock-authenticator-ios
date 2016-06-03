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

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "FRADatabaseConfiguration.h"
#import "FRAFMDatabaseConnectionHelper.h"
#import "FRAFMDatabaseFactory.h"
#import "FMDatabase.h"
#import "FRAError.h"

static NSString * const DatabaseFilePath = @"/database/path";
static NSString * const SchemaFilePath = @"/schema/file/path";

@interface FRAFMDatabaseConnectionHelperTest : XCTestCase

@end

/*!
 * A series of tests which will demonstrate the public interface of the
 * database code, and demonstrate that it throws exceptions for conditions
 * we consider to be exceptional.
 */
@implementation FRAFMDatabaseConnectionHelperTest {
    id mockConfig;
    id mockFactory;
    id mockDatabase;
    id mockSchemaResults;
    NSMutableArray *schemaResultsList;
}

- (void)setUp {
    [super setUp];
    
    mockConfig = OCMClassMock([FRADatabaseConfiguration class]);
    mockFactory = OCMClassMock([FRAFMDatabaseFactory class]);
    mockSchemaResults = OCMClassMock([FMResultSet class]);
    mockDatabase = OCMClassMock([FMDatabase class]);
    
    OCMStub([mockSchemaResults next])
    .andCall(self, @selector(mockSchemaResultsListHasNext));
    OCMStub([mockSchemaResults stringForColumnIndex:1])
    .andCall(self, @selector(mockSchemaResultsListGetStringForColumnIndex));
}

- (void)initialiseSchemaResultsListWith:(NSString *)first, ... {
    
    schemaResultsList = [[NSMutableArray alloc] init];
    va_list args;
    va_start(args, first);
    for (NSString *arg = first; arg != nil; arg = va_arg(args, NSString*)) {
        [schemaResultsList addObject:arg];
    }
    va_end(args);
}

- (BOOL)mockSchemaResultsListHasNext {
    return [schemaResultsList count] != 0;
}

- (NSString*)mockSchemaResultsListGetStringForColumnIndex {
    NSString* value = [schemaResultsList objectAtIndex:0];
    [schemaResultsList removeObjectAtIndex:0];
    return value;
}

- (void)tearDown {
    [mockConfig stopMocking];
    [mockFactory stopMocking];
    [mockDatabase stopMocking];
    [mockSchemaResults stopMocking];
    [super tearDown];
}

- (void)testGetConnectionReturnsNilIfNotInitialised {
    
    FRAFMDatabaseConnectionHelper *database = [FRAFMDatabaseConnectionHelper alloc];
    
    FMDatabase *connection = [database getConnectionWithError:nil];
    
    XCTAssertNil(connection);
}

- (void)testGetConnectionReturnsNilIfCantFindDatabasePath {
    
    OCMStub([mockConfig getDatabasePathWithError:nil]).andReturn(nil);
    FRAFMDatabaseConnectionHelper *database = [[FRAFMDatabaseConnectionHelper alloc] initWithConfiguration:mockConfig databaseFactory:mockFactory];
    
    FMDatabase *connection = [database getConnectionWithError:nil];
    
    XCTAssertNil(connection);
}

- (void)testGetConnectionReturnsNilIfCantCreateConnection {
    
    OCMStub([mockConfig getDatabasePathWithError:nil]).andReturn(DatabaseFilePath);
    OCMStub([mockFactory createDatabaseFor:DatabaseFilePath withError:nil]).andReturn(nil);
    FRAFMDatabaseConnectionHelper *database = [[FRAFMDatabaseConnectionHelper alloc] initWithConfiguration:mockConfig databaseFactory:mockFactory];
    
    FMDatabase *connection = [database getConnectionWithError:nil];
    
    XCTAssertNil(connection);
}

- (void)testGetConnectionReturnsNilIfCantOpenConnection {
    
    FMDatabase *cannotOpenDatabase = OCMClassMock([FMDatabase class]);
    OCMStub([mockConfig getDatabasePathWithError:[OCMArg anyObjectRef]]).andReturn(DatabaseFilePath);
    OCMStub([mockFactory createDatabaseFor:DatabaseFilePath withError:[OCMArg anyObjectRef]]).andReturn(cannotOpenDatabase);
    OCMStub([cannotOpenDatabase open]).andReturn(NO);
    FRAFMDatabaseConnectionHelper *database = [[FRAFMDatabaseConnectionHelper alloc] initWithConfiguration:mockConfig databaseFactory:mockFactory];
    NSError *error;
    FMDatabase *connection = [database getConnectionWithError:&error];
    
    XCTAssertNil(connection);
    XCTAssertNotNil(error);
}

- (void)testGetConnectionReturnsNilIfCantFindInitCheckDatabaseSchema {

    id bundle = OCMClassMock([NSBundle class]);
    OCMStub([bundle mainBundle]).andReturn(bundle);
    OCMStub([bundle pathForResource:@"init_check" ofType:@"sql"]).andReturn(nil);
    OCMStub([mockConfig getDatabasePathWithError:nil]).andReturn(DatabaseFilePath);
    OCMStub([mockFactory createDatabaseFor:DatabaseFilePath withError:nil]).andReturn(mockDatabase);
    FRAFMDatabaseConnectionHelper *database = [[FRAFMDatabaseConnectionHelper alloc] initWithConfiguration:mockConfig databaseFactory:mockFactory];
    
    FMDatabase *connection = [database getConnectionWithError:nil];
    
    XCTAssertNil(connection);
}

- (void)testGetConnectionReturnsNilIfCantReadInitCheckSchemaFileContents {
    
    id bundle = OCMClassMock([NSBundle class]);
    OCMStub([bundle mainBundle]).andReturn(bundle);
    OCMStub([bundle pathForResource:@"init_check" ofType:@"sql"]).andReturn(SchemaFilePath);
    id mockString = OCMClassMock([NSString class]);
    OCMStub([mockString initWithContentsOfFile:SchemaFilePath encoding:NSUTF8StringEncoding error:nil]).andReturn(nil);
    OCMStub([mockConfig getDatabasePathWithError:nil]).andReturn(DatabaseFilePath);
    OCMStub([mockFactory createDatabaseFor:DatabaseFilePath withError:nil]).andReturn(mockDatabase);
    FRAFMDatabaseConnectionHelper *database = [[FRAFMDatabaseConnectionHelper alloc] initWithConfiguration:mockConfig databaseFactory:mockFactory];
    
    FMDatabase *connection = [database getConnectionWithError:nil];
    
    XCTAssertNil(connection);
}

- (void)testGetConnectionReturnsNilIfCantExecuteQueryOnDatabase {
    
    FMDatabase *cannotExecuteQueryDatabase = OCMClassMock([FMDatabase class]);
    OCMStub([cannotExecuteQueryDatabase open]).andReturn(YES);
    OCMStub([cannotExecuteQueryDatabase executeQuery:[OCMArg any]]).andReturn(nil);
    OCMStub([mockConfig getDatabasePathWithError:nil]).andReturn(DatabaseFilePath);
    OCMStub([mockFactory createDatabaseFor:DatabaseFilePath withError:nil]).andReturn(cannotExecuteQueryDatabase);
    FRAFMDatabaseConnectionHelper *database = [[FRAFMDatabaseConnectionHelper alloc] initWithConfiguration:mockConfig databaseFactory:mockFactory];
    
    FMDatabase *connection = [database getConnectionWithError:nil];
    
    XCTAssertNil(connection);
}

- (void)testGetConnectionReturnsNilIfCantFindDatabaseSchema {
    
    [self initialiseSchemaResultsListWith:@"unknown", nil];
    id bundle = OCMPartialMock([NSBundle mainBundle]);
    OCMStub([bundle pathForResource:@"schema" ofType:@"sql"]).andReturn(nil);
    FMDatabase *cannotInitialiseDatabase = OCMClassMock([FMDatabase class]);
    OCMStub([cannotInitialiseDatabase open]).andReturn(YES);
    OCMStub([cannotInitialiseDatabase executeQuery:[OCMArg any]]).andReturn(mockSchemaResults);
    OCMStub([mockConfig getDatabasePathWithError:nil]).andReturn(DatabaseFilePath);
    OCMStub([mockFactory createDatabaseFor:DatabaseFilePath withError:nil]).andReturn(cannotInitialiseDatabase);
    FRAFMDatabaseConnectionHelper *database = [[FRAFMDatabaseConnectionHelper alloc] initWithConfiguration:mockConfig databaseFactory:mockFactory];
    
    FMDatabase *connection = [database getConnectionWithError:nil];
    
    XCTAssertNil(connection);
}

- (void)testGetConnectionReturnsNilIfCantReadSchemaFileContents {
    
    [self initialiseSchemaResultsListWith:@"unknown", nil];
    id bundle = OCMPartialMock([NSBundle mainBundle]);
    OCMStub([bundle pathForResource:@"schema" ofType:@"sql"]).andReturn(SchemaFilePath);
    id mockString = OCMClassMock([NSString class]);
    OCMStub([mockString initWithContentsOfFile:SchemaFilePath encoding:NSUTF8StringEncoding error:nil]).andReturn(nil);
    OCMStub([mockConfig getDatabasePathWithError:nil]).andReturn(DatabaseFilePath);
    OCMStub([mockFactory createDatabaseFor:DatabaseFilePath withError:nil]).andReturn(mockDatabase);
    FRAFMDatabaseConnectionHelper *database = [[FRAFMDatabaseConnectionHelper alloc] initWithConfiguration:mockConfig databaseFactory:mockFactory];
    
    FMDatabase *connection = [database getConnectionWithError:nil];
    
    XCTAssertNil(connection);
}

- (void)testGetConnectionReturnsNilIfCantInitialiseDatabase {
    
    [self initialiseSchemaResultsListWith:@"unknown", nil];
    id sqlDatabase = OCMClassMock([FMDatabase class]);
    OCMStub([sqlDatabase executeStatements:[OCMArg any]]).andReturn(NO);
    OCMStub([mockConfig getDatabasePathWithError:nil]).andReturn(DatabaseFilePath);
    OCMStub([mockFactory createDatabaseFor:DatabaseFilePath withError:nil]).andReturn(mockDatabase);
    FRAFMDatabaseConnectionHelper *database = [[FRAFMDatabaseConnectionHelper alloc] initWithConfiguration:mockConfig databaseFactory:mockFactory];
    
    FMDatabase *connection = [database getConnectionWithError:nil];
    
    XCTAssertNil(connection);
}

- (void)testGetConnectionReturnsDatabaseConnection {

    [self initialiseSchemaResultsListWith:@"identity", @"mechanism", @"notification", nil];
    OCMStub([(FMDatabase *)mockDatabase open]).andReturn(YES);
    OCMStub([mockDatabase executeQuery:[OCMArg any]]).andReturn(mockSchemaResults);
    OCMStub([mockConfig getDatabasePathWithError:nil]).andReturn(DatabaseFilePath);
    OCMStub([mockFactory createDatabaseFor:DatabaseFilePath withError:nil]).andReturn(mockDatabase);
    FRAFMDatabaseConnectionHelper *database = [[FRAFMDatabaseConnectionHelper alloc] initWithConfiguration:mockConfig databaseFactory:mockFactory];
    
    FMDatabase *connection = [database getConnectionWithError:nil];
    
    XCTAssertNotNil(connection);
}

- (void)testThatDatabaseClosesWhenClosed {

    OCMStub([mockFactory createDatabaseFor:[OCMArg any] withError:nil]).andReturn(mockDatabase);
    FRAFMDatabaseConnectionHelper *sqlDatabase = [[FRAFMDatabaseConnectionHelper alloc] initWithConfiguration:mockConfig databaseFactory:mockFactory];
    
    [sqlDatabase closeConnectionToDatabase:mockDatabase];

    OCMVerify([(FMDatabase *)mockDatabase close]);
}

@end
