#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSApplication.h>
#include "GSCodingFlags.h"

char* print_binary(uint32_t value) {
    // Allocate memory for 35 characters (32 bits + 3 spaces + 1 null terminator)
    // Each 8 bits has a space after it, and we need a null terminator at the end.
    char* binary_str = (char*)malloc(36);
    if (!binary_str) return NULL;  // Check if memory allocation was successful

    int index = 0;
    for (int i = 31; i >= 0; i--) {
        // Add '0' or '1' depending on the bit value
        binary_str[index++] = ((value >> i) & 1) ? '1' : '0';
        
        // Add a space every 8 bits (after 8, 16, 24, and 32 bits)
        if (i % 8 == 0 && i != 0) {
            binary_str[index++] = ' ';
        }
    }
    binary_str[index] = '\0';  // Null terminate the string

    return binary_str;
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
    mask.flags.selectable = 1;
    mask.flags.scrollable = 1;
    mask.flags.editable = 1;
    mask.flags.continuous = 1;
    mask.flags.useUserKeyEquivalent = 1;
    mask.flags.truncateLastLine = 1;

    char * mask_Value = print_binary(mask.value);

#if GS_WORDS_BIGENDIAN == 1
    pass(mask.value == 0b00000001001000000000110100000001, "mask.flags translates to mask.value");
#else
    pass(mask.value == 0b00000001001000000000110100000001, "mask.flags translates to mask.value");
#endif
    // reset mask
    mask.value = 0;
    mask.flags = (GSCellFlags){0};
    // now make sure values translate to flags
#if GS_WORDS_BIGENDIAN == 1
    mask.value = 0b00000001001000000000110100000001;
#else
    mask.value = 0b00000001001000000000110100000001;
#endif

    char * mask_Value2 = print_binary(mask.value);
    pass(mask.flags.state = 1, "state is correctly set: %s", mask_Value2);
    pass(mask.flags.selectable = 1, "selectable is correctly set: %s", mask_Value2);
    pass(mask.flags.scrollable = 1, "scrollable is correctly set: %s", mask_Value2);
    pass(mask.flags.editable = 1, "editable is correctly set: %s", mask_Value2);
    pass(mask.flags.continuous = 1, "continuous is correctly set: %s", mask_Value2);
    pass(mask.flags.useUserKeyEquivalent = 1, "useUserKeyEquivalent is correctly set: %s", mask_Value2);
    pass(mask.flags.truncateLastLine = 1, "truncateLastLine is correctly set: %s", mask_Value2);
    
    END_SET("GSCodingFlags GNUstep CellFlags Union")

    DESTROY(arp);
    return 0;
}