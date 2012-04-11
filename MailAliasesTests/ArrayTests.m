#import <SenTestingKit/SenTestingKit.h>
#import "NSMutableArray+Reordering.h"

@interface ArrayTests : SenTestCase {
	NSArray *abc;
}
@end

@implementation ArrayTests

- (void)setUp
{
	abc = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
	STAssertNotNil(abc, @"(sanity)");
}

- (void)testInvalidArgs
{
	NSMutableArray *objs = [abc mutableCopy];
	STAssertThrows([objs moveObjectsAtIndexes:[NSIndexSet indexSet] toIndexes:[NSIndexSet indexSetWithIndex:0]], @"More destination indexes than source indexes.");
	STAssertThrows([objs moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:0] toIndexes:[NSIndexSet indexSet]], @"Fewer destination indexes than source indexes.");

	STAssertThrows([objs moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:50] toIndexes:[NSIndexSet indexSetWithIndex:0]], @"Out of range index");

}

- (void)testSingleMovement
{
	NSMutableArray *objs;
	NSArray *expected;

	objs = [abc mutableCopy];
	[objs moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:2] toIndexes:[NSIndexSet indexSetWithIndex:0]];
	expected = [NSArray arrayWithObjects:@"c", @"a", @"b", nil]; 
	STAssertEqualObjects(objs, expected, @"2 -> 0");

	objs = [abc mutableCopy];
	[objs moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:0] toIndexes:[NSIndexSet indexSetWithIndex:2]];
	expected = [NSArray arrayWithObjects:@"b", @"c", @"a", nil];
	STAssertEqualObjects(objs, expected, @"0 -> 2");

	objs = [abc mutableCopy];
	[objs moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:1] toIndexes:[NSIndexSet indexSetWithIndex:1]];
	expected = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
	STAssertEqualObjects(objs, expected, @"1 -> 1");
}

- (void)testMultipleMovement
{
	NSMutableArray *objs;
	NSArray *expected;

	objs = [abc mutableCopy];
	
	[objs moveObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,2)] toIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1,2)]];
	expected = [NSArray arrayWithObjects:@"c", @"a", @"b", nil]; 
	STAssertEqualObjects(objs, expected, @"0,1 -> 1,2");
	
	objs = [abc mutableCopy];
	[objs moveObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1,2)] toIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,2)]];
	expected = [NSArray arrayWithObjects:@"b", @"c", @"a", nil];
	STAssertEqualObjects(objs, expected, @"1,2 -> 0,1");
	
	objs = [abc mutableCopy];
	[objs moveObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,2)] toIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,2)]];
	expected = [NSArray arrayWithObjects:@"a", @"b", @"c", nil];
	STAssertEqualObjects(objs, expected, @"0,1 -> 0,1");
}

- (void)testNoncontiguousMovement
{
	NSMutableArray *objs;
	NSArray *expected;

	NSMutableIndexSet *firstAndThird = [NSMutableIndexSet indexSet];
	[firstAndThird addIndex:0];
	[firstAndThird addIndex:2];

	objs = [abc mutableCopy];
	[objs moveObjectsAtIndexes:firstAndThird toIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,2)]];
	expected = [NSArray arrayWithObjects:@"a", @"c", @"b", nil];
	STAssertEqualObjects(objs, expected, @"0,2 -> 0,1");
	
	objs = [abc mutableCopy];
	[objs moveObjectsAtIndexes:firstAndThird toIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1,2)]];
	expected = [NSArray arrayWithObjects:@"b", @"a", @"c", nil];
	STAssertEqualObjects(objs, expected, @"0,2 -> 1,2");

	objs = [abc mutableCopy];
	[objs moveObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,2)] toIndexes:firstAndThird];
	expected = [NSArray arrayWithObjects:@"a", @"c", @"b", nil];
	STAssertEqualObjects(objs, expected, @"0,1 -> 0,2");
	
	objs = [abc mutableCopy];
	[objs moveObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1,2)] toIndexes:firstAndThird];
	expected = [NSArray arrayWithObjects:@"b", @"a", @"c", nil];
	STAssertEqualObjects(objs, expected, @"1,2 -> 0,2");
}

@end
