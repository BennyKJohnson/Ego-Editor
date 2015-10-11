//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#include <stdint.h>
#include "dds.h"
#include "DisclosureViewController.h"

static inline float f16toFloat(const uint16_t *pointer) { return *(const __fp16 *)pointer; }