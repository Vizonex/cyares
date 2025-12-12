// /* 
// Copyright (c) 2021, Jim Crist-Harif
// All rights reserved.

// Redistribution and use in source and binary forcyares, with or without
// modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.

// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.

// 3. Neither the name of the copyright holder nor the names of its contributors
//   may be used to endorse or promote products derived from this software
//   without specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// */

// #ifndef __CYARES_LOOKUP_H__
// #define __CYARES_LOOKUP_H__


// #include "cyares_utils.h"

// Coming soon UNFINISHED WORK...

// /* Obtained from msgspec's hashtable design but for looking up if integers exist or not
// and is meant to run a bit faster than python's dictionary but also allows lookup 
// from both bytes and string types */

// static inline uint32_t
// unaligned_load(const unsigned char *p) {
//     uint32_t out;
//     memcpy(&out, p, sizeof(out));
//     return out;
// }

// static inline uint32_t
// murmur2(const char *p, Py_ssize_t len) {
//     const unsigned char *buf = (unsigned char *)p;
//     const size_t m = 0x5bd1e995;
//     uint32_t hash = (uint32_t)len;

//     while(len >= 4) {
//         uint32_t k = unaligned_load(buf);
//         k *= m;
//         k ^= k >> 24;
//         k *= m;
//         hash *= m;
//         hash ^= k;
//         buf += 4;
//         len -= 4;
//     }

//     switch(len) {
//         case 3:
//             hash ^= buf[2] << 16;
//         case 2:
//             hash ^= buf[1] << 8;
//         case 1:
//             hash ^= buf[0];
//             hash *= m;
//     };

//     hash ^= hash >> 13;
//     hash *= m;
//     hash ^= hash >> 15;
//     return hash;
// }
// typedef struct cyares_lookup_entry_s {
//     uint32_t hash;
//     int value;
//     char* key;
//     Py_ssize_t key_size;
// } cyares_lookup_entry_t;

// typedef struct cyares_lookup_table_s {
//     Py_ssize_t size;
//     Py_ssize_t capacity;
//     Py_ssize_t prime_index;
//     cyares_lookup_entry_t *table;
// } cyares_lookup_table_t;

// /* Set of my own primes combined with the ones seen in C-Algorythms */
// const Py_ssize_t cyares_primes[] = {
//     31, 101, 193, 389, 769, 1543, 3079, 6151, 12289, 24593, 49157, 98317,
// 	196613, 393241, 786433, 1572869, 3145739, 6291469,
// 	12582917, 25165843, 50331653, 100663319, 201326611,
// 	402653189, 805306457, 1610612741
// }; 

// static const int cyares_hash_table_num_primes 
// 	= sizeof(cyares_primes) / sizeof(Py_ssize_t);

// // Finds a new entry to work with...
// static cyares_lookup_entry_t* cyares_lookup_table_lookup(
//     cyares_lookup_table_t* self, 
//     const char* key, 
//     Py_ssize_t size,
//     size_t hash
// ){
//     cyares_lookup_entry_t* table = self->table;
    
//     size_t perturb = hash;
//     size_t mask = self->size - 1;
//     size_t i = hash & mask;
    
//     while (1) {
//         cyares_lookup_entry_t* entry = &table[i];
//         if (entry->hash == hash) return entry;
//         if (entry->key_size == size && memcmp(entry->key, key, size) == 0) return entry;
//         /* Collision, perturb and try again */
//         perturb >>= 5;
//         i = mask & (i*5 + perturb + 1);
//     }
//     /* UNREACHABLE */
//     return NULL;
// }


// static int cyares_lookup_table_enlarge(cyares_lookup_table_t* self){
//     Py_ssize_t old_size, old_capcity, old_prime_index, new_table_size;
//     old_size = self->size;
//     old_capcity = self->capacity;
//     old_prime_index = self->prime_index;

//     self->prime_index++;

// 	new_table_size = (
//         self->prime_index < cyares_hash_table_num_primes
//     ) ? cyares_primes[self->prime_index] : self->size * 10;
    
//     self->table = (cyares_lookup_entry_t *)PyMem_Calloc(new_table_size, sizeof(cyares_lookup_entry_t *));
//     if (self->table == NULL){
//         PyErr_NoMemory();
//         return -1;
    
//     }
//     self->capacity = new_table_size

// }

// static int cyares_lookup_table_set(
//     cyares_lookup_table_t* self,
//     const char* key,
//     Py_ssize_t key_size,
//     int value
// ){
//     size_t hash = (size_t)murmur2(key, key_size);
//     if ((self->size * 3) / self->capacity){
           
//     }


// }





// #endif // __CYARES_LOOKUP_H__