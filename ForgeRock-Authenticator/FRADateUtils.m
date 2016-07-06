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

#import "FRADateUtils.h"

@implementation FRADateUtils

- (NSString *)ageOfEventTime:(NSDate *)eventTime {
    NSDate *currentTime = [NSDate date];
    NSLocale *locale = [NSLocale currentLocale];
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    NSString *shortTimeFormat = [NSDateFormatter dateFormatFromTemplate:@"HHmm" options:0 locale:locale];
    [timeFormatter setDateFormat:shortTimeFormat];
    
    NSDateFormatter *dayOfWeekFormatter = [[NSDateFormatter alloc] init];
    [dayOfWeekFormatter setDateFormat:@"EEEE"];
    // Although iOS will give day of the week in the correct language for the device's locale/language settings
    // we should instead perform explicit translation ourselves. This ensures that the app's localizable strings
    // are fully translated or not translated at all - It would seem odd to only show day of the week in the
    // device's language while all other strings are shown in English.
    [dayOfWeekFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_GB"]];

    NSDateFormatter *localeDateFormatter = [[NSDateFormatter alloc] init];
    NSString *shortDateFormat = [NSDateFormatter dateFormatFromTemplate:@"ddMMyyyy" options:0 locale:locale];
    [localeDateFormatter setDateFormat:shortDateFormat];
    
    NSDate *now = currentTime;
    NSDate *midnight = [self midnightOfDate:now];
    
    NSTimeInterval secondsSinceMidnight = [now timeIntervalSinceDate:midnight];
    NSTimeInterval secondsSinceNotification = [now timeIntervalSinceDate:eventTime];
    NSTimeInterval secondsInDay = (NSTimeInterval) 24.0 * 60.0 * 60.0;
    
    if (secondsSinceNotification < secondsSinceMidnight) {
        return [timeFormatter stringFromDate:eventTime];
    } else if (secondsSinceNotification < (secondsSinceMidnight + secondsInDay)) {
        return NSLocalizedString(@"yesterday", nil);
    } else if (secondsSinceNotification < (secondsSinceMidnight + (7 * secondsInDay))) {
        return NSLocalizedString([dayOfWeekFormatter stringFromDate:eventTime], nil);
    }
    return [localeDateFormatter stringFromDate:eventTime];
}

- (NSDate *)midnightOfDate:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSCalendarUnit preservedComponents = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay);
    NSDateComponents *components = [calendar components:preservedComponents fromDate:date];
    return [calendar dateFromComponents:components];
}

@end
