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
#import "RLMPredicateUtil.h"
#import "RLMRealm_Dynamic.h"

#pragma mark - Test Objects

#pragma mark NonRealmEmployeeObject

@interface NonRealmEmployeeObject : NSObject
@property NSString *name;
@property NSInteger age;
@end

@implementation NonRealmEmployeeObject
@end

#pragma mark PersonObject

@interface PersonObject : RLMObject
@property NSString *name;
@property NSInteger age;
@end

@implementation PersonObject
@end

@interface PersonLinkObject : RLMObject
@property PersonObject *person;
@end

@implementation PersonLinkObject
@end

#pragma mark QueryObject

@interface QueryObject : RLMObject
@property (nonatomic, assign) BOOL      bool1;
@property (nonatomic, assign) BOOL      bool2;
@property (nonatomic, assign) NSInteger int1;
@property (nonatomic, assign) NSInteger int2;
@property (nonatomic, assign) float     float1;
@property (nonatomic, assign) float     float2;
@property (nonatomic, assign) double    double1;
@property (nonatomic, assign) double    double2;
@property (nonatomic, copy) NSString   *recordTag;
@end

@implementation QueryObject
@end

#pragma mark - Tests

@interface QueryTests : RLMTestCase
@end

@implementation QueryTests

- (void)testBasicQuery
{
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withObject:@[@"Fiel", @27]];
    [PersonObject createInRealm:realm withObject:@[@"Ari", @33]];
    [PersonObject createInRealm:realm withObject:@[@"Tim", @29]];
    [realm commitWriteTransaction];

    // query on realm
    XCTAssertEqual([realm objects:[PersonObject className] where:@"age > 28"].count, 2U, @"Expecting 2 results");

    // query on realm with order
    RLMArray *results = [[realm objects:[PersonObject className] where:@"age > 28"] arraySortedByProperty:@"age" ascending:YES];
    XCTAssertEqualObjects([results[0] name], @"Tim", @"Tim should be first results");
}

-(void)testQueryBetween
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    NSDate *date1 = [NSDate date];
    NSDate *date2 = [date1 dateByAddingTimeInterval:1];
    NSDate *date3 = [date2 dateByAddingTimeInterval:1];
    NSDate *date33 = [date3 dateByAddingTimeInterval:1];

    StringObject *stringObj = [StringObject new];
    stringObj.stringCol = @"string";

    [realm beginWriteTransaction];
    [AllTypesObject createInRealm:realm withObject:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], date1, @YES, @((long)1), @1, stringObj]];
    [AllTypesObject createInRealm:realm withObject:@[@YES, @2, @2.0f, @2.0, @"b", [@"b" dataUsingEncoding:NSUTF8StringEncoding], date2, @YES, @((long)2), @"mixed", stringObj]];
    [AllTypesObject createInRealm:realm withObject:@[@NO, @3, @3.0f, @3.0, @"c", [@"c" dataUsingEncoding:NSUTF8StringEncoding], date3, @YES, @((long)3), @"mixed", stringObj]];
    [AllTypesObject createInRealm:realm withObject:@[@NO, @33, @3.3f, @3.3, @"cc", [@"cc" dataUsingEncoding:NSUTF8StringEncoding], date33, @NO, @((long)3.3), @"mixed", stringObj]];
    [realm commitWriteTransaction];

    RLMArray *betweenArray = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"intCol BETWEEN %@", @[@2, @3]]];
    XCTAssertEqual(betweenArray.count, 2U, @"Should equal 2");
    betweenArray = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"floatCol BETWEEN %@", @[@1.0f, @4.0f]]];
    XCTAssertEqual(betweenArray.count, 4U, @"Should equal 4");
    betweenArray = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"doubleCol BETWEEN %@", @[@3.0, @7.0f]]];
    XCTAssertEqual(betweenArray.count, 2U, @"Should equal 2");
    betweenArray = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"dateCol BETWEEN %@", @[date2,date3]]];
    XCTAssertEqual(betweenArray.count, 2U, @"Should equal 2");

    betweenArray = [AllTypesObject objectsWhere:@"intCol BETWEEN {2, 3}"];
    XCTAssertEqual(betweenArray.count, 2U, @"Should equal 2");
    betweenArray = [AllTypesObject objectsWhere:@"doubleCol BETWEEN {3.0, 7.0}"];
    XCTAssertEqual(betweenArray.count, 2U, @"Should equal 2");
}

- (void)testQueryWithDates
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    NSDate *date1 = [NSDate date];
    NSDate *date2 = [date1 dateByAddingTimeInterval:1];
    NSDate *date3 = [date2 dateByAddingTimeInterval:1];

    StringObject *stringObj = [StringObject new];
    stringObj.stringCol = @"string";

    [realm beginWriteTransaction];
    [AllTypesObject createInRealm:realm withObject:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], date1, @YES, @((long)1), @1, stringObj]];
    [AllTypesObject createInRealm:realm withObject:@[@YES, @2, @2.0f, @2.0, @"b", [@"b" dataUsingEncoding:NSUTF8StringEncoding], date2, @YES, @((long)2), @"mixed", stringObj]];
    [AllTypesObject createInRealm:realm withObject:@[@NO, @3, @3.0f, @3.0, @"c", [@"c" dataUsingEncoding:NSUTF8StringEncoding], date3, @YES, @((long)3), @"mixed", stringObj]];
    [realm commitWriteTransaction];

    RLMArray *dateArray = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"dateCol < %@", date3]];
    XCTAssertEqual(dateArray.count, 2U, @"2 dates smaller");
    dateArray = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"dateCol =< %@", date3]];
    XCTAssertEqual(dateArray.count, 3U, @"3 dates smaller or equal");
    dateArray = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"dateCol > %@", date1]];
    XCTAssertEqual(dateArray.count, 2U, @"2 dates greater");
    dateArray = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"dateCol => %@", date1]];
    XCTAssertEqual(dateArray.count, 3U, @"3 dates greater or equal");
    dateArray = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"dateCol == %@", date1]];
    XCTAssertEqual(dateArray.count, 1U, @"1 date equal to");
    dateArray = [AllTypesObject objectsWithPredicate:[NSPredicate predicateWithFormat:@"dateCol != %@", date1]];
    XCTAssertEqual(dateArray.count, 2U, @"2 dates not equal to");
}

- (void)testDefaultRealmQuery
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withObject:@[@"Fiel", @27]];
    [PersonObject createInRealm:realm withObject:@[@"Tim", @29]];
    [PersonObject createInRealm:realm withObject:@[@"Ari", @33]];
    [realm commitWriteTransaction];

    // query on class
    RLMArray *all = [PersonObject allObjects];
    XCTAssertEqual(all.count, 3U, @"Expecting 3 results");

    RLMArray *results = [PersonObject objectsWhere:@"age == 27"];
    XCTAssertEqual(results.count, 1U, @"Expecting 1 results");

    // with order
    results = [[PersonObject objectsWhere:@"age > 28"] arraySortedByProperty:@"age" ascending:YES];
    PersonObject *tim = results[0];
    XCTAssertEqualObjects(tim.name, @"Tim", @"Tim should be first results");
}

- (void)testArrayQuery
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withObject:@[@"Fiel", @27]];
    [PersonObject createInRealm:realm withObject:@[@"Tim", @29]];
    [PersonObject createInRealm:realm withObject:@[@"Ari", @33]];
    [realm commitWriteTransaction];

    // query on class
    RLMArray *all = [PersonObject allObjects];
    XCTAssertEqual(all.count, 3U, @"Expecting 3 results");

    RLMArray *some = [[PersonObject objectsWhere:@"age > 28"] arraySortedByProperty:@"age" ascending:YES];

    // query/order on array
    XCTAssertEqual([all objectsWhere:@"age == 27"].count, 1U, @"Expecting 1 result");
    XCTAssertEqual([all objectsWhere:@"age == 28"].count, 0U, @"Expecting 0 results");
    some = [some arraySortedByProperty:@"age" ascending:NO];
    XCTAssertEqualObjects([some[0] name], @"Ari", @"Ari should be first results");
}

