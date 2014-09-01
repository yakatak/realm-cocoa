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

#import "RLMTestCase.h"

#import <libkern/OSAtomic.h>

@interface RLMRealm ()

+ (BOOL)isCoreDebug;

@end

@interface RealmTests : RLMTestCase
@end

@implementation RealmTests

#pragma mark - Tests

- (void)testCoreDebug {
#if DEBUG
    XCTAssertTrue([RLMRealm isCoreDebug], @"Debug version of Realm should use libtightdb{-ios}-dbg");
#else
    XCTAssertFalse([RLMRealm isCoreDebug], @"Release version of Realm should use libtightdb{-ios}");
#endif
}

- (void)testRealmExists {
    RLMRealm *realm = [self realmWithTestPath];
    XCTAssertNotNil(realm, @"realm should not be nil");
    XCTAssertEqual([realm class], [RLMRealm class], @"realm should be of class RLMRealm");
}

- (void)testRealmFailure
{
    XCTAssertThrows([RLMRealm realmWithPath:@"/dev/null"], @"Shouldn't exist");
}

- (void)testDefaultRealmPath
{
    XCTAssertEqualObjects([[RLMRealm defaultRealm] path], [RLMRealm defaultRealmPath], @"Default Realm path should be correct.");
}

- (void)testRealmPath
{
    RLMRealm *defaultRealm = [RLMRealm defaultRealm];
    XCTAssertEqualObjects(defaultRealm.path, RLMDefaultRealmPath(), @"Default path");
    RLMRealm *testRealm = [self realmWithTestPath];
    XCTAssertEqualObjects(testRealm.path, RLMTestRealmPath(), @"Test path");
}

- (void)testRealmAddAndRemoveObjects {
    RLMRealm *realm = [self realmWithTestPath];
    [realm beginWriteTransaction];
    [StringObject createInRealm:realm withObject:@[@"a"]];
    [StringObject createInRealm:realm withObject:@[@"b"]];
    [StringObject createInRealm:realm withObject:@[@"c"]];
    XCTAssertEqual([StringObject objectsInRealm:realm withPredicate:nil].count, (NSUInteger)3, @"Expecting 3 objects");
    [realm commitWriteTransaction];
    
    // test again after write transaction
    RLMArray *objects = [StringObject allObjectsInRealm:realm];
    XCTAssertEqual(objects.count, (NSUInteger)3, @"Expecting 3 objects");
    XCTAssertEqualObjects([objects.firstObject stringCol], @"a", @"Expecting column to be 'a'");

    [realm beginWriteTransaction];
    [realm deleteObject:objects[2]];
    [realm deleteObject:objects[0]];
    XCTAssertEqual([StringObject objectsInRealm:realm withPredicate:nil].count, (NSUInteger)1, @"Expecting 1 object");
    [realm commitWriteTransaction];
    
    objects = [StringObject allObjectsInRealm:realm];
    XCTAssertEqual(objects.count, (NSUInteger)1, @"Expecting 1 object");
    XCTAssertEqualObjects([objects.firstObject stringCol], @"b", @"Expecting column to be 'b'");
}

- (void)testRealmBatchRemoveObjects {
    RLMRealm *realm = [self realmWithTestPath];
    [realm beginWriteTransaction];
    StringObject *strObj = [StringObject createInRealm:realm withObject:@[@"a"]];
    [StringObject createInRealm:realm withObject:@[@"b"]];
    [StringObject createInRealm:realm withObject:@[@"c"]];
    [realm commitWriteTransaction];

    // delete objects
    RLMArray *objects = [StringObject allObjectsInRealm:realm];
    XCTAssertEqual(objects.count, (NSUInteger)3, @"Expecting 3 objects");
    [realm beginWriteTransaction];
    [realm deleteObjects:objects];
    XCTAssertEqual([[StringObject allObjectsInRealm:realm] count], (NSUInteger)0, @"Expecting 0 objects");
    [realm commitWriteTransaction];

    XCTAssertEqual([[StringObject allObjectsInRealm:realm] count], (NSUInteger)0, @"Expecting 0 objects");
    XCTAssertThrows(strObj.stringCol, @"Object should be invalidated");

    // add objects to linkView
    [realm beginWriteTransaction];
    ArrayPropertyObject *obj = [ArrayPropertyObject createInRealm:realm withObject:@[@"name", @[@[@"a"], @[@"b"], @[@"c"]], @[]]];
    [StringObject createInRealm:realm withObject:@[@"d"]];
    [realm commitWriteTransaction];

    XCTAssertEqual([[StringObject allObjectsInRealm:realm] count], (NSUInteger)4, @"Expecting 4 objects");

    // remove from linkView
    [realm beginWriteTransaction];
    [realm deleteObjects:obj.array];
    [realm commitWriteTransaction];

    XCTAssertEqual([[StringObject allObjectsInRealm:realm] count], (NSUInteger)1, @"Expecting 1 object");
    XCTAssertEqual(obj.array.count, (NSUInteger)0, @"Expecting 0 objects");
    
    // remove NSArray
    NSArray *arrayOfLastObject = @[[[StringObject allObjectsInRealm:realm] lastObject]];
    [realm beginWriteTransaction];
    [realm deleteObjects:arrayOfLastObject];
    [realm commitWriteTransaction];
    XCTAssertEqual(objects.count, (NSUInteger)0, @"Expecting 0 objects");
    
    // add objects to linkView
    [realm beginWriteTransaction];
    [obj.array addObject:[StringObject createInRealm:realm withObject:@[@"a"]]];
    [obj.array addObject:[[StringObject alloc] initWithObject:@[@"b"]]];
    [realm commitWriteTransaction];
    
    // remove objects from realm
    XCTAssertEqual(obj.array.count, (NSUInteger)2, @"Expecting 2 objects");
    [realm beginWriteTransaction];
    [realm deleteObjects:[StringObject allObjectsInRealm:realm]];
    [realm commitWriteTransaction];
    XCTAssertEqual(obj.array.count, (NSUInteger)0, @"Expecting 0 objects");
}

