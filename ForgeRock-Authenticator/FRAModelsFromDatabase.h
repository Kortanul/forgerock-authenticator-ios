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

@class FRAIdentity;
@class FRAFMDatabaseConnectionHelper;

/*!
 * Defines all configuration needed to locate the SQLite Database.
 */
@interface FRAModelsFromDatabase : NSObject

/*!
 * Read all Identities, Mechanisms and Notifications from the database
 * and generate the object tree.
 *
 * @param sqlDatabase The SQL Database to read the identities from.
 * @param identityDatabase Assigned to the model objects created.
 * @param identityModel The identity model which contains the list of identities.
 * @param error If an error occurs, upon returns contains an NSError object that describes the problem. If you are not interested in possible errors, you may pass in NULL.
 * @return A non null, possibly empty list of FRAIdentity read from the database.
 */
+ (NSArray<FRAIdentity*> *)getAllIdentitiesFrom:(FRAFMDatabaseConnectionHelper *)sqlDatabase including:(FRAIdentityDatabase *)identityDatabase identityModel:(FRAIdentityModel *)identityModel catchingErrorsWith:(NSError *__autoreleasing *)error;

@end