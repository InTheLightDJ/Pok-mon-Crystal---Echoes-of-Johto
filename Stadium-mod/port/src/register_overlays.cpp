// Tells librecomp where every recompiled function lives (main code + the 77 fragments).
#include "recomp_overlays.inl"
#include "librecomp/overlays.hpp"
#include "stadium.h"

namespace stadium {
    const SectionTableEntry* section_entries(size_t& count) {
        count = ARRLEN(section_table);
        return section_table;
    }
}

void stadium::register_overlays() {
    recomp::overlays::overlay_section_table_data_t sections{
        .code_sections = section_table,
        .num_code_sections = ARRLEN(section_table),
        .total_num_sections = num_sections,
    };
    recomp::overlays::overlays_by_index_t overlays{
        .table = overlay_sections_by_index,
        .len = ARRLEN(overlay_sections_by_index),
    };
    recomp::overlays::register_overlays(sections, overlays);
}