- (void)testQuerySorting
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    NSDate *date1 = [NSDate date];
    NSDate *date2 = [date1 dateByAddingTimeInterval:1];
    NSDate *date3 = [date2 dateByAddingTimeInterval:1];
    NSDate *date33 = [date3 dateByAddingTimeInterval:1];

    [realm beginWriteTransaction];
    StringObject *stringObj = [StringObject new];
    stringObj.stringCol = @"string";
    [AllTypesObject createInRealm:realm withObject:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], date1, @YES, @((long)1), @1, stringObj]];
    [AllTypesObject createInRealm:realm withObject:@[@YES, @2, @2.0f, @2.0, @"b", [@"b" dataUsingEncoding:NSUTF8StringEncoding], date2, @YES, @((long)2), @"mixed", stringObj]];
    [AllTypesObject createInRealm:realm withObject:@[@NO, @3, @3.0f, @3.0, @"c", [@"c" dataUsingEncoding:NSUTF8StringEncoding], date3, @YES, @((long)3), @"mixed", stringObj]];
    [AllTypesObject createInRealm:realm withObject:@[@NO, @33, @3.3f, @3.3, @"cc", [@"cc" dataUsingEncoding:NSUTF8StringEncoding], date33, @NO, @((long)3.3), @"mixed", stringObj]];
    [realm commitWriteTransaction];


    //////////// sort by boolCol
    RLMArray *results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"boolCol" ascending:YES];
    AllTypesObject *o = results[0];
    XCTAssertEqual(o.boolCol, NO, @"Should be NO");

    results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"boolCol" ascending:NO];
    o = results[0];
    XCTAssertEqual(o.boolCol, YES, @"Should be YES");


    //////////// sort by intCol
    results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"intCol" ascending:YES];
    o = results[0];
    XCTAssertEqual(o.intCol, 1, @"Should be 1");

    results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"intCol" ascending:NO];
    o = results[0];
    XCTAssertEqual(o.intCol, 33, @"Should be 33");


    //////////// sort by dateCol
    results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"dateCol" ascending:YES];
    o = results[0];
    XCTAssertEqualWithAccuracy(o.dateCol.timeIntervalSince1970, date1.timeIntervalSince1970, 1, @"Should be date1");

    results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"dateCol" ascending:NO];
    o = results[0];
    XCTAssertEqualWithAccuracy(o.dateCol.timeIntervalSince1970, date33.timeIntervalSince1970, 1, @"Should be date33");


    //////////// sort by doubleCol
    results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"doubleCol" ascending:YES];
    o = results[0];
    XCTAssertEqual(o.doubleCol, 1.0, @"Should be 1.0");

    results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"doubleCol" ascending:NO];
    o = results[0];
    XCTAssertEqualWithAccuracy(o.doubleCol, 3.3, 0.0000001, @"Should be 3.3");


    //////////// sort by floatCol
    results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"floatCol" ascending:YES];
    o = results[0];
    XCTAssertEqual(o.floatCol, 1.0, @"Should be 1.0");

    results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"floatCol" ascending:NO];
    o = results[0];
    XCTAssertEqualWithAccuracy(o.floatCol, 3.3, 0.0000001, @"Should be 3.3");


    //////////// sort by stringCol
    results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"stringCol" ascending:YES];
    o = results[0];
    XCTAssertEqualObjects(o.stringCol, @"a", @"Should be a");

    results = [[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"stringCol" ascending:NO];
    o = results[0];
    XCTAssertEqualObjects(o.stringCol, @"cc", @"Should be cc");


    // sort by mixed column
    XCTAssertThrows([[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"mixedCol" ascending:YES], @"Sort on mixed col not supported");
    XCTAssertThrows([[AllTypesObject objectsWithPredicate:nil] arraySortedByProperty:@"mixedCol" ascending:NO], @"Sort on mixed col not supported");

    // sort by invalid column name
    XCTAssertThrows([[AllTypesObject allObjects] arraySortedByProperty:@"invalidProperty" ascending:YES]);
}

- (void)testClassMisuse
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    // class not derived from RLMObject
    XCTAssertThrows([realm objects:@"NonRealmPersonObject" where:@"age > 25"], @"invalid object type");
    XCTAssertThrows([[realm objects:@"NonRealmPersonObject" where:@"age > 25"] arraySortedByProperty:@"age" ascending:YES], @"invalid object type");

    // empty string for class name
    XCTAssertThrows([realm objects:@"" where:@"age > 25"], @"missing class name");
    XCTAssertThrows([[realm objects:@"" where:@"age > 25"] arraySortedByProperty:@"age" ascending:YES], @"missing class name");

    // nil class name
    XCTAssertThrows([realm objects:nil where:@"age > 25"], @"nil class name");
    XCTAssertThrows([[realm objects:nil where:@"age > 25"] arraySortedByProperty:@"age" ascending:YES], @"nil class name");
}

- (void)testPredicateValidUse
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    // boolean false
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == no"], @"== no");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == No"], @"== No");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == NO"], @"== NO");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == false"], @"== false");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == False"], @"== False");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == FALSE"], @"== FALSE");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == 0"], @"== 0");

    // boolean true
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == yes"], @"== yes");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == Yes"], @"== Yes");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == YES"], @"== YES");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == true"], @"== true");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == True"], @"== True");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == TRUE"], @"== TRUE");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol == 1"], @"== 1");

    // inequality
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol != YES"], @"!= YES");
    XCTAssertNoThrow([AllTypesObject objectsInRealm:realm where:@"boolCol <> YES"], @"<> YES");
}

- (void)testPredicateNotSupported
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    NSString *className = PersonObject.className;

    // testing for null
    XCTAssertThrows([realm objects:className where:@"stringCol = nil"], @"test for nil");

    // ANY
    XCTAssertThrows([realm objects:className where:@"ANY intCol > 5"], @"ANY int > constant");

    // ALL
    XCTAssertThrows([realm objects:className where:@"ALL intCol > 5"], @"ALL int > constant");
}

