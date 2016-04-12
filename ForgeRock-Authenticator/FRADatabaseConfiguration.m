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

#import "FRADatabaseConfiguration.h"
#import "FRAError.h"

/*!
 * Limited configuration at the moment for the SQLite database.
 *
 * Uses the iOS file system to locate the default storage location for the
 * SQLite database.
 */
@implementation FRADatabaseConfiguration
/*!
 * Specifically uses the <Library folder>/Database/database.sqlite location for
 * storage of non-user data which is expected to be backed up by iTunes.
 */
- (NSString *)getDatabasePathWithError:(NSError *__autoreleasing *)error {
    NSURL *library = [self systemLibraryPathWithError:error];
    if (library == nil) {
        return nil;
    }
    
    NSString *databaseFolder = [[library path] stringByAppendingPathComponent:@"Database"];
    
    // Create folder if needed.
    if (![FRADatabaseConfiguration parentFoldersFor:databaseFolder error:error]) {
        return nil;
    }
    
    // Create the Database/database.sql file path
    NSString *databaseFile = [databaseFolder stringByAppendingPathComponent:@"database"];
    return [databaseFile stringByAppendingPathExtension:@"sqlite"];
}

+ (BOOL)parentFoldersFor:(NSString *)folder error:(NSError *__autoreleasing *)error {
    NSFileManager* manager = [NSFileManager defaultManager];
    // Creating the folder if required
    if (![manager fileExistsAtPath:folder]) {
        return [manager createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:error];
        NSLog(@"Created folder: %@", folder);
    }
    return YES;
}

/*!
 * The operating system path that is recommended for storage of files that the user
 * should not have direct access to.
 * 
 * @see table 1_1 for more details:
 * https://developer.apple.com/library/mac/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html#//apple_ref/doc/uid/TP40010672-CH2-SW1
 *
 * @param error Reference to an error if any.
 * @return nil if the system folder could not be located, otherwise the path of the folder.
 */
- (NSURL *)systemLibraryPathWithError:(NSError *__autoreleasing *)error {
    NSFileManager* manager = [NSFileManager defaultManager];
    NSArray<NSURL*> *possibleURLs = [manager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
    // Guaranteed to be present by OS
    if ([possibleURLs count] == 0) {
        [FRAError createErrorForFilePath:@"NSLibraryDirectory" withReason:@"Could not locate system folder /Library" withError:error];
        return nil;
    }
    return [possibleURLs objectAtIndex:0];
}

@end