#import "ObjCGreeter.h"

@implementation ObjCGreeter {
  NSString *_message;
  NSArray *_items;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _message = @"Hello from GNUstep Objective-C";
    _items = @[ @"NSString", @"NSArray", @"Blocks", @"Swift import" ];
  }
  return self;
}

- (const char *)messageCString {
  return [_message UTF8String];
}

- (NSUInteger)itemCount {
  return [_items count];
}

- (void)logFoundationObjects {
  void (^logger)(NSString *) = ^(NSString *label) {
    NSLog(@"%@: %@ (%lu items)", label, _message, (unsigned long)[_items count]);
  };
  logger(@"ObjCGreeter");
}

@end

ObjCGreeter *MakeObjCGreeter(void) {
  return [[ObjCGreeter alloc] init];
}

