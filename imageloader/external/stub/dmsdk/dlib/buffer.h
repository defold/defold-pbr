#ifndef dm_buffer_h
#define dm_buffer_h

namespace dmBuffer {
    typedef enum {
        RESULT_OK,
        RESULT_GUARD_INVALID,
        RESULT_ALLOCATION_ERROR,
        RESULT_BUFFER_INVALID,
        RESULT_BUFFER_SIZE_ERROR,
        RESULT_STREAM_SIZE_ERROR,
        RESULT_STREAM_MISSING,
        RESULT_STREAM_TYPE_MISMATCH,
        RESULT_STREAM_COUNT_MISMATCH
    } Result;
    typedef enum {
        VALUE_TYPE_UINT8,
        VALUE_TYPE_UINT16,
        VALUE_TYPE_UINT32,
        VALUE_TYPE_UINT64,
        VALUE_TYPE_INT8,
        VALUE_TYPE_INT16,
        VALUE_TYPE_INT32,
        VALUE_TYPE_INT64,
        VALUE_TYPE_FLOAT32,
        MAX_VALUE_TYPE_COUNT
    } ValueType;
    typedef struct {
        dmhash_t m_Name;
        ValueType m_Type;
        uint8_t m_Count;
        uint32_t m_Flags;
        uint32_t m_Reserved;
    } StreamDeclaration;
    typedef unsigned int HBuffer;
    Result Create(uint32_t count, const StreamDeclaration *streams_decl, uint8_t streams_decl_count, HBuffer *out_buffer);
    void Destroy(dmBuffer::HBuffer buffer);
    Result GetBytes(HBuffer buffer, void **out_bytes, uint32_t *out_size);
    Result GetCount(HBuffer buffer, uint32_t *count);
    const char *GetResultString(Result result);
    uint32_t GetSizeForValueType(ValueType type);
    Result GetStream(HBuffer buffer, dmhash_t stream_name, void **stream, uint32_t *count, uint32_t *components, uint32_t *stride);
    Result GetStreamType(HBuffer buffer, dmhash_t stream_name, ValueType *type, uint32_t *components);
    const char *GetValueTypeString(ValueType result);
    bool IsBufferValid(HBuffer buffer);
    Result ValidateBuffer(HBuffer buffer);
};

#endif