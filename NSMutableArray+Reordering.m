#import "NSMutableArray+Reordering.h"

@implementation NSMutableArray (Reordering)
- (void)moveObjectsAtIndexes:(NSIndexSet *)srcIndexes toIndexes:(NSIndexSet *)dstIndexes
{
	NSAssert([srcIndexes count] == [dstIndexes count], @"All indexes must appear in the result.");
	NSAssert([srcIndexes lastIndex] < [self count], @"All source indexes must be in range.");
	NSAssert([dstIndexes lastIndex] < [self count], @"All destination indexes must be in range.");

	NSArray *objects = [self objectsAtIndexes:srcIndexes];
	[self removeObjectsAtIndexes:srcIndexes];
	[self insertObjects:objects atIndexes:dstIndexes];
}
@end
