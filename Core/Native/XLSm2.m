//
//  XLSm2.m
//  Xenolexia
//
//  SM-2 implementation matching xenolexia-shared-c sm2.c and spec 04-algorithms.md.
//

#import "XLSm2.h"

#define INITIAL_EASE_FACTOR 2.5
#define MIN_EASE_FACTOR     1.3
#define NEW_INTERVAL       1
#define GRADUATING_INTERVAL 6

@implementation XLSm2State
@synthesize easeFactor = _easeFactor;
@synthesize interval = _interval;
@synthesize reviewCount = _reviewCount;
@synthesize status = _status;
@end

void XLSm2Step(NSInteger quality, XLSm2State *state) {
    if (!state) return;

    double ef = state.easeFactor;
    NSInteger iv = state.interval;
    NSInteger rc = state.reviewCount;

    rc += 1;
    state.reviewCount = rc;

    if (quality >= 3) {
        if (iv == 0)
            iv = NEW_INTERVAL;
        else if (iv == 1)
            iv = GRADUATING_INTERVAL;
        else
            iv = (NSInteger)((double)iv * ef + 0.5);

        ef = ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
        if (ef < MIN_EASE_FACTOR)
            ef = MIN_EASE_FACTOR;

        if (rc >= 5 && quality >= 4)
            state.status = XLSm2StatusLearned;
        else if (rc >= 2)
            state.status = XLSm2StatusReview;
        else
            state.status = XLSm2StatusLearning;
    } else {
        iv = 0;
        state.status = XLSm2StatusLearning;
    }

    state.easeFactor = ef;
    state.interval = iv;
}
