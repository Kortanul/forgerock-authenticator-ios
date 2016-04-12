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

@class FMDatabase;
@class FRADatabaseConfiguration;
@class FRAFMDatabaseFactory;

/*!
 * Responsible for generating a connection to the SQL Database.
 */
@interface FRAFMDatabaseConnectionHelper : NSObject

/*!
 * Initialise the database with any required configuration.
 */
- (instancetype)initWithConfiguration:(FRADatabaseConfiguration *)configuration databaseFactory:(FRAFMDatabaseFactory *)factory;

/*!
 * Establish a connection to the database and return this to the caller.
 *
 * @param error For any error in the process of initialising the database.
 * @return An initialised instance of the database if successfully initialised. Otherwise nil.
 */
- (FMDatabase *)getConnectionWithError:(NSError *__autoreleasing *)error;

/*!
 * Close a connection to the database which was previously opened by this
 * class.
 *
 * @param database possibly nil database instance which was opened by this class.
 */
- (void)closeConnectionToDatabase:(FMDatabase *)database;

/*!
 * Read an SQL schema file from the App. The requested schema must be present
 * in the App, otherwise this is an error.
 *
 * @param schema The schema file to read in, excluding the .sql extension.
 * @return non-nil schema file contents as a string.
 * @throws FRADatabaseException If the file did not exist.
 */
+ (NSString *)readSchema:(NSString *)schema withError:(NSError *__autoreleasing *)error;

@end