- (void)testPredicateMisuse
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    NSString *className = PersonObject.className;

    // invalid column/property name
    XCTAssertThrows([realm objects:className where:@"height > 72"], @"invalid column");

    // wrong/invalid data types
    XCTAssertThrows([realm objects:className where:@"age != xyz"], @"invalid type");
    XCTAssertThrows([realm objects:className where:@"name == 3"], @"invalid type");
    XCTAssertThrows([realm objects:className where:@"age IN {'xyz'}"], @"invalid type");
    XCTAssertThrows([realm objects:className where:@"name IN {3}"], @"invalid type");

    XCTAssertThrows([realm objects:className where:@"age != xyz"], @"invalid type");
    className = AllTypesObject.className;

    XCTAssertThrows([realm objects:className where:@"boolCol == Foo"], @"invalid type");
    XCTAssertThrows([realm objects:className where:@"boolCol == 2"], @"invalid type");
    XCTAssertThrows([realm objects:className where:@"dateCol == 7"], @"invalid type");
    XCTAssertThrows([realm objects:className where:@"doubleCol == The"], @"invalid type");
    XCTAssertThrows([realm objects:className where:@"floatCol == Bar"], @"invalid type");
    XCTAssertThrows([realm objects:className where:@"intCol == Baz"], @"invalid type");

    className = PersonObject.className;

    // compare two constants
    XCTAssertThrows([realm objects:className where:@"3 == 3"], @"comparing 2 constants");

    // invalid strings
    XCTAssertThrows([realm objects:className where:@""], @"empty string");
    XCTAssertThrows([realm objects:className where:@"age"], @"column name only");
    XCTAssertThrows([realm objects:className where:@"sdlfjasdflj"], @"gibberish");
    XCTAssertThrows([realm objects:className where:@"age * 25"], @"invalid operator");
    XCTAssertThrows([realm objects:className where:@"age === 25"], @"invalid operator");
    XCTAssertThrows([realm objects:className where:@","], @"comma");
    XCTAssertThrows([realm objects:className where:@"()"], @"parens");

    // not a link column
    XCTAssertThrows([realm objects:className where:@"age.age == 25"]);
    XCTAssertThrows([realm objects:className where:@"age.age.age == 25"]);

    // abuse of BETWEEN
    XCTAssertThrows([realm objects:className where:@"age BETWEEN 25"], @"between with a scalar");
    XCTAssertThrows([realm objects:className where:@"age BETWEEN Foo"], @"between with a string");
    XCTAssertThrows([realm objects:className where:@"age BETWEEN {age, age}"], @"between with array of keypaths");
    XCTAssertThrows([realm objects:className where:@"age BETWEEN {age, 0}"], @"between with array of keypaths");
    XCTAssertThrows([realm objects:className where:@"age BETWEEN {0, age}"], @"between with array of keypaths");
    XCTAssertThrows([realm objects:className where:@"age BETWEEN {0, {1, 10}}"], @"between with nested arrays");

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @[@1]];
    XCTAssertThrows([realm objects:className withPredicate:pred], @"between with array of 1 item");

    pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @[@1, @2, @3]];
    XCTAssertThrows([realm objects:className withPredicate:pred], @"between with array of 3 items");

    pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @[@"Foo", @"Bar"]];
    XCTAssertThrows([realm objects:className withPredicate:pred], @"between with array of strings");

    pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @[@1.5, @2.5]];
    XCTAssertThrows([realm objects:className withPredicate:pred], @"between with array of doubles");

    pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @[@1, @[@2, @3]]];
    XCTAssertThrows([realm objects:className withPredicate:pred], @"between with nested array");

    pred = [NSPredicate predicateWithFormat:@"age BETWEEN %@", @{@25 : @35}];
    XCTAssertThrows([realm objects:className withPredicate:pred], @"between with dictionary");

    pred = [NSPredicate predicateWithFormat:@"height BETWEEN %@", @[@25, @35]];
    XCTAssertThrows([realm objects:className withPredicate:pred], @"invalid property/column");

    // bad type in link IN
    XCTAssertThrows([PersonLinkObject objectsInRealm:realm where:@"person.age IN {'Tim'}"]);
}

- (void)testTwoColumnComparison
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];

    [QueryObject createInRealm:realm withObject:@[@YES, @YES, @1, @2, @23.0f, @1.7f,  @0.0,  @5.55, @"Instance 0"]];
    [QueryObject createInRealm:realm withObject:@[@YES, @NO,  @1, @3, @-5.3f, @4.21f, @1.0,  @4.44, @"Instance 1"]];
    [QueryObject createInRealm:realm withObject:@[@NO,  @NO,  @2, @2, @1.0f,  @3.55f, @99.9, @6.66, @"Instance 2"]];
    [QueryObject createInRealm:realm withObject:@[@NO,  @YES, @3, @6, @4.21f, @1.0f,  @1.0,  @7.77, @"Instance 3"]];
    [QueryObject createInRealm:realm withObject:@[@YES, @YES, @4, @5, @23.0f, @23.0f, @7.4,  @8.88, @"Instance 4"]];
    [QueryObject createInRealm:realm withObject:@[@YES, @NO,  @15, @8, @1.0f,  @66.0f, @1.01, @9.99, @"Instance 5"]];
    [QueryObject createInRealm:realm withObject:@[@NO,  @YES, @15, @15, @1.0f,  @66.0f, @1.01, @9.99, @"Instance 6"]];

    [realm commitWriteTransaction];

    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"bool1 == bool1" expectedCount:7];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"bool1 == bool2" expectedCount:3];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"bool1 != bool2" expectedCount:4];

    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"int1 == int1"  expectedCount:7];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"int1 == int2"  expectedCount:2];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"int1 != int2"  expectedCount:5];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"int1 > int2"   expectedCount:1];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"int1 < int2"   expectedCount:4];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"int1 >= int2"  expectedCount:3];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"int1 <= int2"  expectedCount:6];

    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"float1 == float1"  expectedCount:7];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"float1 == float2"  expectedCount:1];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"float1 != float2"  expectedCount:6];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"float1 > float2"   expectedCount:2];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"float1 < float2"   expectedCount:4];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"float1 >= float2"  expectedCount:3];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"float1 <= float2"  expectedCount:5];

    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"double1 == double1" expectedCount:7];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"double1 == double2" expectedCount:0];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"double1 != double2" expectedCount:7];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"double1 > double2" expectedCount:1];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"double1 < double2" expectedCount:6];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"double1 >= double2" expectedCount:1];
    [self executeTwoColumnKeypathRealmComparisonQueryWithClass:[QueryObject class] predicate:@"double1 <= double2" expectedCount:6];

    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"int1 == int1"  expectedCount:7];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"int1 == int2"  expectedCount:2];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"int1 != int2"  expectedCount:5];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"int1 > int2"   expectedCount:1];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"int1 < int2"   expectedCount:4];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"int1 >= int2"  expectedCount:3];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"int1 <= int2"  expectedCount:6];

    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"float1 == float1"  expectedCount:7];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"float1 == float2"  expectedCount:1];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"float1 != float2"  expectedCount:6];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"float1 > float2"   expectedCount:2];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"float1 < float2"   expectedCount:4];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"float1 >= float2"  expectedCount:3];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"float1 <= float2"  expectedCount:5];

    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"double1 == double1" expectedCount:7];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"double1 == double2" expectedCount:0];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"double1 != double2" expectedCount:7];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"double1 > double2" expectedCount:1];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"double1 < double2" expectedCount:6];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"double1 >= double2" expectedCount:1];
    [self executeTwoColumnKeypathComparisonQueryWithPredicate:@"double1 <= double2" expectedCount:6];

    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[QueryObject class]
                                                   predicate:@"int1 == float1"
                                              expectedReason:@"Property type mismatch between int and float"];

    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[QueryObject class]
                                                   predicate:@"float2 >= double1"
                                              expectedReason:@"Property type mismatch between float and double"];

    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[QueryObject class]
                                                   predicate:@"double2 <= int2"
                                              expectedReason:@"Property type mismatch between double and int"];

    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[QueryObject class]
                                                   predicate:@"int2 != recordTag"
                                              expectedReason:@"Property type mismatch between int and string"];

    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[QueryObject class]
                                                   predicate:@"float1 > recordTag"
                                              expectedReason:@"Property type mismatch between float and string"];

    [self executeInvalidTwoColumnKeypathRealmComparisonQuery:[QueryObject class]
                                                   predicate:@"double1 < recordTag"
                                              expectedReason:@"Property type mismatch between double and string"];
}

- (void)testValidOperatorsInNumericComparison:(NSString *) comparisonType
                              withProposition:(BOOL(^)(NSPredicateOperatorType)) proposition
{
    NSPredicateOperatorType validOps[] = {
        NSLessThanPredicateOperatorType,
        NSLessThanOrEqualToPredicateOperatorType,
        NSGreaterThanPredicateOperatorType,
        NSGreaterThanOrEqualToPredicateOperatorType,
        NSEqualToPredicateOperatorType,
        NSNotEqualToPredicateOperatorType
    };

    for (NSUInteger i = 0; i < sizeof(validOps) / sizeof(NSPredicateOperatorType); ++i)
    {
        XCTAssert(proposition(validOps[i]),
                  @"%@ operator in %@ comparison.",
                  [RLMPredicateUtil predicateOperatorTypeString:validOps[i]],
                  comparisonType);
    }
}

