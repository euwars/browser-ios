//
//  ODRefreshControl.m
//  ODRefreshControl
//
//  Created by Fabio Ritrovato on 6/13/12.
//  Copyright (c) 2012 orange in a day. All rights reserved.
//
// https://github.com/Sephiroth87/ODRefreshControl
//

#import "ODRefreshControl.h"
#define scaling 0.9f

const CGFloat kMinTopPadding    = 9.0f * scaling;
const CGFloat kMaxTopPadding    = 5.0f  * scaling;
const CGFloat kMinTopRadius     = 12.5f  * scaling;
const CGFloat kMaxTopRadius     = 16.0f  * scaling;
const CGFloat kMinBottomRadius  = 3.0f  * scaling;
const CGFloat kMaxBottomRadius  = 16.0f  * scaling;
const CGFloat kMinBottomPadding = 4.0f  * scaling;
const CGFloat kMaxBottomPadding = 6.0f  * scaling;
const CGFloat kMinArrowSize     = 2.0f  * scaling;
const CGFloat kMaxArrowSize     = 3.0f  * scaling;
const CGFloat kMinArrowRadius   = 5.0f  * scaling;
const CGFloat kMaxArrowRadius   = 7.0f  * scaling;
const CGFloat kMaxDistance      = 53.0f  * scaling;

UIView *_activity;

@interface ODRefreshControlDefaultContentView : UIView <ODRefreshControlContentView>

- (id)initWithFrame:(CGRect)frame activityIndicatorView:(UIView *)activity;

@property (nonatomic,getter=isEnabled) BOOL enabled;
@property (nonatomic, strong) UIColor *tintColor;

@end

@interface ODRefreshControlDefaultContentView ()
{
    CAShapeLayer *_shapeLayer;
    CAShapeLayer *_arrowLayer;
    CAShapeLayer *_highlightLayer;
    BOOL _refreshing;
}

@end

@implementation ODRefreshControlDefaultContentView

static inline CGFloat lerp(CGFloat a, CGFloat b, CGFloat p)
{
    return a + (b - a) * p;
}

- (id)initWithFrame:(CGRect)frame activityIndicatorView:(UIView *)activity
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        id activity = nil;
        _activity = activity ? activity : [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activity.center = CGPointMake(floor(self.frame.size.width / 2), floor(self.frame.size.height / 2));
        _activity.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        _activity.alpha = 0;
        if ([_activity respondsToSelector:@selector(startAnimating)]) {
            [(UIActivityIndicatorView *)_activity startAnimating];
        }
        [self addSubview:_activity];
        
        _tintColor = [UIColor colorWithRed:155.0 / 255.0 green:162.0 / 255.0 blue:172.0 / 255.0 alpha:1.0];
        
        _shapeLayer = [CAShapeLayer layer];
        _shapeLayer.fillColor = [_tintColor CGColor];
        _shapeLayer.strokeColor = [[[UIColor darkGrayColor] colorWithAlphaComponent:0.5] CGColor];
        _shapeLayer.lineWidth = 0.5;
        _shapeLayer.shadowColor = [[UIColor blackColor] CGColor];
        _shapeLayer.shadowOffset = CGSizeMake(0, 1);
        _shapeLayer.shadowOpacity = 0.4;
        _shapeLayer.shadowRadius = 0.5;
        [self.layer addSublayer:_shapeLayer];
        
        _arrowLayer = [CAShapeLayer layer];
        _arrowLayer.strokeColor = [[[UIColor darkGrayColor] colorWithAlphaComponent:0.5] CGColor];
        _arrowLayer.lineWidth = 0.5;
        _arrowLayer.fillColor = [[UIColor whiteColor] CGColor];
        [_shapeLayer addSublayer:_arrowLayer];
        
        _highlightLayer = [CAShapeLayer layer];
        _highlightLayer.fillColor = [[[UIColor whiteColor] colorWithAlphaComponent:0.2] CGColor];
        [_shapeLayer addSublayer:_highlightLayer];
    }
    return self;
}

#pragma mark - Properties

- (void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    _shapeLayer.hidden = !self.enabled;
}

- (void)setTintColor:(UIColor *)tintColor
{
    _tintColor = tintColor;
    _shapeLayer.fillColor = [_tintColor CGColor];
}

