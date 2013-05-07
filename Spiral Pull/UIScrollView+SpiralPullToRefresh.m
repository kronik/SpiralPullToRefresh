//
// UIScrollView+SpiralPullToRefresh.m
// Spiral Pull Demo
//
//  Created by Dmitry Klimkin on 5/5/13.
//  Copyright (c) 2013 Dmitry Klimkin. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "UIScrollView+SpiralPullToRefresh.h"

#define ScreenWidth  self.frame.size.width

#define SpiralPullToRefreshViewHeight 300
#define SpiralPullToRefreshViewTriggerAreaHeight 101
#define SpiralPullToRefreshViewParticleSize 7

@interface SpiralPullToRefreshView ()

@property (nonatomic, copy) void (^pullToRefreshActionHandler)(void);
@property (nonatomic, readwrite) SpiralPullToRefreshState currentState;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalTopInset;
@property (nonatomic, assign) BOOL wasTriggeredByUser;
@property (nonatomic, assign) BOOL showsPullToRefresh;
@property (nonatomic, assign) BOOL isObserving;
@property (nonatomic, strong) NSArray *particles;

- (void)resetScrollViewContentInset;
- (void)setScrollViewContentInsetForLoading;
- (void)setScrollViewContentInset:(UIEdgeInsets)insets;

@end

#pragma mark - UIScrollView (SpiralPullToRefresh)
#import <objc/runtime.h>

static char UIScrollViewPullToRefreshView;

@implementation UIScrollView (SpiralPullToRefresh)

@dynamic pullToRefreshController, showsPullToRefresh;

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler {
    
    if (!self.pullToRefreshController) {
        SpiralPullToRefreshView *view = [[SpiralPullToRefreshView alloc] initWithFrame:CGRectMake(0, -SpiralPullToRefreshViewHeight, self.bounds.size.width, SpiralPullToRefreshViewHeight)];
        view.pullToRefreshActionHandler = actionHandler;
        view.scrollView = self;
        
        [self addSubview:view];
        
        view.originalTopInset = self.contentInset.top;
        self.pullToRefreshController = view;
        self.showsPullToRefresh = YES;
    }
}

- (void)triggerPullToRefresh {
    self.pullToRefreshController.currentState = SpiralPullToRefreshStateTriggered;
    [self.pullToRefreshController startAnimating];
}

- (void)setPullToRefreshController:(SpiralPullToRefreshView *)pullToRefreshView {
    [self willChangeValueForKey:@"SpiralPullToRefreshView"];
    objc_setAssociatedObject(self, &UIScrollViewPullToRefreshView,
                             pullToRefreshView,
                             OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"SpiralPullToRefreshView"];
}

- (SpiralPullToRefreshView *)pullToRefreshController {
    return objc_getAssociatedObject(self, &UIScrollViewPullToRefreshView);
}

