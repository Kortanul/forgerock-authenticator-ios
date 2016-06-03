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
#import "FRADatabaseConfiguration.h"
#import "FRAFMDatabaseFactory.h"
#import "FRAFMDatabaseConnectionHelper.h"

#import "FRAError.h"

/*!
 * Responsible for providing access to the Database connection for the caller.
 * This includes managing detail around initialising the schema for the database if
 * this is the first time the user has setup the App on their device.
 */
@implementation FRAFMDatabaseConnectionHelper {
    FRADatabaseConfiguration* _configuration;
    FRAFMDatabaseFactory* _factory;
    BOOL initialised;
}

- (instancetype)initWithConfiguration:(FRADatabaseConfiguration *)configuration databaseFactory:(FRAFMDatabaseFactory *)factory {
    self = [super init];
    if (self) {
        _configuration = configuration;
        _factory = factory;
        initialised = NO;
    }
    return self;
}

# pragma --
# pragma mark Public functions

-(FMDatabase *)getConnectionWithError:(NSError *__autoreleasing *)error {
    if (!initialised && ![self checkDatabaseInitialised:error]) {
        return nil;
    }
    
    return [self internalGetConnectionWithError:error];
}

-(void)closeConnectionToDatabase:(FMDatabase *)database {
    if (database == nil) {
        return;
    }
    // Placeholder for any additional cleanup or shutdown calls.
    
    // Close the connection.
    NSLog(@"Closing database connection: %@", database);
    BOOL result = [database close];
    NSLog(@"Database closed?: %@", result ? @"YES" : @"NO");
}


# pragma --
# pragma mark Internal database management functions

/*!
 * Internal call to intiailise the database.
 * @param error To contain any error whilst initialising.
 * @return An initialised instance of FMDatabase, or nil if there was an error.
 */
-(FMDatabase *)internalGetConnectionWithError:(NSError *__autoreleasing *)error {
    NSString* databasePath = [_configuration getDatabasePathWithError:error];
    if (databasePath == nil) {
        return nil;
    }
    
    // Open the Database
    NSLog(@"Database path: %@", databasePath);
    FMDatabase *database = [_factory createDatabaseFor:databasePath withError:error];
    if (database == nil) {
        return nil;
    }
    
    if (![database open]) {
        if (error) {
            *error = [FRAError createErrorForLastFailure:database];
        }
        return nil;
    }
    NSLog(@"Database opened: %@", database);
    
    return database;
}

/*!
 * Internal call to check if the database schema has been initialised.
 */
-(BOOL)checkDatabaseInitialised:(NSError *__autoreleasing *)error {
    FMDatabase* database;
    @try {
        database = [self internalGetConnectionWithError:error];
        if (database == nil) {
            return NO;
        }
        
        int query = [self queryDatabaseSchema:database withError:error];
        if (query == -1) {
            return NO;
        } else if (query == 0) {
            NSLog(@"Database is not initialised");
            if ([self initialiseSchema:database withError:error]) {
                initialised = YES;
            } else {
                return NO;
            }
        } else if (query == 1) {
            initialised = YES;
        }
        return YES;
    }
    @finally {
        [self closeConnectionToDatabase:database];
    }
}

/*!
 * A simple check to indicate if we need to setup the database schema or not.
 *
 * Note: Three return states required for this function, thus using an int.
 *
 * @return -1 if there was an error, 0 if the database is not yet setup and 1 if the database is setup.
 */
- (int)queryDatabaseSchema: (FMDatabase *) database withError:(NSError *__autoreleasing *)error {
    NSString* query = [FRAFMDatabaseConnectionHelper readSchema:@"init_check" withError:error];
    if (query == nil) {
        return -1;
    }
    
    FMResultSet* results = [database executeQuery:query];
    if (results == nil) {
        if (error) {
            *error = [FRAError createErrorForLastFailure:database];
        }
        return -1;
    }
    
    NSMutableArray *names = [[NSMutableArray alloc] init];
    while ([results next]) {
        [names addObject:[results stringForColumnIndex:1]];
    }
    
    BOOL result = [names containsObject:@"identity"] &&
    [names containsObject:@"mechanism"] &&
    [names containsObject:@"notification"];
    
    NSLog(@"Database setup: %@", result ? @"YES" : @"NO");
    return result ? 1 : 0;
}

/*!
 * Internal function to initialise database schema.
 * @throws FRADatabaseException If the statement failed to execute.
 */
- (BOOL)initialiseSchema:(FMDatabase *)database withError:(NSError *__autoreleasing *)error {
    NSString* schema = [FRAFMDatabaseConnectionHelper readSchema:@"schema" withError:error];
    if (schema == nil) {
        return NO;
    }
    
    BOOL result = [database executeStatements:schema];
    if (!result) {
        if (error) {
            *error = [FRAError createErrorForLastFailure:database];
        }
        return NO;
    }
    NSLog(@"Database setup complete");
    return YES;
}

#pragma mark --
#pragma mark file functions

+ (NSString *)readSchema:(NSString *)schemaName withError:(NSError *__autoreleasing *)error {
    NSString *extension = @"sql";
    
    // Locate in App bundle
    NSString *path = [[NSBundle mainBundle] pathForResource:schemaName ofType:extension];
    if (path == nil) {
        if (error) {
            *error = [FRAError createErrorForFilePath:schemaName reason:@"Could not find schema file"];
        }
        return nil;
    }
    
    // Read contents into String
    NSString *result = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (result == nil) {
        if (error) {
            *error = [FRAError createErrorForFilePath:path reason:@"Could not read contents"];
        }
        return nil;
    }
    
    return result;
}

@end