- (void)setActivityIndicatorViewStyle:(UIActivityIndicatorViewStyle)activityIndicatorViewStyle
{
    if ([_activity isKindOfClass:[UIActivityIndicatorView class]]) {
        [(UIActivityIndicatorView *)_activity setActivityIndicatorViewStyle:activityIndicatorViewStyle];
    }
}

- (UIActivityIndicatorViewStyle)activityIndicatorViewStyle
{
    if ([_activity isKindOfClass:[UIActivityIndicatorView class]]) {
        return [(UIActivityIndicatorView *)_activity activityIndicatorViewStyle];
    }
    return 0;
}

- (void)setActivityIndicatorViewColor:(UIColor *)activityIndicatorViewColor
{
    if ([_activity isKindOfClass:[UIActivityIndicatorView class]] && [_activity respondsToSelector:@selector(setColor:)]) {
        [(UIActivityIndicatorView *)_activity setColor:activityIndicatorViewColor];
    }
}

- (UIColor *)activityIndicatorViewColor
{
    if ([_activity isKindOfClass:[UIActivityIndicatorView class]] && [_activity respondsToSelector:@selector(color)]) {
        return [(UIActivityIndicatorView *)_activity color];
    }
    return nil;
}

#pragma mark - Layout

- (void)layoutSubviews
{
    if (_refreshing) {
        // Keep thing pinned at the top
        _activity.center = CGPointMake(floor(self.frame.size.width / 2), MIN(floor([self openHeight] / 2), self.frame.size.height - [self openHeight]/ 2));
    } else {
        if (self.frame.size.height == 0) {
            _shapeLayer.path = nil;
            _shapeLayer.shadowPath = nil;
            _arrowLayer.path = nil;
            _highlightLayer.path = nil;
            return;
        }
        CGMutablePathRef path = CGPathCreateMutable();
        
        //Calculate some useful points and values
        CGFloat verticalShift = MAX(0, -((kMaxTopRadius + kMaxBottomRadius + kMaxTopPadding + kMaxBottomPadding) - self.frame.size.height));
        CGFloat distance = MIN(kMaxDistance, fabs(verticalShift));
        CGFloat percentage = 1 - (distance / kMaxDistance);
        
        CGFloat currentTopPadding = lerp(kMinTopPadding, kMaxTopPadding, percentage);
        CGFloat currentTopRadius = lerp(kMinTopRadius, kMaxTopRadius, percentage);
        CGFloat currentBottomRadius = lerp(kMinBottomRadius, kMaxBottomRadius, percentage);
        CGFloat currentBottomPadding =  lerp(kMinBottomPadding, kMaxBottomPadding, percentage);
        
        CGPoint bottomOrigin = CGPointMake(floor(self.bounds.size.width / 2), self.bounds.size.height - currentBottomPadding -currentBottomRadius);
        CGPoint topOrigin = CGPointZero;
        if (distance == 0) {
            topOrigin = CGPointMake(floor(self.bounds.size.width / 2), bottomOrigin.y);
        } else {
            topOrigin = CGPointMake(floor(self.bounds.size.width / 2), currentTopPadding + currentTopRadius);
            if (percentage == 0) {
                bottomOrigin.y -= (fabs(verticalShift) - kMaxDistance);
            }
        }
        
        //Top semicircle
        CGPathAddArc(path, NULL, topOrigin.x, topOrigin.y, currentTopRadius, 0, M_PI, YES);
        
        //Left curve
        CGPoint leftCp1 = CGPointMake(lerp((topOrigin.x - currentTopRadius), (bottomOrigin.x - currentBottomRadius), 0.1), lerp(topOrigin.y, bottomOrigin.y, 0.2));
        CGPoint leftCp2 = CGPointMake(lerp((topOrigin.x - currentTopRadius), (bottomOrigin.x - currentBottomRadius), 0.9), lerp(topOrigin.y, bottomOrigin.y, 0.2));
        CGPoint leftDestination = CGPointMake(bottomOrigin.x - currentBottomRadius, bottomOrigin.y);
        
        CGPathAddCurveToPoint(path, NULL, leftCp1.x, leftCp1.y, leftCp2.x, leftCp2.y, leftDestination.x, leftDestination.y);
        
        //Bottom semicircle
        CGPathAddArc(path, NULL, bottomOrigin.x, bottomOrigin.y, currentBottomRadius, M_PI, 0, YES);
        
        //Right curve
        CGPoint rightCp2 = CGPointMake(lerp((topOrigin.x + currentTopRadius), (bottomOrigin.x + currentBottomRadius), 0.1), lerp(topOrigin.y, bottomOrigin.y, 0.2));
        CGPoint rightCp1 = CGPointMake(lerp((topOrigin.x + currentTopRadius), (bottomOrigin.x + currentBottomRadius), 0.9), lerp(topOrigin.y, bottomOrigin.y, 0.2));
        CGPoint rightDestination = CGPointMake(topOrigin.x + currentTopRadius, topOrigin.y);
        
        CGPathAddCurveToPoint(path, NULL, rightCp1.x, rightCp1.y, rightCp2.x, rightCp2.y, rightDestination.x, rightDestination.y);
        CGPathCloseSubpath(path);
        
        // Set paths
        _shapeLayer.path = path;
        _shapeLayer.shadowPath = path;
        
        // Add the arrow shape
        CGFloat currentArrowSize = lerp(kMinArrowSize, kMaxArrowSize, percentage);
        CGFloat currentArrowRadius = lerp(kMinArrowRadius, kMaxArrowRadius, percentage);
        CGFloat arrowBigRadius = currentArrowRadius + (currentArrowSize / 2);
        CGFloat arrowSmallRadius = currentArrowRadius - (currentArrowSize / 2);
        CGMutablePathRef arrowPath = CGPathCreateMutable();
        CGPathAddArc(arrowPath, NULL, topOrigin.x, topOrigin.y, arrowBigRadius, 0, 3 * M_PI_2, NO);
        CGPathAddLineToPoint(arrowPath, NULL, topOrigin.x, topOrigin.y - arrowBigRadius - currentArrowSize);
        CGPathAddLineToPoint(arrowPath, NULL, topOrigin.x + (2 * currentArrowSize), topOrigin.y - arrowBigRadius + (currentArrowSize / 2));
        CGPathAddLineToPoint(arrowPath, NULL, topOrigin.x, topOrigin.y - arrowBigRadius + (2 * currentArrowSize));
        CGPathAddLineToPoint(arrowPath, NULL, topOrigin.x, topOrigin.y - arrowBigRadius + currentArrowSize);
        CGPathAddArc(arrowPath, NULL, topOrigin.x, topOrigin.y, arrowSmallRadius, 3 * M_PI_2, 0, YES);
        CGPathCloseSubpath(arrowPath);
        _arrowLayer.path = arrowPath;
        [_arrowLayer setFillRule:kCAFillRuleEvenOdd];
        CGPathRelease(arrowPath);
        
        // Add the highlight shape
        CGMutablePathRef highlightPath = CGPathCreateMutable();
        CGPathAddArc(highlightPath, NULL, topOrigin.x, topOrigin.y, currentTopRadius, 0, M_PI, YES);
        CGPathAddArc(highlightPath, NULL, topOrigin.x, topOrigin.y + 1.25, currentTopRadius, M_PI, 0, NO);
        
        _highlightLayer.path = highlightPath;
        [_highlightLayer setFillRule:kCAFillRuleNonZero];
        
        CGPathRelease(highlightPath);
        CGPathRelease(path);
    }
}