- (void)testRealmTransactionBlock {
    RLMRealm *realm = [self realmWithTestPath];
    [realm transactionWithBlock:^{
        [StringObject createInRealm:realm withObject:@[@"b"]];
    }];
    RLMArray *objects = [StringObject allObjectsInRealm:realm];
    XCTAssertEqual(objects.count, (NSUInteger)1, @"Expecting 1 object");
    XCTAssertEqualObjects([objects.firstObject stringCol], @"b", @"Expecting column to be 'b'");
}

- (void)waitForNotification:(NSString *)expectedNote realm:(RLMRealm *)realm block:(dispatch_block_t)block {
    XCTestExpectation *notificationFired = [self expectationWithDescription:@"notification fired"];
    RLMNotificationToken *token = [realm addNotificationBlock:^(__unused NSString *note, RLMRealm *realm) {
        XCTAssertNotNil(realm, @"Realm should not be nil");
        if (note == expectedNote) {
            [notificationFired fulfill];
        }
    }];

    dispatch_queue_t queue = dispatch_queue_create("background", 0);
    dispatch_async(queue, block);

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    [realm removeNotification:token];
}

- (void)testAutorefreshAfterBackgroundUpdate {
    RLMRealm *realm = [self realmWithTestPath];

    XCTAssertEqual(0U, [StringObject allObjectsInRealm:realm].count);

    [self waitForNotification:RLMRealmDidChangeNotification realm:realm block:^{
        RLMRealm *realm = [self realmWithTestPath];
        [realm beginWriteTransaction];
        [StringObject createInRealm:realm withObject:@[@"string"]];
        [realm commitWriteTransaction];

        XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm].count);
    }];

    XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm].count);
}

- (void)testBackgroundUpdateWithoutAutorefresh {
    RLMRealm *realm = [self realmWithTestPath];
    realm.autorefresh = NO;

    XCTAssertEqual(0U, [StringObject allObjectsInRealm:realm].count);

    [self waitForNotification:RLMRealmRefreshRequiredNotification realm:realm block:^{
        RLMRealm *realm = [self realmWithTestPath];
        [realm beginWriteTransaction];
        [StringObject createInRealm:realm withObject:@[@"string"]];
        [realm commitWriteTransaction];

        XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm].count);
    }];

    XCTAssertEqual(0U, [StringObject allObjectsInRealm:realm].count);

    [realm refresh];
    XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm].count);
}

