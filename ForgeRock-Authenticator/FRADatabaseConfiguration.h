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

/*!
 * Defines all configuration needed to locate the SQLite Database.
 */
@interface FRADatabaseConfiguration : NSObject

/*!
 * Gets the path to the database.
 * @param error If an error occurs, upon returns contains an NSError object that describes the problem. If you are not interested in possible errors, you may pass in NULL.
 * @return Non nil complete path to the database file to use for the App.
 */
-(NSString *)getDatabasePathWithError:(NSError *__autoreleasing *)error;

/*!
 * Given a path, create any folders necessary in the path.
 * @param folder The folder and parent folders to create.
 * @param error If an error occurs, upon returns contains an NSError object that describes the problem. If you are not interested in possible errors, you may pass in NULL.
 * @throws FRADatabaseException if the folder could not be created.
 */
+(BOOL)parentFoldersFor:(NSString *)folder error:(NSError *__autoreleasing *)error;

@end