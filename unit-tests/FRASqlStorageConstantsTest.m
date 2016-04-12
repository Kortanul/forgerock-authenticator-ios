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

#import "FRASerialization.h"

@interface FRASqlStorageConstantsTest : XCTestCase

@end

/*!
 * A collection of tests to ensure that the serialise/deserialise functions
 * are sane.
 */
@implementation FRASqlStorageConstantsTest {
}

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark --
#pragma mark Byte Serialisation/Deserialisation

- (void)testBytesCanBeSerialised {
    // Given - badger steps into 'the converter'
    NSData* badgerBytes = [@"badger" dataUsingEncoding:NSUTF8StringEncoding];
    NSString* stringifiedBadger = [FRASerialization serializeBytes:badgerBytes];
    
    // When
    NSData* result = [FRASerialization deserializeBytes:stringifiedBadger];
    
    // Then
    XCTAssertEqualObjects(badgerBytes, result, @"Badger did not survive the conversion process");
}

- (void)testNilIsNotSerialised {
    // Given - nothing steps into 'the converter'
    NSData* nilBytes = nil;
    
    // When
    NSString* result = [FRASerialization serializeBytes:nilBytes];
    
    // Then
    XCTAssertNil(result, @"Did not return nil for nil input");
}

- (void)testNilIsNotDeserialised {
    // Given
    NSString* nilString = nil;
    
    // When
    NSData* result = [FRASerialization deserializeBytes:nilString];
    
    // Then
    XCTAssertNil(result, @"Did not return nil for nil input");
}

#pragma mark --
#pragma mark Dictionary Serialisation/Deserialisation

- (void)testDictionaryCanBeSerialised {
    // Given - A map steps into 'the converter'
    NSMutableDictionary* map = [[NSMutableDictionary alloc] init];
    [map setValue:@"badger" forKey:@"first"];
    [map setValue:@"ferret" forKey:@"second"];
    
    NSString* stringifiedMap;
    XCTAssertTrue([FRASerialization serializeMap:map intoString:&stringifiedMap error:nil], @"Serialisation failed");
    
    // When
    NSDictionary* result;
    XCTAssertTrue([FRASerialization deserializeJSON:stringifiedMap intoDictionary:&result error:nil]);
    
    // Then
    XCTAssertEqualObjects(map, result, @"Map did not survive the conversion process");
}

- (void)testNilDictionaryIsNotSerialised {
    // Given - A map steps into 'the converter'
    NSDictionary* map = nil;
    
    // When
    NSString* result;
    XCTAssertTrue([FRASerialization serializeMap:map intoString:&result error:nil]);
    
    // Then
    XCTAssertNil(result, @"Serialised nil map should be nil");
}

- (void)testNilIsNotDeserialisedIntoADictionary {
    // Given
    NSString* nilString = nil;
    
    // When
    NSDictionary* result;
    XCTAssertTrue([FRASerialization deserializeJSON:nilString intoDictionary:&result error:nil]);
    
    // Then
    XCTAssertNil(result, @"Deserialised nil String should be nil");
}

- (void)testEmptyDictionaryIsSerialised {
    // Given - A map steps into 'the converter'
    NSDictionary* map = [[NSDictionary alloc] init];
    NSString* stringifiedMap;
    XCTAssertTrue([FRASerialization serializeMap:map intoString:&stringifiedMap error:nil]);
    
    // When
    NSDictionary* result;
    XCTAssertTrue([FRASerialization deserializeJSON:stringifiedMap intoDictionary:&result error:nil]);
    
    // Then
    XCTAssertEqualObjects(map, result, @"Map did not survive the conversion process");
}

@end
