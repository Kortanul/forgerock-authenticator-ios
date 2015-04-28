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
 * Copyright 2015 ForgeRock AS.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "base32.h"

@interface base32test : XCTestCase
+ (NSString*) keyToString:(uint8_t*)key withLength:(int)length;
@end

@implementation base32test

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testShouldDecodeStringIncludingPadding {
    // Given
    uint8_t key[4096];
    const char *tmp = [@"IJQWIZ3FOIQQ====" cStringUsingEncoding:NSASCIIStringEncoding];
    
    // When
    int res = base32_decode(tmp, key, sizeof(key));
    
    // Then
    XCTAssertEqualObjects([base32test keyToString:key withLength:res], @"Badger!", @"Pass");
}

- (void)testShouldDecodeStringWithoutPadding {
    // Given
    uint8_t key[4096];
    const char *tmp = [@"IJQWIZ3FOIQUEYLE" cStringUsingEncoding:NSASCIIStringEncoding];

    // When
    int res = base32_decode(tmp, key, sizeof(key));
    
    // Then
    XCTAssertEqualObjects([base32test keyToString:key withLength:res], @"Badger!Bad", @"Pass");
}

// base32 assumpts that a char is 1 byte
- (void) testSizesOfDataTypes {
    long cs = sizeof(char);
    XCTAssert(cs == 1, @"sizeof char: %lu", cs);
}

// Decode the Char* (equivalent to uint8?) to an NSString
+ (NSString*) keyToString:(uint8_t*)key withLength:(int)length {
    if (length == -1) {
        return nil;
    }
    NSData* key_data = [NSData dataWithBytes:key length:length];
    NSString *key_string = [[NSString alloc] initWithData:key_data encoding:NSASCIIStringEncoding];
    return key_string;
}
@end
