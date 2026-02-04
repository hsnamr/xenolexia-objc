//
//  XLSm2.h
//  Xenolexia
//
//  SM-2 spaced repetition algorithm (ObjC). Matches xenolexia-shared-c sm2.h and spec 04-algorithms.md.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, XLSm2Status) {
    XLSm2StatusNew = 0,
    XLSm2StatusLearning,
    XLSm2StatusReview,
    XLSm2StatusLearned
};

@interface XLSm2State : NSObject {
    double _easeFactor;
    NSInteger _interval;
    NSInteger _reviewCount;
    XLSm2Status _status;
}
@property (nonatomic, assign) double easeFactor;
@property (nonatomic, assign) NSInteger interval;
@property (nonatomic, assign) NSInteger reviewCount;
@property (nonatomic, assign) XLSm2Status status;
@end

/// Perform one SM-2 step. quality 0–5; state is updated in place.
void XLSm2Step(NSInteger quality, XLSm2State *state);

NS_ASSUME_NONNULL_END
