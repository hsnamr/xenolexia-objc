//
//  main.m
//  Xenolexia Core Tests
//
//  Tests native ObjC SM-2 (XLSm2). No xenolexia-shared-c required.
//

#import <Foundation/Foundation.h>
#import "../Native/XLSm2.h"
#import <stdio.h>
#import <stdlib.h>

static int test_sm2_step(void) {
    XLSm2State *state = [[[XLSm2State alloc] init] autorelease];
    state.easeFactor = 2.5;
    state.interval = 0;
    state.reviewCount = 0;
    state.status = XLSm2StatusNew;

    XLSm2Step(4, state);
    if (state.reviewCount != 1 || state.interval != 1 || state.status != XLSm2StatusLearning) {
        fprintf(stderr, "SM-2 step 1 failed: count=%ld interval=%ld status=%ld\n",
                (long)state.reviewCount, (long)state.interval, (long)state.status);
        return 1;
    }
    XLSm2Step(4, state);
    if (state.interval != 6 || state.status != XLSm2StatusReview) {
        fprintf(stderr, "SM-2 step 2 failed: interval=%ld status=%ld\n", (long)state.interval, (long)state.status);
        return 1;
    }
    XLSm2Step(2, state);
    if (state.interval != 0 || state.status != XLSm2StatusLearning) {
        fprintf(stderr, "SM-2 fail step failed: interval=%ld status=%ld\n", (long)state.interval, (long)state.status);
        return 1;
    }
    return 0;
}

int main(int argc, const char * argv[]) {
    (void)argc;
    (void)argv;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if (test_sm2_step() != 0) {
        fprintf(stderr, "CoreTests FAILED\n");
        [pool drain];
        return 1;
    }
    fprintf(stdout, "CoreTests PASSED (XLSm2 native ObjC)\n");
    [pool drain];
    return 0;
}
