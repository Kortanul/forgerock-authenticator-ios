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

#import "FRADateUtils.h"

static NSString * const CURRENT_TIME = @"1982-10-25 15:23:12";
static NSString * const TIME_TEN_MINUTES_AGO = @"1982-10-25 15:13:12";
static NSString * const TIME_END_OF_YESTERDAY = @"1982-10-24 23:59:12";
static NSString * const TIME_2_DAYS_AGO = @"1982-10-23 23:59:12";
static NSString * const TIME_3_DAYS_AGO = @"1982-10-22 23:59:12";
static NSString * const TIME_4_DAYS_AGO = @"1982-10-21 23:59:12";
static NSString * const TIME_5_DAYS_AGO = @"1982-10-20 23:59:12";
static NSString * const TIME_6_DAYS_AGO = @"1982-10-19 23:59:12";
static NSString * const TIME_7_DAYS_AGO = @"1982-10-18 23:59:12";
static NSString * const TIME_8_DAYS_AGO = @"1982-10-17 23:59:12";

static NSString * const EN_GB_LOCALE = @"en_GB";
static NSString * const EN_US_LOCALE = @"en_US";
static NSString * const IT_IT_LOCALE = @"it_IT";


@interface FRADateUtilsTests : XCTestCase

@end

@implementation FRADateUtilsTests {
    FRADateUtils *dateTools;
    NSDateFormatter *formatter;
    NSLocale *enGBLocale;
    
    id mockLocale;
    id mockDate;
}

- (void)setUp {
    [super setUp];
    
    dateTools = [[FRADateUtils alloc] init];
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    enGBLocale = [NSLocale localeWithLocaleIdentifier:@"en_GB"];

    mockLocale = OCMClassMock([NSLocale class]);
    mockDate = OCMClassMock([NSDate class]);
}

- (void)tearDown {
    [mockLocale stopMocking];
    [mockDate stopMocking];
    [super tearDown];
}

- (void)testAgeOfNotificationReceivedTodayIsReportedAsTimeUsing24HourClock {
    XCTAssertEqualObjects(@"15:13",
                          [self ageOfEventTime:TIME_TEN_MINUTES_AGO inLocale:EN_GB_LOCALE],
                          @"Notifications received today should be displayed in hours and minutes");
}

- (void)testAgeOfNotificationReceivedTodayIsReportedAsTimeUsing24HourClockInCurrentLocale {
    // This test could be improved by identifying a locale that uses a different format to HH:mm for short time
    XCTAssertEqualObjects(@"15:13",
                          [self ageOfEventTime:TIME_TEN_MINUTES_AGO inLocale:IT_IT_LOCALE],
                          @"Notifications received today should be displayed in hours and minutes formatted for current locale");
}

- (void)testAgeOfNotificationReceivedYesterdayIsReportedAsYesterday {
    XCTAssertEqualObjects(@"Yesterday",
                          [self ageOfEventTime:TIME_END_OF_YESTERDAY inLocale:EN_GB_LOCALE],
                          @"Notifications received yesterday should be displayed as \"Yesterday\"");
}

- (void)testAgeOfNotificationReceivedYesterdayIsReportedAsYesterdayInCurrentLanguage {
    // This test can be improved when we have a translation for Localizable.strings
    XCTAssertEqualObjects(@"Yesterday",
                          [self ageOfEventTime:TIME_END_OF_YESTERDAY inLocale:IT_IT_LOCALE],
                          @"Notifications received yesterday should be displayed as \"Yesterday\" in current language");
}