- (void)setShowsPullToRefresh:(BOOL)showsPullToRefresh {
    self.pullToRefreshController.hidden = !showsPullToRefresh;
    
    if (!showsPullToRefresh) {
        if (self.pullToRefreshController.isObserving) {
            
            [self removeObserver:self.pullToRefreshController forKeyPath:@"contentOffset"];
            [self removeObserver:self.pullToRefreshController forKeyPath:@"frame"];
            [self.pullToRefreshController resetScrollViewContentInset];
            
            self.pullToRefreshController.isObserving = NO;
        }
    }
    else if (!self.pullToRefreshController.isObserving) {
        [self addObserver:self.pullToRefreshController forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        [self addObserver:self.pullToRefreshController forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
        
        self.pullToRefreshController.isObserving = YES;
    }
}

- (BOOL)showsPullToRefresh {
    return !self.pullToRefreshController.hidden;
}

@end

#pragma mark - SpiralPullToRefresh
@implementation SpiralPullToRefreshView

// public properties
@synthesize pullToRefreshActionHandler;

@synthesize waitingAnimation = _waitingAnimation;
@synthesize currentState = _state;
@synthesize scrollView = _scrollView;
@synthesize showsPullToRefresh = _showsPullToRefresh;
@synthesize particles = _particles;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        // default styling values
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.currentState = SpiralPullToRefreshStateStopped;
        
        self.backgroundColor = [UIColor blackColor];
        self.clipsToBounds = YES;
        
        bottomLeftView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, SpiralPullToRefreshViewParticleSize, SpiralPullToRefreshViewParticleSize)];
        bottomLeftView.backgroundColor = [UIColor lightGrayColor];
        bottomLeftView.center = CGPointMake(10, self.frame.size.height - bottomLeftView.frame.size.height - SpiralPullToRefreshViewParticleSize);
        
        [self addSubview: bottomLeftView];
        
        bottomRightView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, SpiralPullToRefreshViewParticleSize, SpiralPullToRefreshViewParticleSize)];
        bottomRightView.backgroundColor = [UIColor lightGrayColor];
        bottomRightView.center = CGPointMake(ScreenWidth - 10, self.frame.size.height - bottomRightView.frame.size.height - SpiralPullToRefreshViewParticleSize);
        
        [self addSubview: bottomRightView];
        
        bottomCenterView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, SpiralPullToRefreshViewParticleSize, SpiralPullToRefreshViewParticleSize)];
        bottomCenterView.backgroundColor = [UIColor lightGrayColor];
        bottomCenterView.center = CGPointMake((ScreenWidth / 2), self.frame.size.height - bottomCenterView.frame.size.height);
        
        [self addSubview: bottomCenterView];
        
        middleLeftView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, SpiralPullToRefreshViewParticleSize, SpiralPullToRefreshViewParticleSize)];
        middleLeftView.backgroundColor = [UIColor lightGrayColor];
        middleLeftView.center = CGPointMake(ScreenWidth - 10, self.frame.size.height - middleLeftView.frame.size.height - SpiralPullToRefreshViewParticleSize);
        
        [self addSubview: middleLeftView];
        
        middleRightView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, SpiralPullToRefreshViewParticleSize, SpiralPullToRefreshViewParticleSize)];
        middleRightView.backgroundColor = [UIColor lightGrayColor];
        middleRightView.center = CGPointMake(ScreenWidth - 10, self.frame.size.height - middleRightView.frame.size.height - SpiralPullToRefreshViewParticleSize);
        
        [self addSubview: middleRightView];
        
        middleCenterView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, SpiralPullToRefreshViewParticleSize, SpiralPullToRefreshViewParticleSize)];
        middleCenterView.backgroundColor = [UIColor lightGrayColor];
        middleCenterView.center = CGPointMake((ScreenWidth / 2), self.frame.size.height - middleCenterView.frame.size.height);
        
        [self addSubview: middleCenterView];
        
        topLeftView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, SpiralPullToRefreshViewParticleSize, SpiralPullToRefreshViewParticleSize)];
        topLeftView.backgroundColor = [UIColor lightGrayColor];
        topLeftView.center = CGPointMake(ScreenWidth - 10, self.frame.size.height - topLeftView.frame.size.height - SpiralPullToRefreshViewParticleSize);
        
        [self addSubview: topLeftView];
        
        topRightView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, SpiralPullToRefreshViewParticleSize, SpiralPullToRefreshViewParticleSize)];
        topRightView.backgroundColor = [UIColor lightGrayColor];
        topRightView.center = CGPointMake(ScreenWidth - 10, self.frame.size.height - topRightView.frame.size.height - 5);
        
        [self addSubview: topRightView];
        
        topCenterView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, SpiralPullToRefreshViewParticleSize, SpiralPullToRefreshViewParticleSize)];
        topCenterView.backgroundColor = [UIColor lightGrayColor];
        topCenterView.center = CGPointMake((ScreenWidth / 2), self.frame.size.height - topCenterView.frame.size.height);
        
        [self addSubview: topCenterView];
        
        _particles = @[bottomLeftView, bottomCenterView, bottomRightView,
                       middleLeftView, middleCenterView, middleRightView,
                       topLeftView, topCenterView, topRightView];
    }

    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview { 
    if (self.superview && newSuperview == nil) {
        //use self.superview, not self.scrollView. Why self.scrollView == nil here?
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        if (scrollView.showsPullToRefresh) {
            if (self.isObserving) {
                //If enter this branch, it is the moment just before "SpiralPullToRefreshView's dealloc", so remove observer here
                [scrollView removeObserver:self forKeyPath:@"contentOffset"];
                [scrollView removeObserver:self forKeyPath:@"frame"];
                
                self.isObserving = NO;
            }
        }
    }
}