- (void)testValidOperatorsInNumericComparison
{
    [self testValidOperatorsInNumericComparison:@"integer"
                                withProposition:[RLMPredicateUtil isEmptyIntColPredicate]];
    [self testValidOperatorsInNumericComparison:@"float"
                                withProposition:[RLMPredicateUtil isEmptyFloatColPredicate]];
    [self testValidOperatorsInNumericComparison:@"double"
                                withProposition:[RLMPredicateUtil isEmptyDoubleColPredicate]];
    [self testValidOperatorsInNumericComparison:@"date"
                                withProposition:[RLMPredicateUtil isEmptyDateColPredicate]];
}

- (void)testInvalidOperatorsInNumericComparison:(NSString *) comparisonType
                                withProposition:(BOOL(^)(NSPredicateOperatorType)) proposition
{
    NSPredicateOperatorType invalidOps[] = {
        NSMatchesPredicateOperatorType,
        NSLikePredicateOperatorType,
        NSBeginsWithPredicateOperatorType,
        NSEndsWithPredicateOperatorType,
        NSContainsPredicateOperatorType
    };

    for (NSUInteger i = 0; i < sizeof(invalidOps) / sizeof(NSPredicateOperatorType); ++i)
    {
        XCTAssertThrowsSpecificNamed(proposition(invalidOps[i]), NSException,
                                     @"Invalid operator type",
                                     @"%@ operator invalid in %@ comparison.",
                                     [RLMPredicateUtil predicateOperatorTypeString:invalidOps[i]],
                                     comparisonType);
    }
}

- (void)testInvalidOperatorsInNumericComparison
{
    [self testInvalidOperatorsInNumericComparison:@"integer"
                                  withProposition:[RLMPredicateUtil isEmptyIntColPredicate]];
    [self testInvalidOperatorsInNumericComparison:@"float"
                                  withProposition:[RLMPredicateUtil isEmptyFloatColPredicate]];
    [self testInvalidOperatorsInNumericComparison:@"double"
                                  withProposition:[RLMPredicateUtil isEmptyDoubleColPredicate]];
    [self testInvalidOperatorsInNumericComparison:@"date"
                                  withProposition:[RLMPredicateUtil isEmptyDateColPredicate]];
}

- (void)testCustomSelectorsInNumericComparison:(NSString *) comparisonType
                               withProposition:(BOOL(^)()) proposition
{
    XCTAssertThrowsSpecificNamed(proposition(), NSException,
                                 @"Invalid operator type",
                                 @"Custom selector invalid in %@ comparison.", comparisonType);
}

- (void)testCustomSelectorsInNumericComparison
{
    BOOL (^isEmpty)();

    isEmpty = [RLMPredicateUtil alwaysEmptyIntColSelectorPredicate];
    [self testCustomSelectorsInNumericComparison:@"integer" withProposition:isEmpty];

    isEmpty = [RLMPredicateUtil alwaysEmptyFloatColSelectorPredicate];
    [self testCustomSelectorsInNumericComparison:@"float" withProposition:isEmpty];

    isEmpty = [RLMPredicateUtil alwaysEmptyDoubleColSelectorPredicate];
    [self testCustomSelectorsInNumericComparison:@"double" withProposition:isEmpty];

    isEmpty = [RLMPredicateUtil alwaysEmptyDateColSelectorPredicate];
    [self testCustomSelectorsInNumericComparison:@"date" withProposition:isEmpty];
}

- (void)testBooleanPredicate
{
    XCTAssertEqual([BoolObject objectsWhere:@"boolCol == TRUE"].count,
                   0U, @"== operator in bool predicate.");
    XCTAssertEqual([BoolObject objectsWhere:@"boolCol != TRUE"].count,
                   0U, @"== operator in bool predicate.");

    XCTAssertThrowsSpecificNamed([BoolObject objectsWhere:@"boolCol >= TRUE"],
                                 NSException,
                                 @"Invalid operator type",
                                 @"Invalid operator in bool predicate.");
}

- (void)testStringBeginsWith
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    StringObject *so = [StringObject createInRealm:realm withObject:(@[@"abc"])];
    [AllTypesObject createInRealm:realm withObject:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], NSDate.date, @YES, @1LL, @1, so]];
    [realm commitWriteTransaction];

    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol BEGINSWITH 'a'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol BEGINSWITH 'ab'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol BEGINSWITH 'abc'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol BEGINSWITH 'abcd'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol BEGINSWITH 'abd'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol BEGINSWITH 'c'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol BEGINSWITH 'A'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol BEGINSWITH[c] 'a'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol BEGINSWITH[c] 'A'"].count);

#if 0 // FIXME: enable when support is added
    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol BEGINSWITH 'a'"].count);
    XCTAssertEqual(0U, [AllTypesObject objectsWhere:@"objectCol.stringCol BEGINSWITH 'c'"].count);
    XCTAssertEqual(0U, [AllTypesObject objectsWhere:@"objectCol.stringCol BEGINSWITH 'A'"].count);
    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol BEGINSWITH[c] 'a'"].count);
    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol BEGINSWITH[c] 'A'"].count);
#else
    XCTAssertThrows([AllTypesObject objectsWhere:@"objectCol.stringCol BEGINSWITH 'a'"]);
#endif
}

- (void)testStringEndsWith
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    StringObject *so = [StringObject createInRealm:realm withObject:(@[@"abc"])];
    [AllTypesObject createInRealm:realm withObject:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], NSDate.date, @YES, @1LL, @1, so]];
    [realm commitWriteTransaction];

    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol ENDSWITH 'c'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol ENDSWITH 'bc'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol ENDSWITH 'abc'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol ENDSWITH 'aabc'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol ENDSWITH 'bbc'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol ENDSWITH 'a'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol ENDSWITH 'C'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol ENDSWITH[c] 'c'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol ENDSWITH[c] 'C'"].count);

#if 0 // FIXME: enable when support is added
    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol ENDSWITH 'c'"].count);
    XCTAssertEqual(0U, [AllTypesObject objectsWhere:@"objectCol.stringCol ENDSWITH 'a'"].count);
    XCTAssertEqual(0U, [AllTypesObject objectsWhere:@"objectCol.stringCol ENDSWITH 'C'"].count);
    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol ENDSWITH[c] 'c'"].count);
    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol ENDSWITH[c] 'C'"].count);
#else
    XCTAssertThrows([AllTypesObject objectsWhere:@"objectCol.stringCol ENDSWITH 'c'"]);
#endif
}

- (void)testStringContains
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    StringObject *so = [StringObject createInRealm:realm withObject:(@[@"abc"])];
    [AllTypesObject createInRealm:realm withObject:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], NSDate.date, @YES, @1LL, @1, so]];
    [realm commitWriteTransaction];

    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol CONTAINS 'a'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol CONTAINS 'b'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol CONTAINS 'c'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol CONTAINS 'ab'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol CONTAINS 'bc'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol CONTAINS 'abc'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol CONTAINS 'd'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol CONTAINS 'aabc'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol CONTAINS 'bbc'"].count);

    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol CONTAINS 'C'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol CONTAINS[c] 'c'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol CONTAINS[c] 'C'"].count);

#if 0 // FIXME: enable when support is added
    XCTAssertEqual(0U, [AllTypesObject objectsWhere:@"objectCol.stringCol CONTAINS 'd'"].count);
    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol CONTAINS 'c'"].count);
    XCTAssertEqual(0U, [AllTypesObject objectsWhere:@"objectCol.stringCol CONTAINS 'C'"].count);
    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol CONTAINS[c] 'c'"].count);
    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol CONTAINS[c] 'C'"].count);
#else
    XCTAssertThrows([AllTypesObject objectsWhere:@"objectCol.stringCol CONTAINS 'c'"]);
#endif
}

