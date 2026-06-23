#import <Foundation/Foundation.h>

@interface ObjCGreeter : NSObject

- (const char *)messageCString;
- (NSUInteger)itemCount;
- (void)logFoundationObjects;

@end

ObjCGreeter *MakeObjCGreeter(void);

