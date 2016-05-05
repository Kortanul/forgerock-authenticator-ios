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
    NSString* codeText;
    uint64_t startTime;
    uint64_t endTime;
}

- (instancetype)initWithValue:(NSString*)value startTime:(uint64_t)start endTime:(uint64_t)end {
    _value = value;
    startTime = start * 1000;
    endTime = end * 1000;
    return self;
}

- (float)progress {
    uint64_t now = currentTimeInMilli();
    
    if (now < startTime) {
        return 0.0;
    }
    if (now < endTime) {
        float totalTime = (float) (endTime - startTime);
        return (now - startTime) / totalTime;
    }
    return 1.0;
}

- (BOOL)hasExpired {
    return [self progress] == 1.0;
}

@end
