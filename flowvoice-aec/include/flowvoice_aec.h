#ifndef FLOWVOICE_AEC_H
#define FLOWVOICE_AEC_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct FlowvoiceAec FlowvoiceAec;

FlowvoiceAec *flowvoice_aec_create(void);
void flowvoice_aec_destroy(FlowvoiceAec *handle);
void flowvoice_aec_reset(FlowvoiceAec *handle);
size_t flowvoice_aec_process(
    FlowvoiceAec *handle,
    const int16_t *microphone,
    const int16_t *speaker,
    int16_t *output,
    size_t sample_count
);

#ifdef __cplusplus
}
#endif

#endif
