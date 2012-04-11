#import "NSDictionary+Replacement.h"

#ifndef __has_feature         // Optional of course.
#define __has_feature(x) 0  // Compatibility with non-clang compilers.
#endif
#if __has_feature(objc_arc)
#define AUTORELEASE(x) (x)
#else
#define AUTORELEASE(x) [(x) autorelease]
#endif

@implementation NSDictionary (Replacement)
- (NSDictionary *)dictionaryBySettingObject:(id)value forKey:(NSString *)key
{
	NSMutableDictionary *result = [self mutableCopy];
	if (value == nil)
	{
		[result removeObjectForKey:key];
	}
	else
	{
		[result setObject:value forKey:key];
	}
	return AUTORELEASE(result);
}
@end
