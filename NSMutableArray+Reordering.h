#import <Foundation/Foundation.h>

@interface NSMutableArray (Reordering)
- (void)moveObjectsAtIndexes:(NSIndexSet *)srcIndexes toIndexes:(NSIndexSet *)dstIndexes;
@end