// FIXME: Re-enable once we find out why this fails intermittently on iOS in Xcode6
// Asana: https://app.asana.com/0/861870036984/14552787865017
#ifndef REALM_SWIFT
- (void)testBackgroundRealmIsNotified {
    RLMRealm *realm = [self realmWithTestPath];

    XCTestExpectation *bgReady = [self expectationWithDescription:@"background queue waiting for commit"];
    __block XCTestExpectation *bgDone = nil;

    dispatch_queue_t queue = dispatch_queue_create("background", 0);
    dispatch_async(queue, ^{
        RLMRealm *realm = [self realmWithTestPath];
        __block bool fulfilled = false;
        RLMNotificationToken *token = [realm addNotificationBlock:^(NSString *note, RLMRealm *realm) {
            XCTAssertNotNil(realm, @"Realm should not be nil");
            XCTAssertEqual(note, RLMRealmDidChangeNotification);
            XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm].count);
            fulfilled = true;
        }];

        // notify main thread that we're ready for it to commit
        [bgReady fulfill];

        // run for two seconds or until we recieve notification
        NSDate *end = [NSDate dateWithTimeIntervalSinceNow:5.0];
        while (!fulfilled) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:end];
        }
        XCTAssertTrue(fulfilled, @"Notification should have been received");

        [realm removeNotification:token];
        [bgDone fulfill];
    });

    // wait for background realm to be created
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    bgDone = [self expectationWithDescription:@"background queue done"];;

    [realm beginWriteTransaction];
    [StringObject createInRealm:realm withObject:@[@"string"]];
    [realm commitWriteTransaction];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}
#endif

- (void)testBeginWriteTransactionsNotifiesWithUpdatedObjects {
    RLMRealm *realm = [self realmWithTestPath];
    realm.autorefresh = NO;

    XCTAssertEqual(0U, [StringObject allObjectsInRealm:realm].count);

    // Create an object in a background thread and wait for that to complete,
    // without refreshing the main thread realm
    [self waitForNotification:RLMRealmRefreshRequiredNotification realm:realm block:^{
        RLMRealm *realm = [self realmWithTestPath];
        [realm beginWriteTransaction];
        [StringObject createInRealm:realm withObject:@[@"string"]];
        [realm commitWriteTransaction];

        XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm].count);
    }];

    // Verify that the main thread realm still doesn't have any objects
    XCTAssertEqual(0U, [StringObject allObjectsInRealm:realm].count);

    // Verify that the local notification sent by the beginWriteTransaction
    // below when it advances the realm to the latest version occurs *after*
    // the advance
    __block bool notificationFired = false;
    RLMNotificationToken *token = [realm addNotificationBlock:^(__unused NSString *note, RLMRealm *realm) {
        XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm].count);
        notificationFired = true;
    }];

    [realm beginWriteTransaction];
    [realm commitWriteTransaction];

    [realm removeNotification:token];
    XCTAssertTrue(notificationFired);
}

- (void)testRealmInMemory
{
    RLMRealm *realmWithFile = [RLMRealm defaultRealm];
    [realmWithFile beginWriteTransaction];
    [StringObject createInRealm:realmWithFile withObject:@[@"a"]];
    [realmWithFile commitWriteTransaction];
    XCTAssertThrows([RLMRealm useInMemoryDefaultRealm], @"Realm instances already created");
}

- (void)testRealmInMemory2
{
    [RLMRealm useInMemoryDefaultRealm];
    
    RLMRealm *realmInMemory = [RLMRealm defaultRealm];
    [realmInMemory beginWriteTransaction];
    [StringObject createInRealm:realmInMemory withObject:@[@"a"]];
    [StringObject createInRealm:realmInMemory withObject:@[@"b"]];
    [StringObject createInRealm:realmInMemory withObject:@[@"c"]];
    XCTAssertEqual([StringObject objectsInRealm:realmInMemory withPredicate:nil].count, (NSUInteger)3, @"Expecting 3 objects");
    [realmInMemory commitWriteTransaction];
}

- (void)testRealmFileAccess
{
    XCTAssertThrows([RLMRealm realmWithPath:nil], @"nil path");
    XCTAssertThrows([RLMRealm realmWithPath:@""], @"empty path");    
    
    NSString *content = @"Some content";
    NSData *fileContents = [content dataUsingEncoding:NSUTF8StringEncoding];
    NSString *filePath = RLMRealmPathForFile(@"filename.realm");
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:fileContents attributes:nil];
    
    NSError *error;
    XCTAssertNil([RLMRealm realmWithPath:filePath readOnly:NO error:&error], @"Invalid database");
    XCTAssertNotNil(error, @"Should populate error object");
}

- (void)testCrossThreadAccess
{
    RLMRealm *realm = RLMRealm.defaultRealm;

    // Using dispatch_async to ensure it actually lands on another thread
    __block OSSpinLock spinlock = OS_SPINLOCK_INIT;
    OSSpinLockLock(&spinlock);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        XCTAssertThrows([realm beginWriteTransaction]);
        XCTAssertThrows([IntObject allObjectsInRealm:realm]);
        XCTAssertThrows([IntObject objectsInRealm:realm where:@"intCol = 0"]);
        OSSpinLockUnlock(&spinlock);
    });
    OSSpinLockLock(&spinlock);
}

@end
