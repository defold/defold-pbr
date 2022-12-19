#ifndef dm_hash_h
#define dm_hash_h

#include <stdint.h>

typedef uint64_t dmhash_t;

dmhash_t dmHashBuffer64(const void *buffer, uint32_t buffer_len);
dmhash_t dmHashString64(const char *string);

#endif