- (void)testAgeOfNotificationReceivedBetweenTwoAndSevenDaysAgoIsReportedAsDayOfTheWeek {
    XCTAssertEqualObjects(@"Saturday",
                          [self ageOfEventTime:TIME_2_DAYS_AGO inLocale:EN_GB_LOCALE],
                          @"Notifications received two days ago should be displayed as day of week");
    XCTAssertEqualObjects(@"Friday",
                          [self ageOfEventTime:TIME_3_DAYS_AGO inLocale:EN_GB_LOCALE],
                          @"Notifications received three days ago should be displayed as day of week");
    XCTAssertEqualObjects(@"Thursday",
                          [self ageOfEventTime:TIME_4_DAYS_AGO inLocale:EN_GB_LOCALE],
                          @"Notifications received four days ago should be displayed as day of week");
    XCTAssertEqualObjects(@"Wednesday",
                          [self ageOfEventTime:TIME_5_DAYS_AGO inLocale:EN_GB_LOCALE],
                          @"Notifications received five days ago should be displayed as day of week");
    XCTAssertEqualObjects(@"Tuesday",
                          [self ageOfEventTime:TIME_6_DAYS_AGO inLocale:EN_GB_LOCALE],
                          @"Notifications received six days ago should be displayed as day of week");
    XCTAssertEqualObjects(@"Monday",
                          [self ageOfEventTime:TIME_7_DAYS_AGO inLocale:EN_GB_LOCALE],
                          @"Notifications received seven days ago should be displayed as day of week");
}

- (void)testAgeOfNotificationReceivedBetweenTwoAndSevenDaysAgoIsReportedAsDayOfTheWeekInCurrentLanguage {
    XCTAssertEqualObjects(@"sabato",
                          [self ageOfEventTime:TIME_2_DAYS_AGO inLocale:IT_IT_LOCALE],
                          @"Notifications received two days ago should be displayed as day of week");
    XCTAssertEqualObjects(@"venerdì",
                          [self ageOfEventTime:TIME_3_DAYS_AGO inLocale:IT_IT_LOCALE],
                          @"Notifications received three days ago should be displayed as day of week");
    XCTAssertEqualObjects(@"giovedì",
                          [self ageOfEventTime:TIME_4_DAYS_AGO inLocale:IT_IT_LOCALE],
                          @"Notifications received four days ago should be displayed as day of week");
    XCTAssertEqualObjects(@"mercoledì",
                          [self ageOfEventTime:TIME_5_DAYS_AGO inLocale:IT_IT_LOCALE],
                          @"Notifications received five days ago should be displayed as day of week");
    XCTAssertEqualObjects(@"martedì",
                          [self ageOfEventTime:TIME_6_DAYS_AGO inLocale:IT_IT_LOCALE],
                          @"Notifications received six days ago should be displayed as day of week");
    XCTAssertEqualObjects(@"lunedì",
                          [self ageOfEventTime:TIME_7_DAYS_AGO inLocale:IT_IT_LOCALE],
                          @"Notifications received seven days ago should be displayed as day of week");
}

- (void)testAgeOfNotificationReceivedEightOrMoreDaysAgoIsReportedAsShortDate {
    XCTAssertEqualObjects(@"17/10/1982",
                          [self ageOfEventTime:TIME_8_DAYS_AGO inLocale:EN_GB_LOCALE],
                          @"Notifications received eight or more days ago should be displayed as locale formatted short date");
}

- (void)testAgeOfNotificationReceivedEightOrMoreDaysAgoIsReportedAsShortDateInCurrentLocale {
    XCTAssertEqualObjects(@"10/17/1982",
                          [self ageOfEventTime:TIME_8_DAYS_AGO inLocale:EN_US_LOCALE],
                          @"Notifications received eight or more days ago should be displayed as locale formatted short date");
}

- (NSString *)ageOfEventTime:(NSString *)timestamp inLocale:(NSString *)locale {
    OCMStub([mockLocale currentLocale]).andReturn([NSLocale localeWithLocaleIdentifier:locale]);
    OCMStub([mockDate date]).andReturn([formatter dateFromString:CURRENT_TIME]);
    return [dateTools ageOfEventTime:[formatter dateFromString:timestamp]];
}

@end

