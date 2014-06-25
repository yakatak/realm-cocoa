////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>
#import "KZPropertyMapper.h"

BOOL validateArguments(int argc, const char * argv[]) {
    if (argc != 2 ||
        [[NSString stringWithFormat:@"%s", argv[1]] rangeOfString:@"^.*\\.json$" options:NSRegularExpressionSearch].location == NSNotFound) {
        return NO;
    }
    return YES;
}

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        if (!validateArguments(argc, argv)) {
            printf("realm-import must be called with a single json file\n\nUsage: realm-import \"my file.json\"\n");
            return 1;
        }
        
    }
    return 0;
}