- (void)testStringEquality
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    StringObject *so = [StringObject createInRealm:realm withObject:(@[@"abc"])];
    [AllTypesObject createInRealm:realm withObject:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], NSDate.date, @YES, @1LL, @1, so]];
    [realm commitWriteTransaction];

    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol == 'abc'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol != 'def'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol ==[c] 'abc'"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol ==[c] 'ABC'"].count);

    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol != 'abc'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol == 'def'"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol == 'ABC'"].count);

    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol == 'abc'"].count);
    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol != 'def'"].count);

#if 0 // FIXME: enable when support is added
    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol ==[c] 'abc'"].count);
    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol ==[c] 'ABC'"].count);
#else
    XCTAssertThrows([AllTypesObject objectsWhere:@"objectCol.stringCol ==[c] 'abc'"]);
#endif

    XCTAssertEqual(0U, [AllTypesObject objectsWhere:@"objectCol.stringCol != 'abc'"].count);
    XCTAssertEqual(0U, [AllTypesObject objectsWhere:@"objectCol.stringCol == 'def'"].count);
    XCTAssertEqual(0U, [AllTypesObject objectsWhere:@"objectCol.stringCol == 'ABC'"].count);
}

- (void)testStringIN
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    StringObject *so = [StringObject createInRealm:realm withObject:(@[@"abc"])];
    [AllTypesObject createInRealm:realm withObject:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], NSDate.date, @YES, @1LL, @1, so]];
    [realm commitWriteTransaction];

    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol IN {'abc'}"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol IN[c] {'abc'}"].count);
    XCTAssertEqual(1U, [StringObject objectsWhere:@"stringCol IN[c] {'ABC'}"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol IN {'def'}"].count);
    XCTAssertEqual(0U, [StringObject objectsWhere:@"stringCol IN {'ABC'}"].count);

    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol IN {'abc'}"].count);
#if 0 // FIXME: enable when support is added
    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol IN[c] {'abc'}"].count);
    XCTAssertEqual(1U, [AllTypesObject objectsWhere:@"objectCol.stringCol IN[c] {'ABC'}"].count);
#else
    XCTAssertThrows([AllTypesObject objectsWhere:@"objectCol.stringCol INc] {'abc'}"]);
#endif
    XCTAssertEqual(0U, [AllTypesObject objectsWhere:@"objectCol.stringCol IN {'def'}"].count);
    XCTAssertEqual(0U, [AllTypesObject objectsWhere:@"objectCol.stringCol IN {'ABC'}"].count);
}

- (void)testStringUnsupportedOperations
{
    XCTAssertThrows([StringObject objectsWhere:@"stringCol LIKE 'abc'"]);
    XCTAssertThrows([StringObject objectsWhere:@"stringCol MATCHES 'abc'"]);
    XCTAssertThrows([StringObject objectsWhere:@"stringCol BETWEEN {'a', 'b'}"]);
    XCTAssertThrows([StringObject objectsWhere:@"stringCol < 'abc'"]);

    XCTAssertThrows([AllTypesObject objectsWhere:@"objectCol.stringCol LIKE 'abc'"]);
    XCTAssertThrows([AllTypesObject objectsWhere:@"objectCol.stringCol MATCHES 'abc'"]);
    XCTAssertThrows([AllTypesObject objectsWhere:@"objectCol.stringCol BETWEEN {'a', 'b'}"]);
    XCTAssertThrows([AllTypesObject objectsWhere:@"objectCol.stringCol < 'abc'"]);
}

- (void)testBinaryComparisonInPredicate
{
    NSExpression *binary = [NSExpression expressionForConstantValue:[[NSData alloc] init]];

    NSUInteger (^count)(NSPredicateOperatorType) = ^(NSPredicateOperatorType type) {
        NSPredicate *pred = [RLMPredicateUtil comparisonWithKeyPath: @"binaryCol"
                                                         expression: binary
                                                       operatorType: type];
        return [BinaryObject objectsWithPredicate: pred].count;
    };

    XCTAssertEqual(count(NSBeginsWithPredicateOperatorType), 0U,
                   @"BEGINSWITH operator in binary comparison.");
    XCTAssertEqual(count(NSEndsWithPredicateOperatorType), 0U,
                   @"ENDSWITH operator in binary comparison.");
    XCTAssertEqual(count(NSContainsPredicateOperatorType), 0U,
                   @"CONTAINS operator in binary comparison.");
    XCTAssertEqual(count(NSEqualToPredicateOperatorType), 0U,
                   @"= or == operator in binary comparison.");
    XCTAssertEqual(count(NSNotEqualToPredicateOperatorType), 0U,
                   @"!= or <> operator in binary comparison.");

    // Invalid operators.
    XCTAssertThrowsSpecificNamed(count(NSLessThanPredicateOperatorType), NSException,
                                 @"Invalid operator type",
                                 @"Invalid operator in binary comparison.");
}

- (void)testKeyPathLocationInComparison
{
    NSExpression *keyPath = [NSExpression expressionForKeyPath:@"intCol"];
    NSExpression *expr = [NSExpression expressionForConstantValue:@0];
    NSPredicate *predicate;

    predicate = [RLMPredicateUtil defaultPredicateGenerator](keyPath, expr);
    XCTAssert([RLMPredicateUtil isEmptyIntColWithPredicate:predicate],
              @"Key path to the left in an integer comparison.");

    predicate = [RLMPredicateUtil defaultPredicateGenerator](expr, keyPath);
    XCTAssert([RLMPredicateUtil isEmptyIntColWithPredicate:predicate],
              @"Key path to the right in an integer comparison.");

    predicate = [RLMPredicateUtil defaultPredicateGenerator](keyPath, keyPath);
    XCTAssert([RLMPredicateUtil isEmptyIntColWithPredicate:predicate],
              @"Key path in both locations in an integer comparison.");

    predicate = [RLMPredicateUtil defaultPredicateGenerator](expr, expr);
    XCTAssertThrowsSpecificNamed([RLMPredicateUtil isEmptyIntColWithPredicate:predicate],
                                 NSException, @"Invalid predicate expressions",
                                 @"Key path in absent in an integer comparison.");
}

- (void)executeTwoColumnKeypathRealmComparisonQueryWithClass:(Class)class
                                                   predicate:(NSString *)predicate
                                               expectedCount:(NSUInteger)expectedCount
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    RLMArray *queryResult = [realm objects:NSStringFromClass(class)
                       where:predicate];
    NSUInteger actualCount = queryResult.count;
    XCTAssertEqual(actualCount, expectedCount, @"Predicate: %@, Expecting %zd result(s), found %zd",
                   predicate, expectedCount, actualCount);
}

- (void)executeTwoColumnKeypathComparisonQueryWithPredicate:(NSString *)predicate
                                              expectedCount:(NSUInteger)expectedCount
{
    RLMArray *queryResult = [QueryObject objectsWhere:predicate];
    NSUInteger actualCount = queryResult.count;
    XCTAssertEqual(actualCount, expectedCount, @"Predicate: %@, Expecting %zd result(s), found %zd",
                   predicate, expectedCount, actualCount);
}

- (void)executeInvalidTwoColumnKeypathRealmComparisonQuery:(Class)class
                                                 predicate:(NSString *)predicate
                                            expectedReason:(NSString *)expectedReason
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    @try {
        RLMArray *queryResult = [realm objects:NSStringFromClass(class)
                           where:predicate];
        NSUInteger actualCount = queryResult.count;
#pragma unused(actualCount)

        XCTFail(@"Predicate: %@ - exception expected.", predicate);
    }
    @catch (NSException *exception) {
        if (![expectedReason isEqualToString:exception.reason]) {
            XCTFail(@"Exception reason: expected \"%@\" received @\"%@\"", expectedReason, exception.reason);
        }
        realm = nil;
    }
}


