#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSApplication.h>
#include "GSCodingFlags.h"

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
  mask.flags.state = YES;
  mask.flags.highlighted = YES;
  mask.flags.disabled = NO;
  mask.flags.editable = YES;

#if GS_WORDS_BIGENDIAN == 1
  pass(mask.value == 0b10000011000000000000000000000000, "mask.flags translates to mask.value");
#else
  pass(mask.value == 0b00000000000000000000000000001101, "mask.flags translates to mask.value");
#endif
// now make sure values translate to flags
#if GS_WORDS_BIGENDIAN == 1
  mask.value = 0b10000011000000000000000000000000;
#else
  mask.value = 0b00000000000000000000000000001101;
#endif

pass(mask.flags.state == YES, "state is correctly set");
pass(mask.flags.highlighted == YES, "highlighted is correctly set");
pass(mask.flags.disabled == NO, "disabled is correctly set");
pass(mask.flags.editable == YES, "editable is correctly set");
 
END_SET("GSCodingFlags GNUstep CellFlags Union")

DESTROY(arp);
return 0;
}