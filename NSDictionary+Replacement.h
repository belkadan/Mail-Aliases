#import <Foundation/Foundation.h>


@interface NSDictionary (Replacement)
- (NSDictionary *)dictionaryBySettingObject:(id)value forKey:(NSString *)key;
@end
