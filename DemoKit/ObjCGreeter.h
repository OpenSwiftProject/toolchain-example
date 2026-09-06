#import <Foundation/Foundation.h>

@interface ObjCGreeter : NSObject

- (const char * _Nullable)messageCString;
- (NSUInteger)itemCount;
- (void)logFoundationObjects;

// Exercise class messages, property accessors, and multi-argument selectors.
+ (const char * _Nonnull)classMessageCString;
@property(nonatomic) NSUInteger selectorProbeValue;
- (NSUInteger)add:(NSUInteger)lhs to:(NSUInteger)rhs;

@end

ObjCGreeter * _Nullable MakeObjCGreeter(void);

// Exercise class references across the package and GNUstep Foundation library.
const char * _Nonnull ObjCDemoClassName(Class _Nonnull cls);
