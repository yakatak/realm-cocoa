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
#import "RLMRealm_Dynamic.h"

@interface LinkTests : RLMTestCase
@end

@implementation LinkTests

- (void)testBasicLink
{
    RLMRealm *realm = [self realmWithTestPath];
    
    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = @"Tim";
    owner.dog = [[DogObject alloc] init];
    owner.dog.dogName = @"Harvie";
    
    [realm beginWriteTransaction];
    [realm addObject:owner];
    [realm commitWriteTransaction];
    
    RLMArray *owners = [realm objects:[OwnerObject className] withPredicate:nil];
    RLMArray *dogs = [realm objects:[DogObject className] withPredicate:nil];
    XCTAssertEqual(owners.count, (NSUInteger)1, @"Expecting 1 owner");
    XCTAssertEqual(dogs.count, (NSUInteger)1, @"Expecting 1 dog");
    XCTAssertEqualObjects([owners[0] name], @"Tim", @"Tim is named Tim");
    XCTAssertEqualObjects([dogs[0] dogName], @"Harvie", @"Harvie is named Harvie");
    
    OwnerObject *tim = owners[0];
    XCTAssertEqualObjects(tim.dog.dogName, @"Harvie", @"Tim's dog should be Harvie");
}

-(void)testBasicLinkWithNil
{
    RLMRealm *realm = [self realmWithTestPath];

    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = @"Tim";
    owner.dog = nil;

    [realm beginWriteTransaction];
    [realm addObject:owner];
    [realm commitWriteTransaction];

    RLMArray *owners = [realm objects:[OwnerObject className] withPredicate:nil];
    RLMArray *dogs = [realm objects:[DogObject className] withPredicate:nil];
    XCTAssertEqual(owners.count, (NSUInteger)1, @"Expecting 1 owner");
    XCTAssertEqual(dogs.count, (NSUInteger)0, @"Expecting 0 dogs");
    XCTAssertEqualObjects([owners[0] name], @"Tim", @"Tim is named Tim");

    OwnerObject *tim = owners[0];
    XCTAssertEqualObjects(tim.dog, nil, @"Tim does not have a dog");
}

- (void)testMultipleOwnerLink
{
    RLMRealm *realm = [self realmWithTestPath];
    
    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = @"Tim";
    owner.dog = [[DogObject alloc] init];
    owner.dog.dogName = @"Harvie";
    
    [realm beginWriteTransaction];
    [realm addObject:owner];
    [realm commitWriteTransaction];
    
    XCTAssertEqual([realm objects:[OwnerObject className] withPredicate:nil].count, (NSUInteger)1, @"Expecting 1 owner");
    XCTAssertEqual([realm objects:[DogObject className] withPredicate:nil].count, (NSUInteger)1, @"Expecting 1 dog");
    
    [realm beginWriteTransaction];
    OwnerObject *fiel = [OwnerObject createInRealm:realm withObject:@[@"Fiel", [NSNull null]]];
    fiel.dog = owner.dog;
    [realm commitWriteTransaction];
    
    XCTAssertEqual([realm objects:[OwnerObject className] withPredicate:nil].count, (NSUInteger)2, @"Expecting 2 owners");
    XCTAssertEqual([realm objects:[DogObject className] withPredicate:nil].count, (NSUInteger)1, @"Expecting 1 dog");
}

- (void)testLinkRemoval
{
    RLMRealm *realm = [self realmWithTestPath];
    
    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = @"Tim";
    owner.dog = [[DogObject alloc] init];
    owner.dog.dogName = @"Harvie";
    
    [realm beginWriteTransaction];
    [realm addObject:owner];
    [realm commitWriteTransaction];
    
    XCTAssertEqual([realm objects:[OwnerObject className] withPredicate:nil].count, (NSUInteger)1, @"Expecting 1 owner");
    XCTAssertEqual([realm objects:[DogObject className] withPredicate:nil].count, (NSUInteger)1, @"Expecting 1 dog");
    
    [realm beginWriteTransaction];
    DogObject *dog = owner.dog;
    [realm deleteObject:dog];
    [realm commitWriteTransaction];
    
    XCTAssertNil(owner.dog, @"Dog should be nullified when deleted");
    XCTAssertThrows(dog.dogName, @"Dog object should be invalid after being deleted from the realm");

    // refresh owner and check
    owner = [realm allObjects:[OwnerObject className]].firstObject;
    XCTAssertNotNil(owner, @"Should have 1 owner");
    XCTAssertNil(owner.dog, @"Dog should be nullified when deleted");
    XCTAssertEqual([realm objects:[DogObject className] withPredicate:nil].count, (NSUInteger)0, @"Expecting 0 dogs");
}