- (void)testFloatQuery
{
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    [FloatObject createInRealm:realm withObject:@[@1.7f]];
    [realm commitWriteTransaction];

    XCTAssertEqual(([[realm objects:[FloatObject className] where:@"floatCol > 1"] count]), 1U, @"1 object expected");
    XCTAssertEqual(([[realm objects:[FloatObject className] where:@"floatCol > %d", 1] count]), 1U, @"1 object expected");
    XCTAssertEqual(([[realm objects:[FloatObject className] where:@"floatCol = 1.7"] count]), 1U, @"1 object expected");
    XCTAssertEqual(([[realm objects:[FloatObject className] where:@"floatCol = %f", 1.7f] count]), 1U, @"1 object expected");
    XCTAssertEqual(([[realm objects:[FloatObject className] where:@"floatCol > 1.0"] count]), 1U, @"1 object expected");
    XCTAssertEqual(([[realm objects:[FloatObject className] where:@"floatCol >= 1.0"] count]), 1U, @"1 object expected");
    XCTAssertEqual(([[realm objects:[FloatObject className] where:@"floatCol < 1.0"] count]), 0U, @"0 objects expected");
    XCTAssertEqual(([[realm objects:[FloatObject className] where:@"floatCol <= 1.0"] count]), 0U, @"0 objects expected");
    XCTAssertEqual(([[realm objects:[FloatObject className] where:@"floatCol BETWEEN %@", @[@1.0, @2.0]] count]), 1U, @"1 object expected");
    XCTAssertEqual(([[realm objects:[FloatObject className] where:@"floatCol = %e", 1.7] count]), 1U, @"1 object expected");
    XCTAssertEqual(([[realm objects:[FloatObject className] where:@"floatCol == %f", FLT_MAX] count]), 0U, @"0 objects expected");
    XCTAssertThrows(([[realm objects:[FloatObject className] where:@"floatCol = 3.5e+38"] count]), @"Too large to be a float");
    XCTAssertThrows(([[realm objects:[FloatObject className] where:@"floatCol = -3.5e+38"] count]), @"Too small to be a float");
}

- (void)testLiveQueriesInsideTransaction
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    {
        [QueryObject createInRealm:realm withObject:@[@YES, @YES, @1, @2, @23.0f, @1.7f,  @0.0,  @5.55, @"Instance 0"]];

        RLMArray *results = [QueryObject objectsWhere:@"bool1 = YES"];
        XCTAssertEqual(results.count, 1U);

        // Delete the (only) object in result set
        [realm deleteObject:[results lastObject]];
        XCTAssertEqual(results.count, 0U);

        // Add an object that does not match query
        QueryObject *q1 = [QueryObject createInRealm:realm withObject:@[@NO, @YES, @1, @2, @23.0f, @1.7f,  @0.0,  @5.55, @"Instance 0"]];
        XCTAssertEqual(results.count, 0U);

        // Change object to match query
        q1.bool1 = YES;
        XCTAssertEqual(results.count, 1U);

        // Add another object that matches
        [QueryObject createInRealm:realm withObject:@[@YES, @NO,  @1, @3, @-5.3f, @4.21f, @1.0,  @4.44, @"Instance 1"]];
        XCTAssertEqual(results.count, 2U);
    }
    [realm commitWriteTransaction];
}

- (void)testLiveQueriesBetweenTransactions
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [QueryObject createInRealm:realm withObject:@[@YES, @YES, @1, @2, @23.0f, @1.7f,  @0.0,  @5.55, @"Instance 0"]];
    [realm commitWriteTransaction];

    RLMArray *results = [QueryObject objectsWhere:@"bool1 = YES"];
    XCTAssertEqual(results.count, 1U);

    // Delete the (only) object in result set
    [realm beginWriteTransaction];
    [realm deleteObject:[results lastObject]];
    [realm commitWriteTransaction];
    XCTAssertEqual(results.count, 0U);

    // Add an object that does not match query
    [realm beginWriteTransaction];
    QueryObject *q1 = [QueryObject createInRealm:realm withObject:@[@NO, @YES, @1, @2, @23.0f, @1.7f,  @0.0,  @5.55, @"Instance 0"]];
    [realm commitWriteTransaction];
    XCTAssertEqual(results.count, 0U);

    // Change object to match query
    [realm beginWriteTransaction];
    q1.bool1 = YES;
    [realm commitWriteTransaction];
    XCTAssertEqual(results.count, 1U);

    // Add another object that matches
    [realm beginWriteTransaction];
    [QueryObject createInRealm:realm withObject:@[@YES, @NO,  @1, @3, @-5.3f, @4.21f, @1.0,  @4.44, @"Instance 1"]];
    [realm commitWriteTransaction];
    XCTAssertEqual(results.count, 2U);
}

- (void)makeDogWithName:(NSString *)name owner:(NSString *)ownerName {
    RLMRealm *realm = [self realmWithTestPath];

    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = ownerName;
    owner.dog = [[DogObject alloc] init];
    owner.dog.dogName = name;

    [realm beginWriteTransaction];
    [realm addObject:owner];
    [realm commitWriteTransaction];
}

- (void)makeDogWithAge:(int)age owner:(NSString *)ownerName {
    RLMRealm *realm = [self realmWithTestPath];

    OwnerObject *owner = [[OwnerObject alloc] init];
    owner.name = ownerName;
    owner.dog = [[DogObject alloc] init];
    owner.dog.dogName = @"";
    owner.dog.age = age;

    [realm beginWriteTransaction];
    [realm addObject:owner];
    [realm commitWriteTransaction];
}

- (void)testLinkQueryString
{
    RLMRealm *realm = [self realmWithTestPath];

    [self makeDogWithName:@"Harvie" owner:@"Tim"];
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName  = 'Harvie'"].count), 1U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName != 'Harvie'"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName  = 'eivraH'"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName  = 'Fido'"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName IN {'Fido', 'Harvie'}"].count), 1U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName IN {'Fido', 'eivraH'}"].count), 0U);

    [self makeDogWithName:@"Harvie" owner:@"Joe"];
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName  = 'Harvie'"].count), 2U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName != 'Harvie'"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName  = 'eivraH'"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName  = 'Fido'"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName IN {'Fido', 'Harvie'}"].count), 2U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName IN {'Fido', 'eivraH'}"].count), 0U);

    [self makeDogWithName:@"Fido" owner:@"Jim"];
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName  = 'Harvie'"].count), 2U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName != 'Harvie'"].count), 1U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName  = 'eivraH'"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName  = 'Fido'"].count), 1U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName IN {'Fido', 'Harvie'}"].count), 3U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName IN {'Fido', 'eivraH'}"].count), 1U);

    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName = 'Harvie' and name = 'Tim'"].count), 1U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.dogName = 'Harvie' and name = 'Jim'"].count), 0U);

    // test invalid operators
    XCTAssertThrows([realm objects:[OwnerObject className] where:@"dog.dogName > 'Harvie'"], @"Invalid operator should throw");
}

