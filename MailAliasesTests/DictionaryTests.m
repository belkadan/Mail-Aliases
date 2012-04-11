#import <SenTestingKit/SenTestingKit.h>
#import "NSDictionary+Replacement.h"

@interface DictionaryTests : SenTestCase {
	NSDictionary *dict;
}
@end

@implementation DictionaryTests

- (void)setUp
{
	dict = [NSDictionary dictionaryWithObjectsAndKeys:@"A", @"a", @"B", @"b", nil];
	STAssertNotNil(dict, @"(sanity)");
}

- (void)testNil
{
	NSDictionary *expected, *actual;

	actual = [dict dictionaryBySettingObject:nil forKey:@"b"];
	expected = [NSDictionary dictionaryWithObject:@"A" forKey:@"a"];
	STAssertEqualObjects(actual, expected, @"b -> (null)");
	
	actual = [dict dictionaryBySettingObject:nil forKey:@"c"];
	expected = dict;
	STAssertEqualObjects(actual, expected, @"c -> (null)");
}

- (void)testValue
{
	NSDictionary *expected, *actual;
	
	actual = [dict dictionaryBySettingObject:@"C" forKey:@"b"];
	expected = [NSDictionary dictionaryWithObjectsAndKeys:@"A", @"a", @"C", @"b", nil];
	STAssertEqualObjects(actual, expected, @"b -> C");
	
	actual = [dict dictionaryBySettingObject:@"C" forKey:@"c"];
	expected = [NSDictionary dictionaryWithObjectsAndKeys:@"A", @"a", @"B", @"b", @"C", @"c", nil];
	STAssertEqualObjects(actual, expected, @"c -> C");
}

@end