- (void)beginRefreshing:(BOOL)animated
{
    if (!_refreshing) {
        if (animated) {
            // Start the shape disappearance animation
            CGFloat radius = lerp(kMinBottomRadius, kMaxBottomRadius, 0.2);
            CABasicAnimation *pathMorph = [CABasicAnimation animationWithKeyPath:@"path"];
            pathMorph.duration = 0.15;
            pathMorph.fillMode = kCAFillModeForwards;
            pathMorph.removedOnCompletion = NO;
            CGMutablePathRef toPath = CGPathCreateMutable();
            CGPoint topOrigin = CGPointMake(floor(self.bounds.size.width / 2), kMaxTopPadding + kMaxTopRadius);
            CGPathAddArc(toPath, NULL, topOrigin.x, topOrigin.y, radius, 0, M_PI, YES);
            CGPathAddCurveToPoint(toPath, NULL, topOrigin.x - radius, topOrigin.y, topOrigin.x - radius, topOrigin.y, topOrigin.x - radius, topOrigin.y);
            CGPathAddArc(toPath, NULL, topOrigin.x, topOrigin.y, radius, M_PI, 0, YES);
            CGPathAddCurveToPoint(toPath, NULL, topOrigin.x + radius, topOrigin.y, topOrigin.x + radius, topOrigin.y, topOrigin.x + radius, topOrigin.y);
            CGPathCloseSubpath(toPath);
            pathMorph.toValue = (__bridge id)toPath;
            [_shapeLayer addAnimation:pathMorph forKey:nil];
            CABasicAnimation *shadowPathMorph = [CABasicAnimation animationWithKeyPath:@"shadowPath"];
            shadowPathMorph.duration = 0.15;
            shadowPathMorph.fillMode = kCAFillModeForwards;
            shadowPathMorph.removedOnCompletion = NO;
            shadowPathMorph.toValue = (__bridge id)toPath;
            [_shapeLayer addAnimation:shadowPathMorph forKey:nil];
            CGPathRelease(toPath);
            CABasicAnimation *shapeAlphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            shapeAlphaAnimation.duration = 0.1;
            shapeAlphaAnimation.beginTime = CACurrentMediaTime() + 0.1;
            shapeAlphaAnimation.toValue = [NSNumber numberWithFloat:0];
            shapeAlphaAnimation.fillMode = kCAFillModeForwards;
            shapeAlphaAnimation.removedOnCompletion = NO;
            [_shapeLayer addAnimation:shapeAlphaAnimation forKey:nil];
            CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            alphaAnimation.duration = 0.1;
            alphaAnimation.toValue = [NSNumber numberWithFloat:0];
            alphaAnimation.fillMode = kCAFillModeForwards;
            alphaAnimation.removedOnCompletion = NO;
            [_arrowLayer addAnimation:alphaAnimation forKey:nil];
            [_highlightLayer addAnimation:alphaAnimation forKey:nil];
            
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            _activity.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1);
            [CATransaction commit];
            [UIView animateWithDuration:0.2 delay:0.15 options:UIViewAnimationOptionCurveLinear animations:^{
                _activity.alpha = 1;
                _activity.layer.transform = CATransform3DMakeScale(1, 1, 1);
            } completion:nil];
        } else {
            CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            alphaAnimation.duration = 0.0001;
            alphaAnimation.toValue = [NSNumber numberWithFloat:0];
            alphaAnimation.fillMode = kCAFillModeForwards;
            alphaAnimation.removedOnCompletion = NO;
            [_shapeLayer addAnimation:alphaAnimation forKey:nil];
            [_arrowLayer addAnimation:alphaAnimation forKey:nil];
            [_highlightLayer addAnimation:alphaAnimation forKey:nil];
            
            _activity.alpha = 1;
            _activity.layer.transform = CATransform3DMakeScale(1, 1, 1);
        }
        
        _refreshing = YES;
    }
}