- (void)testLinkQueryInt
{
    RLMRealm *realm = [self realmWithTestPath];

    [self makeDogWithAge:5 owner:@"Tim"];
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age  = 5"].count), 1U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age != 5"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age  = 10"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age  = 8"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age IN {5, 8}"].count), 1U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age IN {8, 10}"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age BETWEEN {0, 10}"].count), 1U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age BETWEEN {0, 7}"].count), 1U);

    [self makeDogWithAge:5 owner:@"Joe"];
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age  = 5"].count), 2U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age != 5"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age  = 10"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age  = 8"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age IN {5, 8}"].count), 2U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age IN {8, 10}"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age BETWEEN {0, 10}"].count), 2U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age BETWEEN {0, 7}"].count), 2U);

    [self makeDogWithAge:8 owner:@"Jim"];
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age  = 5"].count), 2U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age != 5"].count), 1U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age  = 10"].count), 0U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age  = 8"].count), 1U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age IN {5, 8}"].count), 3U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age IN {8, 10}"].count), 1U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age BETWEEN {0, 10}"].count), 3U);
    XCTAssertEqual(([OwnerObject objectsInRealm:realm where:@"dog.age BETWEEN {0, 7}"].count), 2U);
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

    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.boolCol = YES"] count], 1U);
    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.boolCol = NO"] count], 0U);

    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.intCol = 1"] count], 1U);
    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.intCol != 1"] count], 0U);
    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.intCol > 0"] count], 1U);
    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.intCol > 1"] count], 0U);

    NSPredicate *predEq = [NSPredicate predicateWithFormat:@"allTypesCol.floatCol = %f", 1.1];
    XCTAssertEqual([LinkToAllTypesObject objectsInRealm:realm withPredicate:predEq].count, 1U);
    NSPredicate *predLessEq = [NSPredicate predicateWithFormat:@"allTypesCol.floatCol <= %f", 1.1];
    XCTAssertEqual([LinkToAllTypesObject objectsInRealm:realm withPredicate:predLessEq].count, 1U);
    NSPredicate *predLess = [NSPredicate predicateWithFormat:@"allTypesCol.floatCol < %f", 1.1];
    XCTAssertEqual([LinkToAllTypesObject objectsInRealm:realm withPredicate:predLess].count, 0U);

    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.doubleCol = 1.11"] count], 1U);
    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.doubleCol >= 1.11"] count], 1U);
    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.doubleCol > 1.11"] count], 0U);

    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.longCol = 11"] count], 1U);
    XCTAssertEqual([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.longCol != 11"] count], 0U);

    XCTAssertEqual(([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.dateCol = %@", now] count]), 1U);
    XCTAssertEqual(([[realm objects:[LinkToAllTypesObject className] where:@"allTypesCol.dateCol != %@", now] count]), 0U);
}

- (void)testLinkQueryInvalid {
    XCTAssertThrows([LinkToAllTypesObject objectsWhere:@"allTypesCol.binaryCol = 'a'"], @"Binary data not supported");
    XCTAssertThrows([LinkToAllTypesObject objectsWhere:@"allTypesCol.mixedCol = 'a'"], @"Mixed data not supported");
    XCTAssertThrows([LinkToAllTypesObject objectsWhere:@"allTypesCol.invalidCol = 'a'"], @"Invalid column name should throw");

    XCTAssertThrows([LinkToAllTypesObject objectsWhere:@"allTypesCol.longCol = 'a'"], @"Wrong data type should throw");

    XCTAssertThrows([LinkToAllTypesObject objectsWhere:@"intArray.intCol > 5"], @"RLMArray query without ANY modifier should throw");
}


- (void)testLinkQueryMany
{
    RLMRealm *realm = [self realmWithTestPath];

    ArrayPropertyObject *arrPropObj1 = [[ArrayPropertyObject alloc] init];
    arrPropObj1.name = @"Test";
    for(NSUInteger i=0; i<10; i++) {
        StringObject *sobj = [[StringObject alloc] init];
        sobj.stringCol = [NSString stringWithFormat:@"%lu", (unsigned long)i];
        [arrPropObj1.array addObject:sobj];
        IntObject *iobj = [[IntObject alloc] init];
        iobj.intCol = (int)i;
        [arrPropObj1.intArray addObject:iobj];
    }
    [realm beginWriteTransaction];
    [realm addObject:arrPropObj1];
    [realm commitWriteTransaction];

    XCTAssertEqual([[realm objects:[ArrayPropertyObject className] where:@"ANY intArray.intCol > 10"] count], 0U);
    XCTAssertEqual([[realm objects:[ArrayPropertyObject className] where:@"ANY intArray.intCol > 5"] count], 1U);
    XCTAssertEqual([[realm objects:[ArrayPropertyObject className] where:@"ANY array.stringCol = '1'"] count], 1U);

    ArrayPropertyObject *arrPropObj2 = [[ArrayPropertyObject alloc] init];
    arrPropObj2.name = @"Test";
    for(NSUInteger i=0; i<4; i++) {
        StringObject *sobj = [[StringObject alloc] init];
        sobj.stringCol = [NSString stringWithFormat:@"%lu", (unsigned long)i];
        [arrPropObj2.array addObject:sobj];
        IntObject *iobj = [[IntObject alloc] init];
        iobj.intCol = (int)i;
        [arrPropObj2.intArray addObject:iobj];
    }
    [realm beginWriteTransaction];
    [realm addObject:arrPropObj2];
    [realm commitWriteTransaction];
    XCTAssertEqual([[realm objects:[ArrayPropertyObject className] where:@"ANY intArray.intCol > 10"] count], 0U);
    XCTAssertEqual([[realm objects:[ArrayPropertyObject className] where:@"ANY intArray.intCol > 5"] count], 1U);
    XCTAssertEqual([[realm objects:[ArrayPropertyObject className] where:@"ANY intArray.intCol > 2"] count], 2U);
}

- (void)testMultiLevelLinkQuery
{
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    CircleObject *circle = nil;
    for (int i = 0; i < 5; ++i) {
        circle = [CircleObject createInRealm:realm withObject:@{@"data": [NSString stringWithFormat:@"%d", i],
                                                                @"next": circle ?: NSNull.null}];
    }
    [realm commitWriteTransaction];

    XCTAssertEqualObjects(circle, [CircleObject objectsInRealm:realm where:@"data = '4'"].firstObject);
    XCTAssertEqualObjects(circle, [CircleObject objectsInRealm:realm where:@"next.data = '3'"].firstObject);
    XCTAssertEqualObjects(circle, [CircleObject objectsInRealm:realm where:@"next.next.data = '2'"].firstObject);
    XCTAssertEqualObjects(circle, [CircleObject objectsInRealm:realm where:@"next.next.next.data = '1'"].firstObject);
    XCTAssertEqualObjects(circle, [CircleObject objectsInRealm:realm where:@"next.next.next.next.data = '0'"].firstObject);
    XCTAssertEqualObjects(circle.next, [CircleObject objectsInRealm:realm where:@"next.next.next.data = '0'"].firstObject);
    XCTAssertEqualObjects(circle.next.next, [CircleObject objectsInRealm:realm where:@"next.next.data = '0'"].firstObject);

    XCTAssertNoThrow(([CircleObject objectsInRealm:realm where:@"next = %@", circle]));
    XCTAssertThrows(([CircleObject objectsInRealm:realm where:@"next.next = %@", circle]));
    XCTAssertEqualObjects(circle.next.next.next.next, [CircleObject objectsInRealm:realm where:@"next = nil"].firstObject);
}

- (void)testArrayMultiLevelLinkQuery
{
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    CircleObject *circle = nil;
    for (int i = 0; i < 5; ++i) {
        circle = [CircleObject createInRealm:realm withObject:@{@"data": [NSString stringWithFormat:@"%d", i],
                                                                @"next": circle ?: NSNull.null}];
    }
    [CircleArrayObject createInRealm:realm withObject:@[[CircleObject allObjectsInRealm:realm]]];
    [realm commitWriteTransaction];

    XCTAssertEqual(1U, [CircleArrayObject objectsInRealm:realm where:@"ANY circles.data = '4'"].count);
    XCTAssertEqual(0U, [CircleArrayObject objectsInRealm:realm where:@"ANY circles.next.data = '4'"].count);
    XCTAssertEqual(1U, [CircleArrayObject objectsInRealm:realm where:@"ANY circles.next.data = '3'"].count);
    XCTAssertEqual(1U, [CircleArrayObject objectsInRealm:realm where:@"ANY circles.data = '3'"].count);

    XCTAssertEqual(0U, [CircleArrayObject objectsInRealm:realm where:@"ANY circles.next.next.data = '3'"].count);
    XCTAssertEqual(1U, [CircleArrayObject objectsInRealm:realm where:@"ANY circles.next.next.data = '2'"].count);
    XCTAssertEqual(1U, [CircleArrayObject objectsInRealm:realm where:@"ANY circles.next.data = '2'"].count);
    XCTAssertEqual(1U, [CircleArrayObject objectsInRealm:realm where:@"ANY circles.data = '2'"].count);

    XCTAssertThrows([CircleArrayObject objectsInRealm:realm where:@"ANY data = '2'"]);
    XCTAssertThrows([CircleArrayObject objectsInRealm:realm where:@"ANY circles.next = '2'"]);
    XCTAssertThrows([CircleArrayObject objectsInRealm:realm where:@"ANY data.circles = '2'"]);
    XCTAssertThrows([CircleArrayObject objectsInRealm:realm where:@"circles.data = '2'"]);
}

- (void)testQueryWithObjects
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    NSDate *date1 = [NSDate date];
    NSDate *date2 = [date1 dateByAddingTimeInterval:1];
    NSDate *date3 = [date2 dateByAddingTimeInterval:1];

    StringObject *stringObj0 = [[StringObject alloc] initWithObject:@[@"string0"]];
    StringObject *stringObj1 = [[StringObject alloc] initWithObject:@[@"string1"]];
    StringObject *stringObj2 = [[StringObject alloc] initWithObject:@[@"string2"]];

    [realm beginWriteTransaction];

    AllTypesObject *obj0 = [AllTypesObject createInRealm:realm withObject:@[@YES, @1, @1.0f, @1.0, @"a", [@"a" dataUsingEncoding:NSUTF8StringEncoding], date1, @YES, @1LL, @1, stringObj0]];
    AllTypesObject *obj1 = [AllTypesObject createInRealm:realm withObject:@[@YES, @2, @2.0f, @2.0, @"b", [@"b" dataUsingEncoding:NSUTF8StringEncoding], date2, @YES, @2LL, @"mixed", stringObj1]];
    AllTypesObject *obj2 = [AllTypesObject createInRealm:realm withObject:@[@NO, @3, @3.0f, @3.0, @"c", [@"c" dataUsingEncoding:NSUTF8StringEncoding], date3, @YES, @3LL, @"mixed", stringObj0]];
    AllTypesObject *obj3 = [AllTypesObject createInRealm:realm withObject:@[@NO, @3, @3.0f, @3.0, @"c", [@"c" dataUsingEncoding:NSUTF8StringEncoding], date3, @YES, @3LL, @"mixed", stringObj2]];
    AllTypesObject *obj4 = [AllTypesObject createInRealm:realm withObject:@[@NO, @3, @3.0f, @3.0, @"c", [@"c" dataUsingEncoding:NSUTF8StringEncoding], date3, @YES, @34359738368LL, @"mixed", NSNull.null]];

    [ArrayOfAllTypesObject createInDefaultRealmWithObject:@[@[obj0, obj1]]];
    [ArrayOfAllTypesObject createInDefaultRealmWithObject:@[@[obj1]]];
    [ArrayOfAllTypesObject createInDefaultRealmWithObject:@[@[obj0, obj2, obj3]]];
    [ArrayOfAllTypesObject createInDefaultRealmWithObject:@[@[obj4]]];

    [realm commitWriteTransaction];

    // simple queries
    NSPredicate *pred1 = [NSPredicate predicateWithFormat:@"objectCol = %@", stringObj0];
    XCTAssertEqual([AllTypesObject objectsWithPredicate:pred1].count, 2U, @"Count should be 2");
    NSPredicate *pred2 = [NSPredicate predicateWithFormat:@"objectCol = %@", stringObj1];
    XCTAssertEqual([AllTypesObject objectsWithPredicate:pred2].count, 1U, @"Count should be 1");
    NSPredicate *predNil = [NSPredicate predicateWithFormat:@"objectCol = nil"];
    XCTAssertEqual([AllTypesObject objectsWithPredicate:predNil].count, 1U, @"Count should be 1");

    NSPredicate *longPred = [NSPredicate predicateWithFormat:@"longCol = %lli", 34359738368];
    XCTAssertEqual([AllTypesObject objectsWithPredicate:longPred].count, 1U, @"Count should be 1");

    NSPredicate *longBetweenPred = [NSPredicate predicateWithFormat:@"longCol BETWEEN %@", @[@34359738367LL, @34359738369LL]];
    XCTAssertEqual([AllTypesObject objectsWithPredicate:longBetweenPred].count, 1U, @"Count should be 1");

    // invalid object queries
    NSPredicate *pred3 = [NSPredicate predicateWithFormat:@"objectCol != %@", stringObj1];
    XCTAssertThrows([AllTypesObject objectsWithPredicate:pred3], @"Operator other than = should throw");

    // check for ANY object in array
    NSPredicate *pred9 = [NSPredicate predicateWithFormat:@"ANY array = %@", obj0];
    XCTAssertEqual([ArrayOfAllTypesObject objectsWithPredicate:pred9].count, 2U, @"Count should be 2");
    NSPredicate *pred10 = [NSPredicate predicateWithFormat:@"array = %@", obj3];
    XCTAssertThrows([ArrayOfAllTypesObject objectsWithPredicate:pred10].count, @"Array query without ANY should throw");
}

- (void)testCompoundOrQuery {
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withObject:@[@"Tim", @29]];
    [PersonObject createInRealm:realm withObject:@[@"Ari", @33]];
    [realm commitWriteTransaction];

    XCTAssertEqual(2U, [[PersonObject objectsWhere:@"name == 'Ari' or age < 30"] count]);
    XCTAssertEqual(1U, [[PersonObject objectsWhere:@"name == 'Ari' or age > 40"] count]);
}

- (void)testCompoundAndQuery {
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withObject:@[@"Tim", @29]];
    [PersonObject createInRealm:realm withObject:@[@"Ari", @33]];
    [realm commitWriteTransaction];

    XCTAssertEqual(1U, [[PersonObject objectsWhere:@"name == 'Ari' and age > 30"] count]);
    XCTAssertEqual(0U, [[PersonObject objectsWhere:@"name == 'Ari' and age > 40"] count]);
}

- (void)testINPredicate {
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [PersonObject createInRealm:realm withObject:@[@"Tim", @29]];
    [PersonObject createInRealm:realm withObject:@[@"Ari", @33]];
    [realm commitWriteTransaction];

    XCTAssertEqual(0U, [[PersonObject objectsWhere:@"age IN {0, 1, 2}"] count]);
    XCTAssertEqual(1U, [[PersonObject objectsWhere:@"age IN {29}"] count]);
    XCTAssertEqual(2U, [[PersonObject objectsWhere:@"age IN {29, 33}"] count]);
    XCTAssertEqual(2U, [[PersonObject objectsWhere:@"age IN {29, 33, 45}"] count]);

    XCTAssertEqual(0U, [[PersonObject objectsWhere:@"name IN {''}"] count]);
    XCTAssertEqual(1U, [[PersonObject objectsWhere:@"name IN {'Tim'}"] count]);
    XCTAssertEqual(1U, [[PersonObject objectsWhere:@"name IN {'a', 'Tim'}"] count]);

    XCTAssertEqual(0U, ([[PersonObject objectsWhere:@"age IN %@", @[@0, @1, @2]] count]));
    XCTAssertEqual(1U, ([[PersonObject objectsWhere:@"age IN %@", @[@29]] count]));
    XCTAssertEqual(2U, ([[PersonObject objectsWhere:@"age IN %@", @[@29, @33]] count]));
    XCTAssertEqual(2U, ([[PersonObject objectsWhere:@"age IN %@", @[@29, @33, @45]] count]));

    XCTAssertEqual(0U, ([[PersonObject objectsWhere:@"name IN %@", @[@""]] count]));
    XCTAssertEqual(1U, ([[PersonObject objectsWhere:@"name IN %@", @[@"Tim"]] count]));
    XCTAssertEqual(1U, ([[PersonObject objectsWhere:@"name IN %@", @[@"Tim", @"a"]] count]));
}

@end