- (void)testInvalidLinks
{
    RLMRealm *realm = [self realmWithTestPath];
    
    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = @"Tim";
    owner.dog = [[DogObject alloc] init];
    
    [realm beginWriteTransaction];
    XCTAssertThrows([realm addObject:owner], @"dogName not set on linked object");
    
    StringObject *to = [StringObject createInRealm:realm withObject:@[@"testObject"]];
    NSArray *args = @[@"Tim", to];
    XCTAssertThrows([OwnerObject createInRealm:realm withObject:args], @"Inserting wrong object type should throw");
    [realm commitWriteTransaction];
}

- (void)testLinkQueryString
{
    RLMRealm *realm = [self realmWithTestPath];

    OwnerObject *owner1 = [[OwnerObject alloc] init];
    owner1.name = @"Tim";
    owner1.dog = [[DogObject alloc] init];
    owner1.dog.dogName = @"Harvie";

    [realm beginWriteTransaction];
    [realm addObject:owner1];
    [realm commitWriteTransaction];

    XCTAssertEqual(([[realm objects:[OwnerObject className] where:@"dog.dogName = 'Harvie'"] count]), (NSUInteger)1, @"Expecting 1 dog");
    XCTAssertEqual(([[realm objects:[OwnerObject className] where:@"dog.dogName = 'eivraH'"] count]), (NSUInteger)0, @"Expecting 0 dogs");
    XCTAssertEqual(([[realm objects:[OwnerObject className] where:@"dog.dogName = 'Harvie'"] count]), (NSUInteger)1, @"Expecting 1 dog");


    OwnerObject *owner2 = [[OwnerObject alloc] init];
    owner2.name = @"Joe";
    owner2.dog = [[DogObject alloc] init];
    owner2.dog.dogName = @"Harvie";

    [realm beginWriteTransaction];
    [realm addObject:owner2];
    [realm commitWriteTransaction];

    XCTAssertEqual(([[realm objects:[OwnerObject className] where:@"dog.dogName = 'Harvie'"] count]), (NSUInteger)2, @"Expecting 2 dogs");
    XCTAssertEqual(([[realm objects:[OwnerObject className] where:@"dog.dogName = 'eivraH'"] count]), (NSUInteger)0, @"Expecting 0 dogs");
    XCTAssertEqual(([[realm objects:[OwnerObject className] where:@"dog.dogName = 'Harvie'"] count]), (NSUInteger)2, @"Expecting 2 dogs");


    OwnerObject *owner3 = [[OwnerObject alloc] init];
    owner3.name = @"Jim";
    owner3.dog = [[DogObject alloc] init];
    owner3.dog.dogName = @"Fido";

    [realm beginWriteTransaction];
    [realm addObject:owner3];
    [realm commitWriteTransaction];

    XCTAssertEqual(([[realm objects:[OwnerObject className] where:@"dog.dogName = 'Harvie'"] count]), (NSUInteger)2, @"Expecting 2 dogs");
    XCTAssertEqual(([[realm objects:[OwnerObject className] where:@"dog.dogName = 'eivraH'"] count]), (NSUInteger)0, @"Expecting 0 dogs");
    XCTAssertEqual(([[realm objects:[OwnerObject className] where:@"dog.dogName = 'Fido'"] count]), (NSUInteger)1, @"Expecting 1 dogs");
    XCTAssertEqual(([[realm objects:[OwnerObject className] where:@"dog.dogName = 'Harvie'"] count]), (NSUInteger)2, @"Expecting 2 dogs");
    
    // test !=
    XCTAssertEqual(([[realm objects:[OwnerObject className] where:@"dog.dogName != 'Harvie'"] count]), (NSUInteger)1, @"Expecting 1 dogs");

    // test invalid operators
    XCTAssertThrows([realm objects:[OwnerObject className] where:@"dog.dogName > 'Harvie'"], @"Invalid operator should throw");
}