- (void)endRefreshing
{
    if (_refreshing) {
        [UIView animateWithDuration:0.4 animations:^{
            _activity.alpha = 0;
            _activity.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1);
        } completion:^(BOOL finished) {
            [_shapeLayer removeAllAnimations];
            _shapeLayer.path = nil;
            _shapeLayer.shadowPath = nil;
            _shapeLayer.position = CGPointZero;
            [_arrowLayer removeAllAnimations];
            _arrowLayer.path = nil;
            [_highlightLayer removeAllAnimations];
            _highlightLayer.path = nil;
            _refreshing = NO;
        }];
    }
}

- (CGFloat)triggerHeight
{
    return kMaxDistance + 43;
}

- (CGFloat)openHeight
{
    return 44.0f;
}

@end

@interface ODRefreshControl ()
{
    UIView<ODRefreshControlContentView> *_contentView;
    
    BOOL _canRefresh;
    BOOL _ignoreInset;
    BOOL _ignoreOffset;
    BOOL _didSetInset;
    BOOL _hasSectionHeaders;
    CGFloat _lastOffset;
    CGFloat _currentTopInset;
}

@property (nonatomic, readwrite) BOOL refreshing;
@property (nonatomic, assign) UIView *parentView;


@end

@implementation ODRefreshControl

- (id)initInScrollView:(UIView *)parentView {
    return [self initInScrollView:parentView activityIndicatorView:nil];
}

- (id)initInScrollView:(UIView *)parentView activityIndicatorView:(UIView *)activity
{
    self = [super initWithFrame:CGRectMake(0, 0, parentView.frame.size.width, 0)];
    
    if (self) {
        self.parentView = parentView;

        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [parentView addSubview:self];
//        [parentView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
//        [parentView addObserver:self forKeyPath:@"contentInset" options:NSKeyValueObservingOptionNew context:nil];

        _contentView = [[ODRefreshControlDefaultContentView alloc] initWithFrame:self.bounds activityIndicatorView:activity];
        _contentView.clipsToBounds = YES;
        _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_contentView];
    }
    return self;
}

