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
#import "FRAIdentity.h"
#import "FRAMechanism.h"

@interface FRAIdentityTests : XCTestCase

@end

@implementation FRAIdentityTests {
    FRAIdentity* identity;
}

- (void)setUp {
    [super setUp];
    identity = [[FRAIdentity alloc] initWithAccountName:@"badger" issuedBy:@"forrest"
                                              withImage:[[NSURL alloc] initWithString:@"http://animalia-life.com/data_images/badger/badger1.jpg"]];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testIdentityWithLabelIssuerImage {
    // Given
    NSString* issuer = @"ForgeRock";
    NSString* accountName = @"joe.bloggs";
    NSURL* image = [NSURL URLWithString:@"https://forgerock.org/ico/favicon-32x32.png"];
    
    // When
    FRAIdentity* test = [FRAIdentity identityWithAccountName:accountName issuedBy:issuer withImage:image];
    
    // Then
    XCTAssertEqualObjects([test issuer], issuer);
    XCTAssertEqualObjects([test accountName], accountName);
    XCTAssertEqualObjects([[test image] absoluteString], [image description]);
}

- (void) testCanAddMechanism {
    // Given
    FRAMechanism* mechansim = [[FRAMechanism alloc] init];
    
    // When
    [identity addMechanism:mechansim];
    
    // Then
    XCTAssertEqual([[identity mechanisms]count], 1);
}

- (void) testCanRemoveMechanism {
    // Given
    FRAMechanism* mechansim = [[FRAMechanism alloc] init];
    [identity addMechanism:mechansim];
    
    // When
    [identity removeMechanism:mechansim];
    
    // Then
    XCTAssertEqual([[identity mechanisms]count], 0);
}

@end
