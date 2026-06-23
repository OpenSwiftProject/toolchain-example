#include <objc/runtime.h>
#include <stdint.h>

extern void *__start_objc_selrefs;
extern void *__stop_objc_selrefs;

__attribute__((constructor))
static void registerDarwinSelectorRefs(void) {
  void **cursor = &__start_objc_selrefs;
  void **end = &__stop_objc_selrefs;

  for (; cursor < end; ++cursor) {
    const char *name = (const char *)(uintptr_t)*cursor;
    if (name != 0) {
      *cursor = sel_registerName(name);
    }
  }
}