#pragma mark - Scroll View

- (void)resetScrollViewContentInset {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.top = self.originalTopInset;
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInsetForLoading {
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.top = SpiralPullToRefreshViewTriggerAreaHeight;
        
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset {
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.scrollView.contentInset = contentInset;
                         self.scrollView.contentOffset = CGPointMake(0, 0);
                     }
                     completion:nil];
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        
        CGPoint oldOffset = [[change objectForKey:NSKeyValueChangeOldKey] CGPointValue];
        
        [self contentOffsetChanged: oldOffset.y];
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    } else {
        if ([keyPath isEqualToString:@"frame"]) {
            [self layoutSubviews];
        }
    }
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    if (self.currentState != SpiralPullToRefreshStateLoading) {
        
        CGFloat scrollOffsetThreshold = self.frame.origin.y-self.originalTopInset;

        if (!self.scrollView.isDragging && self.currentState == SpiralPullToRefreshStateTriggered) {
            self.currentState = SpiralPullToRefreshStateLoading;
        }
        else if (((contentOffset.y < scrollOffsetThreshold) || (contentOffset.y < -SpiralPullToRefreshViewTriggerAreaHeight)) && self.scrollView.isDragging && self.currentState == SpiralPullToRefreshStateStopped) {
            self.currentState = SpiralPullToRefreshStateTriggered;
        }
        else if (contentOffset.y >= scrollOffsetThreshold && self.currentState != SpiralPullToRefreshStateStopped) {
            self.currentState = SpiralPullToRefreshStateStopped;
        }
    }
}

- (void)triggerRefresh {
    [self.scrollView triggerPullToRefresh];    
}

- (void)setWaitingAnimation:(SpiralPullToRefreshWaitAnimation)waitingAnimation {
    _waitingAnimation = waitingAnimation;
    
    switch (waitingAnimation) {
        case SpiralPullToRefreshWaitAnimationCircular:
        case SpiralPullToRefreshWaitAnimationLinear: {
            _particles = @[bottomRightView, topCenterView, topRightView,
                           middleLeftView, middleCenterView, middleRightView,
                           bottomLeftView, bottomCenterView, topLeftView];
        }
            break;
                        
        default:
            break;
    }
}

- (void)doAnimationStepForRandomWaitingAnimation {
    int idx = arc4random() % self.particles.count;
    
    for (int i=0; i<self.particles.count; i++) {
        UIView *particleView = self.particles [i];
        
        particleView.backgroundColor = (i == idx) ? [UIColor whiteColor] : [UIColor darkGrayColor];
    }
}

- (void)doAnimationStepForLinearWaitingAnimation {        
    int startIdx = 0;
    int prevIdx = 0;
    
    for (int i=0; i<self.particles.count; i++) {
        UIView *particleView = self.particles [i];
        
        if (particleView.backgroundColor == [UIColor whiteColor]) {
            startIdx = i;
            break;;
        }
    }
    
    prevIdx = startIdx;
    startIdx = (startIdx + 1) % self.particles.count;
    
    for (int i=0; i<self.particles.count; i++) {
        UIView *particleView = self.particles [i];
        
        if (i == prevIdx) {
            particleView.backgroundColor = [UIColor lightGrayColor];
        } else if (i == startIdx) {
            particleView.backgroundColor = [UIColor whiteColor];
        } else {
            particleView.backgroundColor = [UIColor darkGrayColor];
        }
    }
}

- (void)doAnimationStepForCircularWaitingAnimation {
    int path[] = {0, 1, 2, 5, 8, 7, 6, 3};
    
    int startIdx = 0;
    int prevIdx = 0;
    
    animationStep++;

    prevIdx = path[animationStep % (self.particles.count - 1)];
    startIdx = path[(animationStep + 1) % (self.particles.count - 1)];
        
    if (prevIdx == startIdx) {
        startIdx = prevIdx;
    }
    
    for (int i=0; i<self.particles.count; i++) {
        UIView *particleView = self.particles [i];
        
        if (i == prevIdx) {
            particleView.backgroundColor = [UIColor lightGrayColor];
        } else if (i == startIdx) {
            particleView.backgroundColor = [UIColor whiteColor];
        } else {
            particleView.backgroundColor = [UIColor darkGrayColor];
        }
    }
}

