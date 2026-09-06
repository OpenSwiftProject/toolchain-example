#import <Foundation/Foundation.h>

@interface ObjCGreeter : NSObject

- (const char * _Nullable)messageCString;
- (NSUInteger)itemCount;
- (void)logFoundationObjects;

@end

ObjCGreeter * _Nullable MakeObjCGreeter(void);

// Exercise class references across the package and GNUstep Foundation library.
const char * _Nonnull ObjCDemoClassName(Class _Nonnull cls);
