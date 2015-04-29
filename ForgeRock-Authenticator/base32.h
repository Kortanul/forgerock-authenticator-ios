/*
 Base32 implementation

 Copyright 2010 Google Inc.
 Author: Markus Gutschke

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 Portions copyright 2015 ForgeRock AS.
 */


/*
 Encode and decode base32 encoding using the following alphabet:
 "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
 
 This alphabet is specified in the RFC 4668
 (http://tools.ietf.org/html/rfc4648)

 White-space and hyphens will be allowed but ignored. All other characters 
 are considered invalid.
 
 Encoding is performed in quantums of 8 encoded characters. If the output
 string is less than a full quantum, it will be padded with the '=' 
 character to make a full quantun.
 
 All functions return the number of output bytes or -1 on error. If the
 output buffer is too small, the result will silently be truncated.
 */

#ifndef _BASE32_H_
#define _BASE32_H_
#import <stdint.h>
int __attribute__((visibility("hidden")))
base32_decode(const char *encoded, uint8_t *result, int bufSize);

int __attribute__((visibility("hidden")))
base32_encode(const uint8_t *data, int length, char *result, int bufSize);
#endif /* _BASE32_H_ */