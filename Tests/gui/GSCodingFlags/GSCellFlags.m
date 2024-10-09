#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSApplication.h>
#include "GSCodingFlags.h"

void print_binary(uint32_t value) {
    for (int i = 31; i >= 0; i--) {
        NSLog(@"%d", (value >> i) & 1);
        if (i % 8 == 0) printf(" ");
    }
    NSLog(@"\n");
}

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  GSCellFlagsUnion mask = { { 0 } };

  START_SET("GSCodingFlags GNUstep CellFlags Union")
  
  NS_DURING
  {
    [NSApplication sharedApplication];
  }
  NS_HANDLER
  {
    if ([[localException name] isEqualToString: NSInternalInconsistencyException ])
       SKIP("It looks like GNUstep backend is not yet installed")
  }
  NS_ENDHANDLER
  // first make sure flags translate to values
  mask.flags.state = 1;
  mask.flags.highlighted = 1;
  mask.flags.disabled = 0;
  mask.flags.editable = 1;

  print_binary(mask.value);

#if GS_WORDS_BIGENDIAN == 1
  pass(mask.value == 0b10000011000000000000000000000000, "mask.flags translates to mask.value");
#else
  pass(mask.value == 0b00000000000000000000000000001101, "mask.flags translates to mask.value");
#endif
// reset mask
mask.value = 0;
mask.flags = (GSCellFlags){0};
// now make sure values translate to flags
#if GS_WORDS_BIGENDIAN == 1
  mask.value = 0b10000011000000000000000000000000;
#else
  mask.value = 0b00000000000000000000000000001101;
#endif

print_binary(mask.value);

pass(mask.flags.state == 1, "state is correctly set");
pass(mask.flags.highlighted == 1, "highlighted is correctly set");
pass(mask.flags.disabled == 0, "disabled is correctly set");
pass(mask.flags.editable == 1, "editable is correctly set");
 
END_SET("GSCodingFlags GNUstep CellFlags Union")

DESTROY(arp);
return 0;
}