`ifndef _DEFINE_ACE
`define _DEFINE_ACE

// ACE Protocol Definitions for ICache
// Based on AMBA 4 ACE (Advanced Coherency Extensions) specification

// ACE Channel Types
typedef enum logic [2:0] {
    ACE_READ_SHARED     = 3'b000,  // ReadShared - read data, may be shared
    ACE_READ_UNIQUE     = 3'b001,  // ReadUnique - read data, get exclusive access
    ACE_READ_NO_SNOOP   = 3'b010,  // ReadNoSnoop - read data, no snooping required
    ACE_READ_ONCE       = 3'b011,  // ReadOnce - read data once, no caching
    ACE_READ_CLEAN      = 3'b100,  // ReadClean - read clean data
    ACE_READ_NOT_SHARED = 3'b101,  // ReadNotSharedDirty - read data, not shared dirty
    ACE_READ_SHARED_OTHER = 3'b110, // ReadSharedOther - read shared data from other cache
    ACE_READ_UNIQUE_OTHER = 3'b111  // ReadUniqueOther - read unique data from other cache
} ace_ar_snoop_t;

typedef enum logic [2:0] {
    ACE_WRITE_UNIQUE    = 3'b000,  // WriteUnique - write data, get exclusive access
    ACE_WRITE_LINE_UNIQUE = 3'b001, // WriteLineUnique - write entire line, get exclusive
    ACE_WRITE_NO_SNOOP  = 3'b010,  // WriteNoSnoop - write data, no snooping required
    ACE_WRITE_UNIQUE_PARTIAL = 3'b011, // WriteUniquePartial - write partial line, get exclusive
    ACE_WRITE_BACK      = 3'b100,  // WriteBack - write back dirty data
    ACE_WRITE_EVICT     = 3'b101,  // WriteEvict - evict clean data
    ACE_WRITE_CLEAN     = 3'b110,  // WriteClean - write clean data
    ACE_WRITE_UNIQUE_PARTIAL_STASH = 3'b111 // WriteUniquePartialStash - write partial with stash
} ace_aw_snoop_t;

// ACE Response Types
typedef enum logic [3:0] {
    ACE_CR_OKAY         = 4'b0000, // Okay - normal response
    ACE_CR_EXOKAY       = 4'b0001, // Exclusive okay - exclusive access granted
    ACE_CR_SLVERR       = 4'b0010, // Slave error
    ACE_CR_DECERR       = 4'b0011, // Decode error
    ACE_CR_SPLIT        = 4'b0100, // Split transaction
    ACE_CR_RETRY        = 4'b0101, // Retry
    ACE_CR_LAST         = 4'b0110, // Last response
    ACE_CR_OTHER        = 4'b0111  // Other response
} ace_cr_resp_t;

// ACE Data Response Types
typedef enum logic [2:0] {
    ACE_CD_OKAY         = 3'b000,  // Okay - normal data response
    ACE_CD_EXOKAY       = 3'b001,  // Exclusive okay - exclusive data
    ACE_CD_SLVERR       = 3'b010,  // Slave error
    ACE_CD_DECERR       = 3'b011,  // Decode error
    ACE_CD_SPLIT        = 3'b100,  // Split transaction
    ACE_CD_RETRY        = 3'b101,  // Retry
    ACE_CD_LAST         = 3'b110,  // Last data
    ACE_CD_OTHER        = 3'b111   // Other response
} ace_cd_resp_t;

// ACE Cache States
typedef enum logic [2:0] {
    ACE_INVALID         = 3'b000,  // Invalid
    ACE_SHARED          = 3'b001,  // Shared
    ACE_EXCLUSIVE       = 3'b010,  // Exclusive
    ACE_MODIFIED        = 3'b011,  // Modified
    ACE_OWNED           = 3'b100,  // Owned
    ACE_SHARED_CLEAN    = 3'b101,  // Shared Clean
    ACE_SHARED_DIRTY    = 3'b110,  // Shared Dirty
    ACE_EXCLUSIVE_CLEAN = 3'b111   // Exclusive Clean
} ace_cache_state_t;

// ACE Domain Types
typedef enum logic [1:0] {
    ACE_DOMAIN_INNER    = 2'b00,   // Inner domain
    ACE_DOMAIN_OUTER    = 2'b01,   // Outer domain
    ACE_DOMAIN_SYSTEM   = 2'b10,   // System domain
    ACE_DOMAIN_RESERVED = 2'b11    // Reserved
} ace_domain_t;

// ACE Barrier Types
typedef enum logic [1:0] {
    ACE_BARRIER_NORMAL  = 2'b00,   // Normal barrier
    ACE_BARRIER_MEMORY  = 2'b01,   // Memory barrier
    ACE_BARRIER_SYNC    = 2'b10,   // Synchronization barrier
    ACE_BARRIER_RESERVED = 2'b11   // Reserved
} ace_barrier_t;

// ACE Interface Parameters
`define ACE_ID_WIDTH    4          // Transaction ID width
`define ACE_ADDR_WIDTH  32         // Address width
`define ACE_DATA_WIDTH  128        // Data width (cache line size)
`define ACE_STRB_WIDTH  16         // Strobe width (data_width/8)
`define ACE_USER_WIDTH  4          // User signal width
`define ACE_SNOOP_WIDTH 3          // Snoop signal width
`define ACE_RESP_WIDTH  4          // Response signal width
`define ACE_CACHE_WIDTH 4          // Cache attribute width
`define ACE_PROT_WIDTH  3          // Protection signal width
`define ACE_QOS_WIDTH   4          // Quality of service width
`define ACE_REGION_WIDTH 4         // Region signal width

// ACE Interface Macros
`define ACE_AR_SNOOP_WIDTH 3
`define ACE_AW_SNOOP_WIDTH 3
`define ACE_CR_RESP_WIDTH  4
`define ACE_CD_RESP_WIDTH  3

// ACE Transaction Types for ICache
`define ACE_ICACHE_READ_SHARED     ACE_READ_SHARED
`define ACE_ICACHE_READ_UNIQUE     ACE_READ_UNIQUE
`define ACE_ICACHE_READ_NO_SNOOP   ACE_READ_NO_SNOOP

// ACE Cache Attributes
`define ACE_CACHE_BUFFERABLE       1'b1
`define ACE_CACHE_MODIFIABLE       1'b1
`define ACE_CACHE_READ_ALLOCATE    1'b1
`define ACE_CACHE_WRITE_ALLOCATE   1'b1

// ACE Protection Attributes
`define ACE_PROT_NORMAL            3'b000
`define ACE_PROT_PRIVILEGED        3'b001
`define ACE_PROT_NONSECURE         3'b010
`define ACE_PROT_INSTRUCTION       3'b100

// ACE Quality of Service
`define ACE_QOS_DEFAULT            4'b0000

// ACE Region (for multi-master systems)
`define ACE_REGION_DEFAULT         4'b0000

`endif
