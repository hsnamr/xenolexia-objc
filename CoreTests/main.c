/*
 * Xenolexia Core Tests (pure C)
 * Tests xenolexia-shared-c SM-2. Link: -L../../xenolexia-shared-c -lxenolexia_sm2
 */
#include "sm2.h"
#include <stdio.h>
#include <stdlib.h>

static int test_sm2_step(void) {
    xenolexia_sm2_state_t state = {
        .ease_factor = 2.5,
        .interval = 0,
        .review_count = 0,
        .status = XENOLEXIA_SM2_NEW
    };
    xenolexia_sm2_step(4, &state);
    if (state.review_count != 1 || state.interval != 1 || state.status != XENOLEXIA_SM2_LEARNING) {
        fprintf(stderr, "SM-2 step 1 failed: count=%d interval=%d status=%d\n",
                state.review_count, state.interval, (int)state.status);
        return 1;
    }
    xenolexia_sm2_step(4, &state);
    if (state.interval != 6 || state.status != XENOLEXIA_SM2_REVIEW) {
        fprintf(stderr, "SM-2 step 2 failed: interval=%d status=%d\n", state.interval, (int)state.status);
        return 1;
    }
    xenolexia_sm2_step(2, &state);
    if (state.interval != 0 || state.status != XENOLEXIA_SM2_LEARNING) {
        fprintf(stderr, "SM-2 fail step failed: interval=%d status=%d\n", state.interval, (int)state.status);
        return 1;
    }
    return 0;
}

int main(int argc, const char * argv[]) {
    (void)argc;
    (void)argv;
    if (test_sm2_step() != 0) {
        fprintf(stderr, "CoreTests FAILED\n");
        return 1;
    }
    fprintf(stdout, "CoreTests PASSED (SM-2 from xenolexia-shared-c)\n");
    return 0;
}