- (void)onAnimationTimer {
    
    if (isRefreshing) {
        
        switch (self.waitingAnimation) {
            case SpiralPullToRefreshWaitAnimationRandom: {
                [self doAnimationStepForRandomWaitingAnimation];
            }
                break;
             
            case SpiralPullToRefreshWaitAnimationLinear: {
                [self doAnimationStepForLinearWaitingAnimation];
            }
                break;
                
            case SpiralPullToRefreshWaitAnimationCircular: {
                [self doAnimationStepForCircularWaitingAnimation];
            }
                break;
                
            default:
                break;
        }
        
    } else {
        if (lastOffset < 30) {
            [animationTimer invalidate];
            animationTimer = nil;
            
            self.currentState = SpiralPullToRefreshStateStopped;
            
            if (!self.wasTriggeredByUser) {
                [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, 0) animated:YES];
            }
            
            return;
        }
        
        lastOffset -= 2;
        
        [self contentOffsetChanged:-lastOffset];
    }
}

- (void)startAnimating {
    
    for (int i=0; i<self.particles.count; i++) {
        UIView *particleView = self.particles [i];
        
        particleView.backgroundColor = [UIColor whiteColor];
    }
    
    if (self.scrollView.contentOffset.y == 0) {
        [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -SpiralPullToRefreshViewTriggerAreaHeight) animated:YES];
        self.wasTriggeredByUser = NO;
    }
    else
        self.wasTriggeredByUser = YES;
    
    self.currentState = SpiralPullToRefreshStateLoading;
    
    [animationTimer invalidate];
    animationTimer = nil;
    
    isRefreshing = YES;
    animationStep = 0;
    animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(onAnimationTimer) userInfo:nil repeats:YES];
}

- (void)didFinishRefresh {
    
    if (isRefreshing == NO) {
        return;
    }

    isRefreshing = NO;
    
    NSArray *particles = @[bottomLeftView, bottomCenterView, bottomRightView,
                           middleLeftView, middleCenterView, middleRightView,
                           topLeftView, topCenterView, topRightView];
    
    for (int i=0; i<particles.count; i++) {
        UIView *particleView = particles [i];
        
        particleView.backgroundColor = [UIColor lightGrayColor];
    }
    
    [self setNeedsDisplay];
    
    [animationTimer invalidate];
    animationTimer = nil;
    
    animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(onAnimationTimer) userInfo:nil repeats:YES];
}

- (void)setCurrentState:(SpiralPullToRefreshState)newState {
    
    if (_state == newState)
        return;
    
    SpiralPullToRefreshState previousState = _state;
    _state = newState;
    
    [self setNeedsLayout];
    
    switch (newState) {
        case SpiralPullToRefreshStateStopped:
            [self resetScrollViewContentInset];
            break;
            
        case SpiralPullToRefreshStateTriggered:
            [self startAnimating];
            break;
            
        case SpiralPullToRefreshStateLoading:
            [self setScrollViewContentInsetForLoading];
            
            if (previousState == SpiralPullToRefreshStateTriggered && pullToRefreshActionHandler)
                pullToRefreshActionHandler();
            break;
            
        default: break;
    }
}

