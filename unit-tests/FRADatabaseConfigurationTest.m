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
#import "FRADatabaseConfiguration.h"
#import "FRAError.h"

static NSString * const FOLDER_NAME = @"any_folder";

@interface FRADatabaseConfigurationTest : XCTestCase

@end

@implementation FRADatabaseConfigurationTest {
    id mockFileManager;
}

- (void)setUp {
    [super setUp];
    
    mockFileManager = OCMClassMock([NSFileManager class]);
    OCMStub([mockFileManager defaultManager]).andReturn(mockFileManager);
}

- (void)tearDown {
    [mockFileManager stopMocking];
    [super tearDown];
}

- (void)testCreateParentFolderReturnsYesIfFolderAlreadyExists {
    
    OCMStub([mockFileManager fileExistsAtPath:FOLDER_NAME]).andReturn(YES);
    
    BOOL result = [FRADatabaseConfiguration parentFoldersFor:FOLDER_NAME error:nil];
    
    XCTAssertTrue(result);
}

- (void)testCreateParentFolderReturnsYesIfFolderIsCreated {
    
    OCMStub([mockFileManager fileExistsAtPath:FOLDER_NAME]).andReturn(NO);
    OCMStub([mockFileManager createDirectoryAtPath:FOLDER_NAME withIntermediateDirectories:YES attributes:nil error:nil]).andReturn(YES);
    
    BOOL result = [FRADatabaseConfiguration parentFoldersFor:FOLDER_NAME error:nil];
    
    XCTAssertTrue(result);
}

- (void)testCreateParentFolderReturnsNoIfFails {

    OCMStub([mockFileManager fileExistsAtPath:FOLDER_NAME]).andReturn(NO);
    OCMStub([mockFileManager createDirectoryAtPath:FOLDER_NAME withIntermediateDirectories:YES attributes:nil error:[OCMArg anyObjectRef]]).andReturn(NO);
    
    BOOL result = [FRADatabaseConfiguration parentFoldersFor:FOLDER_NAME error:nil];
    
    XCTAssertFalse(result);
}

- (void)testGetDatabasePathReturnsNilIfNoLibraryDirectories {
    
    NSArray<NSURL*> *urls = [NSMutableArray new];
    OCMStub([mockFileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask]).andReturn(urls);
    NSError *error;
    
    FRADatabaseConfiguration *databaseConfiguration = [FRADatabaseConfiguration alloc];
    NSString *path = [databaseConfiguration getDatabasePathWithError:&error];
    
    XCTAssertNil(path);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects([error.userInfo valueForKey:NSLocalizedDescriptionKey], @"Could not locate system folder /Library");
}

- (void)testGetDatabasePathReturnsNilIfCannotCreateFolder {
    
    OCMStub([FRADatabaseConfiguration parentFoldersFor:@"" error:nil]).andReturn(NO);
    
    FRADatabaseConfiguration *databaseConfiguration = [FRADatabaseConfiguration alloc];
    NSString *path = [databaseConfiguration getDatabasePathWithError:nil];
    
    XCTAssertNil(path);
}

- (void)testGetDatabasePathReturnsPathToSQLliteFile {
    
    NSString *databaseDirectoryName = @"Database";
    NSString *libraryDirectory = @"/library_directory";
    NSString *databaseDirectoryPath = [NSString stringWithFormat:@"%@/%@", libraryDirectory, databaseDirectoryName];
    NSString *expectedDatabaseFilePath = [NSString stringWithFormat:@"%@/%@/%@", libraryDirectory, databaseDirectoryName, @"database.sqlite"];
    NSArray<NSURL*> *urls = [[NSMutableArray alloc] initWithObjects:[NSURL URLWithString:libraryDirectory], nil];
    
    OCMStub([mockFileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask]).andReturn(urls);
    OCMStub([FRADatabaseConfiguration parentFoldersFor:databaseDirectoryPath error:nil]).andReturn(YES);
    
    FRADatabaseConfiguration *databaseConfiguration = [FRADatabaseConfiguration alloc];
    NSString *path = [databaseConfiguration getDatabasePathWithError:nil];
    
    XCTAssertEqualObjects(path, expectedDatabaseFilePath);
}

@end