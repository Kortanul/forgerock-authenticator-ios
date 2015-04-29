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

#import <string.h>
#import "base32.h"

/*
 Decode a base32 encoded string into the provided buffer.
 
 Uses the algorithm described in RFC 4648
 (http://tools.ietf.org/html/rfc4648#page-8)
 
 Includes parsing the padding symbol '='.
 
 Params:
 
 encoded - A null terminated char* containing the encoded base32
 result - An initialised buffer to contain the decoded result
 bufSize - The size of the initialised buffer
 
 Return:
 
 A count of length of the decoded string
*/
int
base32_decode(const char *encoded, uint8_t *result, int bufSize)
{
    int buffer = 0;
    int bitsLeft = 0;
    int count = 0;

    for (const char *ptr = encoded; count < bufSize && *ptr; ++ptr) {
        char ch = *ptr;
        if (ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n' || ch == '-' || ch == '=')
            continue;
        buffer <<= 5;
        
        // Deal with commonly mistyped characters
        if (ch == '0')
            ch = 'O';
        else if (ch == '1')
            ch = 'L';
        else if (ch == '8')
            ch = 'B';
        
        // Look up one base32 digit
        if ((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z'))
            ch = (ch & 0x1F) - 1;
        else if (ch >= '2' && ch <= '7')
            ch -= '2' - 26;
        else
            return -1;
        
        buffer |= ch;
        bitsLeft += 5;
        if (bitsLeft >= 8) {
            result[count++] = buffer >> (bitsLeft - 8);
            bitsLeft -= 8;
        }
    }

    if (count < bufSize)
        result[count] = '\000';

    return count;
}

/*
 Encode a string with base32 encoding into the provided buffer.
 
 Uses the algorithm described in RFC 4648
 (http://tools.ietf.org/html/rfc4648#page-8)
 
 Includes inserting padding symbols as required.
 
 Params:
 
 data - A possibly null terminated buffer containing the characters to encode
 length - The number of characters in 'data'
 result - A pre-initialised buffer to store the encoded characters in
 bufSize - The size of the 'result' buffer
 
 Return:
 
 A count of length of the encoded string
 */
int
base32_encode(const uint8_t *data, int length, char *result, int bufSize)
{
    int count = 0;
    int quantum = 8;

    if (length < 0 || length > (1 << 28))
        return -1;

    if (length > 0) {
        int buffer = data[0];
        int next = 1;
        int bitsLeft = 8;


        while (count < bufSize && (bitsLeft > 0 || next < length)) {
            if (bitsLeft < 5) {
                if (next < length) {
                    buffer <<= 8;
                    buffer |= data[next++] & 0xFF;
                    bitsLeft += 8;
                } else {
                    int pad = 5 - bitsLeft;
                    buffer <<= pad;
                    bitsLeft += pad;
                }
            }

            int index = 0x1F & (buffer >> (bitsLeft - 5));
            bitsLeft -= 5;
            result[count++] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"[index];
            
            // Track the characters which make up a single quantum of 8 characters
            quantum--;
            if (quantum == 0) {
                quantum = 8;
            }
        }
    }
    
    // If the number of encoded characters does not make a full quantum, insert padding
    if (quantum != 8) {
        while (quantum > 0) {
            result[count++] = '=';
            quantum--;
        }
    }
    
    if (count < bufSize)
        result[count] = '\000';

    return count;
}