- (void) contentOffsetChanged:(float)contentOffset {
    contentOffset = -contentOffset / 2;
        
    if (isRefreshing) {
        return;
    }
    
    if (contentOffset < -10) {
        contentOffset = -10;
    }
    
    if (contentOffset > 50) {
        contentOffset = 50;
    }
    
    if (contentOffset == 50.0) {
        bottomLeftView.center = CGPointMake((ScreenWidth / 2) - bottomLeftView.frame.size.width - 1, self.frame.size.height - 50 + bottomLeftView.frame.size.height + 1);
        bottomRightView.center = CGPointMake((ScreenWidth / 2) - bottomRightView.frame.size.width - 1, self.frame.size.height - 50 - bottomRightView.frame.size.height - 1);
        topRightView.center = CGPointMake((ScreenWidth / 2) + topRightView.frame.size.width + 1, self.frame.size.height - 50 - topRightView.frame.size.height - 1);
        topLeftView.center = CGPointMake((ScreenWidth / 2) + topLeftView.frame.size.width + 1, self.frame.size.height - 50 + topLeftView.frame.size.height + 1);
        
        middleLeftView.center = CGPointMake((ScreenWidth / 2) - middleLeftView.frame.size.width - 1, self.frame.size.height - 50);
        middleRightView.center = CGPointMake((ScreenWidth / 2) + middleRightView.frame.size.width + 1, self.frame.size.height - 50);
        middleCenterView.center = CGPointMake((ScreenWidth / 2), self.frame.size.height - 50);
        
    } else {
    
        lastOffset = contentOffset * 2;
        
        CGPoint point = [self calcNewCurvePointForBottomLeftViewForOffset: contentOffset];
        CGPoint point2 = [self calcNewCurvePointForBottomRightViewForOffset: contentOffset];
        
        bottomLeftView.center = CGPointMake(point.x, point.y);
        bottomRightView.center = CGPointMake(ScreenWidth - point2.x, self.frame.size.height - 100 + (self.frame.size.height - point2.y));
        bottomCenterView.center = [self calcNewPointForBottomCenterViewForOffset: contentOffset];
        
        middleLeftView.center = [self calcNewPointForMiddleLeftViewForOffset: contentOffset];
        middleRightView.center = CGPointMake(ScreenWidth - middleLeftView.center.x, middleLeftView.center.y);
        middleCenterView.center = [self calcNewPointForMiddleCenterViewForOffset: contentOffset];

        topRightView.center = CGPointMake(ScreenWidth - point.x, self.frame.size.height - 100 + (self.frame.size.height - point.y));
        topCenterView.center = [self calcNewPointForTopCenterViewForOffset: contentOffset];
        topLeftView.center = point2;
    }
    
    [self setNeedsDisplay];
}

- (CGPoint) calcNewCurvePointForBottomLeftViewForOffset: (float)contentOffset {
    
    contentOffset *= 2;
    contentOffset = (100 - contentOffset);
    
    return CGPointMake(((contentOffset + 70) * sin((contentOffset + 0) * M_PI / 90)) + (ScreenWidth / 2) - bottomLeftView.frame.size.width - 1, self.frame.size.height - ((contentOffset + 70) * cos((contentOffset + 0) * M_PI / 90)) + 28);
}


- (CGPoint) calcNewCurvePointForBottomRightViewForOffset: (float)contentOffset {
    
    contentOffset *= 2;
    contentOffset = (100 - contentOffset);
    
    CGPoint point = CGPointMake(((contentOffset + 70) * sin((contentOffset + 0) * M_PI / 90)) + (ScreenWidth / 2) - bottomLeftView.frame.size.width + 1, self.frame.size.height - ((contentOffset + 70) * cos((contentOffset + 0) * M_PI / 90)) + 29);
    
    CGPoint finalPoint = CGPointMake(point.x * cos(45 * M_PI / 180) + point.y * sin (45 * M_PI / 180) - (ScreenWidth > 700 ? 58.5 : 124),
                                     point.y * cos(45 * M_PI / 180) - point.x * sin (45 * M_PI / 180) + (ScreenWidth > 700 ? 342 : 183.7));
    return finalPoint;
}

- (CGPoint) calcNewLinearPointForBottomLeftViewForOffset: (float)contentOffset {
    
    float x1 = 10;
    float x2 = (ScreenWidth / 2) - bottomLeftView.frame.size.width;
    float y1 = 5;
    float y2 = 50 - bottomLeftView.frame.size.height;
    
    float A = y1 - y2;
    float B = x2 - x1;
    float C = x1 * y2 - x2 * y1;
    
    float newY = contentOffset;
    float newX = -(C + B * newY) / A;
    
    if ((newX > -10) && (newX < x2 - 1)) {
        return CGPointMake(newX, self.frame.size.height - newY);
    } else {
        if (newX >= x2 - 1) {
            return CGPointMake(x2 - 1, self.frame.size.height - (y2 - 1));
        } else {
            return CGPointMake(bottomLeftView.center.x, self.frame.size.height - newY);
        }
    }
}