- (void)dealloc
{
//    [self.parentView removeObserver:self forKeyPath:@"contentOffset"];
//    [self.parentView removeObserver:self forKeyPath:@"contentInset"];
    self.parentView = nil;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    if (!newSuperview) {
//        [self.parentView removeObserver:self forKeyPath:@"contentOffset"];
//        [self.parentView removeObserver:self forKeyPath:@"contentInset"];
        self.parentView = nil;
    }
}

#pragma mark - Properties

- (void)setEnabled:(BOOL)enabled
{
    super.enabled = enabled;
    _contentView.enabled = enabled;
}


- (void)setTintColor:(UIColor *)tintColor
{
    _contentView.tintColor = tintColor;
}

- (UIColor *)tintColor
{
    return _contentView.tintColor;
}

- (void)setActivityIndicatorViewStyle:(UIActivityIndicatorViewStyle)activityIndicatorViewStyle
{
    _contentView.activityIndicatorViewStyle = activityIndicatorViewStyle;
}

- (UIActivityIndicatorViewStyle)activityIndicatorViewStyle
{
    return _contentView.activityIndicatorViewStyle;
}

- (void)setActivityIndicatorViewColor:(UIColor *)activityIndicatorViewColor
{
    _contentView.activityIndicatorViewColor = activityIndicatorViewColor;
}

- (UIColor *)activityIndicatorViewColor
{
    return _contentView.activityIndicatorViewColor;
}

#pragma mark - Scroll handling

- (CGFloat)navigationBarInset
{
    if ([UIViewController instancesRespondToSelector:@selector(topLayoutGuide)]) {
        Class class = [UIViewController class];
        UIResponder *responder = self;
        while ((responder = [responder nextResponder])) {
            if ([responder isKindOfClass:class]) {
                break;
            }
        }
        UIViewController *viewController = (UIViewController *)responder;
        if (viewController.automaticallyAdjustsScrollViewInsets && (viewController.edgesForExtendedLayout & UIRectEdgeTop)) {
            // There's a known bug in iOS7 where calling topLayoutGuide breaks UITableViewControllers, so we do some manual calculations
            CGFloat size = MIN([UIApplication sharedApplication].statusBarFrame.size.height, [UIApplication sharedApplication].statusBarFrame.size.width);
            if (viewController.navigationController) {
                size += CGRectIntersection(viewController.navigationController.view.bounds, viewController.navigationController.navigationBar.frame).size.height;
            }
            return size;
        }
    }
    return 0.0f;
}

#pragma mark - Public methods

-(void)animate
{
  assert(_activity);
  [(UIActivityIndicatorView *)_activity startAnimating];
}


- (void)beginRefreshing
{
    [_contentView beginRefreshing:YES];
    
//    CGPoint offset = self.parentView.contentOffset;
//    _ignoreInset = YES;
//    _currentTopInset = [_contentView openHeight];
//    self.parentView.contentInset = UIEdgeInsetsMake(_currentTopInset + self.originalContentInset.top, self.originalContentInset.left, self.originalContentInset.bottom, self.originalContentInset.right);
//    _ignoreInset = NO;
//    [self.parentView setContentOffset:offset animated:NO];

    self.refreshing = YES;
    _canRefresh = NO;
}

- (void)endRefreshing
{
    if (_refreshing) {
        // Create a temporary retain-cycle, so the parentView won't be released
        // halfway through the end animation.
        // This allows for the refresh control to clean up the observer,
        // in the case the parentView is released while the animation is running
        //__block UIView *blockScrollView = self.parentView;
        [UIView animateWithDuration:0.4 animations:^{
            _ignoreInset = YES;
            _currentTopInset = 0.0f;
           // [blockScrollView setContentInset:self.originalContentInset];
            _ignoreInset = NO;
        } completion:^(BOOL finished) {
            // We need to use the parentView somehow in the end block,
            // or it'll get released in the animation block.
            _ignoreInset = YES;
           // [blockScrollView setContentInset:self.originalContentInset];
            _ignoreInset = NO;
        }];
        [_contentView endRefreshing];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.refreshing = NO;
        });
    }
}

@end
