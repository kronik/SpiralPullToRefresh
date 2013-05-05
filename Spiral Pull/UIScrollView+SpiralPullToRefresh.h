//
// UIScrollView+SpiralPullToRefresh.h
// Spiral Pull Demo
//
//  Created by Dmitry Klimkin on 5/5/13.
//  Copyright (c) 2013 Dmitry Klimkin. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    SpiralPullToRefreshStateStopped = 0,
    SpiralPullToRefreshStateTriggered,
    SpiralPullToRefreshStateLoading
} SpiralPullToRefreshState;

typedef enum {
    SpiralPullToRefreshWaitAnimationRandom = 0,
    SpiralPullToRefreshWaitAnimationLinear,
    SpiralPullToRefreshWaitAnimationCircular
} SpiralPullToRefreshWaitAnimation;

@class SpiralPullToRefreshView;

@interface UIScrollView (SpiralPullToRefresh)

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler;
- (void)triggerPullToRefresh;

@property (nonatomic, strong, readonly) SpiralPullToRefreshView *pullToRefreshController;
@property (nonatomic, assign) BOOL showsPullToRefresh;

@end

@interface SpiralPullToRefreshView : UIView {
    UIView *bottomLeftView;
    UIView *bottomRightView;
    UIView *bottomCenterView;
    
    UIView *middleLeftView;
    UIView *middleRightView;
    UIView *middleCenterView;
    
    UIView *topLeftView;
    UIView *topRightView;
    UIView *topCenterView;
    
    BOOL isRefreshing;
    NSTimer *animationTimer;
    float lastOffset;
    int animationStep;
}

@property (nonatomic, readonly) SpiralPullToRefreshState currentState;
@property (nonatomic, assign) SpiralPullToRefreshWaitAnimation waitingAnimation;

- (void)startAnimating;
- (void)didFinishRefresh;

@end