- (void)testLinkQueryAllTypes
{
    RLMRealm *realm = [self realmWithTestPath];

    NSDate *now = [NSDate dateWithTimeIntervalSince1970:100000];

    LinkToAllTypesObject *linkToAllTypes = [[LinkToAllTypesObject alloc] init];
    linkToAllTypes.allTypesCol = [[AllTypesObject alloc] init];
    linkToAllTypes.allTypesCol.boolCol = YES;
    linkToAllTypes.allTypesCol.intCol = 1;
    linkToAllTypes.allTypesCol.floatCol = 1.1f;
    linkToAllTypes.allTypesCol.doubleCol = 1.11;
    linkToAllTypes.allTypesCol.stringCol = @"string";
    linkToAllTypes.allTypesCol.binaryCol = [NSData dataWithBytes:"a" length:1];
    linkToAllTypes.allTypesCol.dateCol = now;
    linkToAllTypes.allTypesCol.cBoolCol = YES;
    linkToAllTypes.allTypesCol.longCol = 11;
    linkToAllTypes.allTypesCol.mixedCol = @0;
    StringObject *obj = [[StringObject alloc] initWithObject:@[@"string"]];
    linkToAllTypes.allTypesCol.objectCol = obj;

    [realm beginWriteTransaction];
    [realm addObject:linkToAllTypes];
    [realm commitWriteTransaction];

    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.boolCol = YES"] count], (NSUInteger)1, @"1 expected");
    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.boolCol = NO"] count], (NSUInteger)0, @"0 expected");

    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.intCol = 1"] count], (NSUInteger)1, @"1 expected");
    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.intCol != 1"] count], (NSUInteger)0, @"0 expected");

    NSPredicate *predEq = [NSPredicate predicateWithFormat:@"allTypesCol.floatCol = %f", 1.1];
    XCTAssertEqual([LinkToAllTypesObject objectsInRealm:realm withPredicate:predEq].count, (NSUInteger)1, @"1 expected");
    NSPredicate *predLessEq = [NSPredicate predicateWithFormat:@"allTypesCol.floatCol <= %f", 1.1];
    XCTAssertEqual([LinkToAllTypesObject objectsInRealm:realm withPredicate:predLessEq].count, (NSUInteger)1, @"1 expected");
    NSPredicate *predLess = [NSPredicate predicateWithFormat:@"allTypesCol.floatCol < %f", 1.1];
    XCTAssertEqual([LinkToAllTypesObject objectsInRealm:realm withPredicate:predLess].count, (NSUInteger)0, @"1 expected");
    
    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.doubleCol = 1.11"] count], (NSUInteger)1, @"1 expected");
    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.doubleCol >= 1.11"] count], (NSUInteger)1, @"1 expected");
    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.doubleCol > 1.11"] count], (NSUInteger)0, @"0 expected");

    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.longCol = 11"] count], (NSUInteger)1, @"1 expected");
    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.longCol != 11"] count], (NSUInteger)0, @"0 expected");

    XCTAssertEqual(([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.dateCol = %@", now] count]), (NSUInteger)1, @"1 expected");
    XCTAssertEqual(([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.dateCol != %@", now] count]), (NSUInteger)0, @"0 expected");
}

- (void)testLinkQueryInvalid {
    XCTAssertThrows([LinkToAllTypesObject objectsWhere:@"allTypesCol.binaryCol = 'a'"], @"Binary data not supported");
    XCTAssertThrows([LinkToAllTypesObject objectsWhere:@"allTypesCol.mixedCol = 'a'"], @"Mixed data not supported");
    XCTAssertThrows([LinkToAllTypesObject objectsWhere:@"allTypesCol.invalidCol = 'a'"], @"Invalid column name should throw");

    XCTAssertThrows([LinkToAllTypesObject objectsWhere:@"allTypesCol.longCol = 'a'"], @"Wrong data type should throw");

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"allTypesCol.floatCol BETWEEN %@", @[@1.1, @1.2]];
    XCTAssertThrows([LinkToAllTypesObject objectsWithPredicate:pred], @"BETWEEN query should throw");

    XCTAssertThrows([LinkToAllTypesObject objectsWhere:@"intArray.intCol > 5"], @"RLMArray query without ANY modifier should throw");
}

- (void)testLinkTooManyRelationships
{
    RLMRealm *realm = [self realmWithTestPath];

    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = @"Tim";
    owner.dog = [[DogObject alloc] init];
    owner.dog.dogName = @"Harvie";

    [realm beginWriteTransaction];
    [realm addObject:owner];
    [realm commitWriteTransaction];

    XCTAssertThrows([realm objects:[OwnerObject className] where:@"dog.dogName.first = 'Fifo'"], @"3 levels of relationship");

}

// FIXME - disabled until we fix commit log issue which break transacions when leaking realm objects
/*
- (void)testCircularLinks 
 {
    RLMRealm *realm = [self realmWithTestPath];
    
    CircleObject *obj = [[CircleObject alloc] init];
    obj.data = @"a";
    obj.next = obj;
    
    [realm beginWriteTransaction];
    [realm addObject:obj];
    obj.next.data = @"b";
    [realm commitWriteTransaction];
    
    CircleObject *obj1 = [realm allObjects:CircleObject.className].firstObject;
    XCTAssertEqualObjects(obj1.data, @"b", @"data should be 'b'");
    XCTAssertEqualObjects(obj1.data, obj.next.data, @"objects should be equal");
}*/

@end

