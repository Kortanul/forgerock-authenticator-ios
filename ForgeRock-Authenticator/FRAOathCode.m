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
 *
 * Portions Copyright 2014 Nathaniel McCallum, Red Hat
 */

#import "FRAOathCode.h"

static uint64_t currentTimeInMilli() {
    struct timeval tv;
    
    if (gettimeofday(&tv, NULL) != 0) {
        return 0;
    }
    
    return tv.tv_sec * 1000 + tv.tv_usec / 1000;
}

@implementation FRAOathCode {
    FRAOathCode* nextCode;
    NSString* codeText;
    uint64_t startTime;
    uint64_t endTime;
}

- (instancetype)initWithCode:(NSString*)code startTime:(time_t)start endTime:(time_t)end {
    codeText = code;
    startTime = start * 1000;
    endTime = end * 1000;
    nextCode = nil;
    return self;
}

- (instancetype)initWithCode:(NSString*)code startTime:(time_t)start endTime:(time_t)end nextTokenCode:(FRAOathCode*)next {
    self = [self initWithCode:code startTime:start endTime:end];
    nextCode = next;
    return self;
}

- (NSString*)currentCode {
    uint64_t now = currentTimeInMilli();
    
    if (now < startTime) {
        return nil;
    }
    if (now < endTime) {
        return codeText;
    }
    if (nextCode != nil) {
        return [nextCode currentCode];
    }
    return nil;
}

- (float)currentProgress {
    uint64_t now = currentTimeInMilli();
    
    if (now < startTime) {
        return 0.0;
    }
    if (now < endTime) {
        float totalTime = (float) (endTime - startTime);
        return 1.0 - (now - startTime) / totalTime;
    }
    if (nextCode != nil) {
        return [nextCode currentProgress];
    }
    return 0.0;
}

- (float)totalProgress {
    uint64_t now = currentTimeInMilli();
    FRAOathCode* last = self;
    
    if (now < startTime) {
        return 0.0;
    }
    // Find the last token code.
    while (last->nextCode != nil) {
        last = last->nextCode;
    }
    if (now < last->endTime) {
        float totalTime = (float) (last->endTime - startTime);
        return 1.0 - (now - startTime) / totalTime;
    }
    return 0.0;
}

- (NSUInteger)totalCodes {
    if (nextCode == nil) {
        return 1;
    }
    return nextCode.totalCodes + 1;
}

@end