- (CGPoint) calcNewPointForBottomCenterViewForOffset: (float)contentOffset {
    float x1 = (ScreenWidth / 2);
    float x2 = (ScreenWidth / 2);
    float y1 = -10;
    float y2 = 50 - bottomCenterView.frame.size.height;
    
    float A = y1 - y2;
    float B = x2 - x1;
    float C = x1 * y2 - x2 * y1;
    
    float newY = contentOffset;
    float newX = -(C + B * newY) / A;
    
    if ((newY > -10) && (newY < y2)) {
        return CGPointMake(newX, self.frame.size.height - newY);
    } else {
        if (newY >= y2) {
            return CGPointMake(x2, self.frame.size.height - (y2 - 1));
        } else {
            return CGPointMake(bottomCenterView.center.x, self.frame.size.height - newY);
        }
    }
}

- (CGPoint) calcNewPointForMiddleLeftViewForOffset: (float)contentOffset {
    float x1 = 10;
    float x2 = (ScreenWidth / 2) - middleLeftView.frame.size.width;
    float y1 = 5;
    float y2 = 50;
    
    float A = y1 - y2;
    float B = x2 - x1;
    float C = x1 * y2 - x2 * y1;
    
    float newY = contentOffset;
    float newX = -(C + B * newY) / A;
    
    if ((newX > -10) && (newX < x2 - 1)) {
        return CGPointMake(newX, self.frame.size.height - newY);
    } else {
        if (newX >= x2 - 1) {
            return CGPointMake(x2 - 1, self.frame.size.height - y2);
        } else {
            return CGPointMake(middleLeftView.center.x, self.frame.size.height - newY);
        }
    }
}

- (CGPoint) calcNewPointForMiddleCenterViewForOffset: (float)contentOffset {
    float x1 = (ScreenWidth / 2);
    float x2 = (ScreenWidth / 2);
    float y1 = -10;
    float y2 = 50;
    
    float A = y1 - y2;
    float B = x2 - x1;
    float C = x1 * y2 - x2 * y1;
    
    float newY = contentOffset;
    float newX = -(C + B * newY) / A;
    
    if ((newY > -10) && (newY < y2)) {
        return CGPointMake(newX, self.frame.size.height - newY);
    } else {
        if (newY >= y2) {
            return CGPointMake(x2, self.frame.size.height - y2);
        } else {
            return CGPointMake(middleCenterView.center.x, self.frame.size.height - newY);
        }
    }
}

- (CGPoint) calcNewPointForTopLeftViewForOffset: (float)contentOffset {
    float x1 = 10;
    float x2 = (ScreenWidth / 2) - topLeftView.frame.size.width;
    float y1 = 70;
    float y2 = 50 + topLeftView.frame.size.height;
    
    float A = y1 - y2;
    float B = x2 - x1;
    float C = x1 * y2 - x2 * y1;
    
    float newY = 100 - contentOffset;
    float newX = -(C + B * newY) / A;
    
    if ((newX > -10) && (newX < x2 - 1)) {
        
        return CGPointMake(newX, self.frame.size.height - newY);
    } else {
        if (newX >= x2 - 1) {
            return CGPointMake(x2 - 1, self.frame.size.height - (y2 + 1));
        } else {
            return CGPointMake(topLeftView.center.x, self.frame.size.height - newY);
        }
    }
}

- (CGPoint) calcNewPointForTopCenterViewForOffset: (float)contentOffset {
    float x1 = (ScreenWidth / 2);
    float x2 = (ScreenWidth / 2);
    float y1 = 100;
    float y2 = 50 + topCenterView.frame.size.height;
    
    float A = y1 - y2;
    float B = x2 - x1;
    float C = x1 * y2 - x2 * y1;
    
    float newY = 100 - contentOffset;
    float newX = -(C + B * newY) / A;
    
    if ((newY < 120) && (newY > y2)) {
        return CGPointMake(newX, self.frame.size.height - newY);
    } else {
        if (newY <= y2) {
            return CGPointMake(x2, self.frame.size.height - (y2 + 1));
        } else {
            return CGPointMake(middleCenterView.center.x, self.frame.size.height - newY);
        }
    }
}

@end

