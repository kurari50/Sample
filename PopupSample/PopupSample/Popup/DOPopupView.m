//
//  DOPopupView.m
//  PopupSample
//
//  Created by kura on 2015/06/06.
//  Copyright (c) 2015年 kura. All rights reserved.
//

#import "DOPopupView.h"

#define DEBUG_DOPopupView 0

#if ! DEBUG_DOPopupView
#define NSLog(...)
#endif

@interface DOWeakObject : NSObject
@property (nonatomic, weak) NSObject *obj;
@end
@implementation DOWeakObject
+ (instancetype)weak:(NSObject *)obj
{
    DOWeakObject *o = [[DOWeakObject alloc] init];
    o.obj = obj;
    return o;
}
@end

@interface DOPopupView ()

@property (nonatomic, assign) DOPopupViewResizingMode resizingMode;
@property (nonatomic, weak) UIView *innerView;
@property (nonatomic, weak) UIView *parentView;
@property (nonatomic, weak) UIView *baseView;
@property (nonatomic, weak) UIViewController *parentViewController;

@property (nonatomic, assign, readonly) BOOL isInWindow;
@property (nonatomic, assign, readonly) BOOL isInViewController;
@property (nonatomic, assign, readonly) BOOL needRotateSelf;

@end

@implementation DOPopupView

static NSMutableDictionary *s_popup;

+ (void)initialize
{
    [super initialize];
    
    s_popup = [[NSMutableDictionary alloc] init];
}

- (BOOL)needRotateSelf
{
    return [UIDevice currentDevice].systemVersion.floatValue < 8.0 && [self isInWindow];
}

- (BOOL)isShowning
{
    return !self.hidden && self.superview != nil;
}

- (BOOL)isInWindow
{
    return [self.parentView isKindOfClass:[UIWindow class]];
}

- (BOOL)isInViewController
{
    return self.parentViewController != nil;
}

- (void)setOrigin:(CGPoint)origin to:(UIView *)view
{
    NSLog(@"----- setOrigin:to: -----");
    CGRect frame = view.frame;
    frame.origin = origin;
    view.frame = frame;
    
    if (view == self.baseView) {
        [self setOrigin:CGPointZero to:self.backgroundView];
    }
    
    if (view == self.innerView) {
        NSLog(@"InnerView Frame: %@", NSStringFromCGRect(frame));
        NSLog(@"InnerView Bounds: %@", NSStringFromCGRect(view.bounds));
    } else if (view == self) {
        NSLog(@"Popup Frame: %@", NSStringFromCGRect(frame));
        NSLog(@"Popup Bounds: %@", NSStringFromCGRect(view.bounds));
    } else if (view == self.baseView) {
        NSLog(@"Base Frame: %@", NSStringFromCGRect(frame));
        NSLog(@"Base Bounds: %@", NSStringFromCGRect(view.bounds));
    } else {
        NSLog(@"View Frame: %@", NSStringFromCGRect(frame));
        NSLog(@"View Bounds: %@", NSStringFromCGRect(view.bounds));
    }
    NSLog(@"----------");
}

- (void)setSize:(CGSize)size to:(UIView *)view
{
    NSLog(@"----- setSize:to: -----");
    CGRect bounds = view.bounds;
    bounds.size = size;
    view.bounds = bounds;
    
    if (view == self.baseView) {
        [self setSize:size to:self.backgroundView];
    }
    
    if (view == self.innerView) {
        NSLog(@"InnerView Frame: %@", NSStringFromCGRect(view.frame));
        NSLog(@"InnerView Bounds: %@", NSStringFromCGRect(bounds));
    } else if (view == self) {
        NSLog(@"Popup Frame: %@", NSStringFromCGRect(view.frame));
        NSLog(@"Popup Bounds: %@", NSStringFromCGRect(bounds));
    } else if (view == self.baseView) {
        NSLog(@"Base Frame: %@", NSStringFromCGRect(view.frame));
        NSLog(@"Base Bounds: %@", NSStringFromCGRect(bounds));
    } else {
        NSLog(@"View Frame: %@", NSStringFromCGRect(view.frame));
        NSLog(@"View Bounds: %@", NSStringFromCGRect(bounds));
    }
    NSLog(@"----------");
}

- (CGSize)parentViewSize
{
    return [self parentViewSizeWithOrientation:UIInterfaceOrientationUnknown];
}

- (CGSize)parentViewSizeWithOrientation:(UIInterfaceOrientation)orientation
{
    CGSize size = self.parentView.bounds.size;
    if (self.isInWindow) {
        if (orientation == UIInterfaceOrientationUnknown) {
            orientation = [UIApplication sharedApplication].statusBarOrientation;
        }
        
        // 必ずheighの方が小さくなるようにする
        if (UIInterfaceOrientationIsPortrait(orientation)) {
            if (size.height < size.width) {
                size = CGSizeMake(size.height, size.width);
            }
        } else {
            if (size.height > size.width) {
                size = CGSizeMake(size.height, size.width);
            }
        }
    }
    return size;
}

- (CGSize)statusBarSize
{
    CGSize size = [UIApplication sharedApplication].statusBarFrame.size;
    if (size.height > size.width) {
        size = CGSizeMake(size.height, size.width);
    }
    if (size.height > 0 && !self.isInWindow) {
        // 着信中など、ステータスバーのサイズが変化している場合があるので、固定値とする
        size.height = 20;
    }
    return size;
}

- (CGSize)navigationBarSize
{
    CGSize size = self.parentViewController.navigationController.navigationBar.bounds.size;
    if (size.height > size.width) {
        size = CGSizeMake(size.height, size.width);
    }
    if (self.parentViewController.navigationController.navigationBarHidden) {
        // hiddenの場合は高さ0
        size = CGSizeZero;
    }
    return size;
}

- (void)layoutSelfWithOrientation:(UIInterfaceOrientation)orientation
{
    NSLog(@"----- layoutSelf -----");
    CGSize selfSize = [self parentViewSizeWithOrientation:orientation];
    CGPoint selfOrigin = CGPointZero;
    
    [self setSize:selfSize to:self];
    [self setOrigin:selfOrigin to:self];
    
    if (!self.enableUnderTopBar && (self.isInWindow || self.isInViewController)) {
        // ステータスバーとナビゲーションバーの高さを計算して、重ならないようにする
        CGSize statusBarSize = [self statusBarSize];
        CGSize navigationBarSize = [self navigationBarSize];
        CGFloat offset = statusBarSize.height + navigationBarSize.height;
        selfSize.height = selfSize.height - offset;
        selfOrigin.y = selfOrigin.y + offset;
    }
    
    [self setSize:selfSize to:self.baseView];
    [self setOrigin:selfOrigin to:self.baseView];
    
    if (self.needRotateSelf) {
        if (orientation == UIInterfaceOrientationUnknown) {
            orientation = [UIApplication sharedApplication].statusBarOrientation;
        }
        
        CGFloat degree = 0;
        switch (orientation) {
            case UIInterfaceOrientationPortrait:
                degree = 0;
                break;
            case UIInterfaceOrientationLandscapeLeft:
                degree = -90;
                break;
            case UIInterfaceOrientationLandscapeRight:
                degree = 90;
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                degree = 180;
                break;
                
            default:
                break;
        }
        self.transform = CGAffineTransformMakeRotation(degree * M_PI / 180.0);
    }
    
    NSLog(@"----------");
}

- (void)layoutInnerView
{
    NSLog(@"----- layoutInnerView -----");
    if (self.resizingMode == DOPopupViewResizingModeStrech) {
        [self setSize:[self sizeForInnerView] to:self.innerView];
        [self setOrigin:CGPointZero to:self.innerView];
    }
    [self centeringInnerView];
    NSLog(@"----------");
}

- (void)centeringInnerView
{
    NSLog(@"----- centeringInnerView -----");
    NSLog(@"Popup Frame: %@", NSStringFromCGRect(self.frame));
    NSLog(@"Popup Bounds: %@", NSStringFromCGRect(self.bounds));
    NSLog(@"Base Frame: %@", NSStringFromCGRect(self.baseView.frame));
    NSLog(@"Base Bounds: %@", NSStringFromCGRect(self.baseView.bounds));
    NSLog(@"InnerView Frame: %@", NSStringFromCGRect(self.innerView.frame));
    NSLog(@"InnerView Bounds: %@", NSStringFromCGRect(self.innerView.bounds));
    
    CGFloat x, y, w, h;
    
    w = self.innerView.bounds.size.width;
    h = self.innerView.bounds.size.height;
    
    x = (self.baseView.bounds.size.width - w) / 2;
    y = (self.baseView.bounds.size.height - h) / 2;
    
    [self setSize:CGSizeMake(w, h) to:self.innerView];
    [self setOrigin:CGPointMake(x, y) to:self.innerView];
    NSLog(@"----------");
}

- (CGSize)sizeForInnerView
{
    id<DOPopupViewDelegate> delegate = self.delegate;
    CGSize size = self.baseView.bounds.size;
    if (delegate &&
        [delegate conformsToProtocol:@protocol(DOPopupViewDelegate)] &&
        [delegate respondsToSelector:@selector(popup:didChangeSize:)]) {
        size = [delegate popup:self didChangeSize:size];
    }
#if DEBUG_DOPopupView
    size = CGSizeMake(size.width - 10, size.height - 10);
#endif
    return size;
}

- (instancetype)initWithInnerView:(UIView *)view resizingMode:(DOPopupViewResizingMode)resizingMode
{
    self = [self init];
    if (self) {
        NSLog(@"----- initWithInnerView:resizingMode: -----");
        _innerView = view;
        _resizingMode = resizingMode;
        
#if DEBUG_DOPopupView
        self.backgroundColor = [UIColor cyanColor];
#endif
        
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.clipsToBounds = YES;
        
        // ビューの構成
        //  self                <- 回転するため、centerが一定になるように幅と高さを変更しない
        //      baseView        <- ステータスバーやナビゲーションバーなどに重ならないように高さを調整する
        //          InnerView   <- センタリングする
        UIView *baseView = [[UIView alloc] initWithFrame:self.frame];
        _baseView = baseView;
        baseView.autoresizingMask = UIViewAutoresizingNone;
        baseView.clipsToBounds = YES;
#if DEBUG_DOPopupView
        baseView.backgroundColor = [UIColor blueColor];
#endif
        [baseView addSubview:view];
        [self addSubview:baseView];
        
        // InnerViewが勝手にリサイズされないようにする
        _innerView.autoresizingMask = UIViewAutoresizingNone;
        
        NSLog(@"InnerView Frame: %@", NSStringFromCGRect(_innerView.frame));
        NSLog(@"InnerView Bounds: %@", NSStringFromCGRect(_innerView.bounds));
        NSLog(@"InnerView autoresizingMask: %d", (int)_innerView.autoresizingMask);
        
        NSLog(@"----------");
    }
    return self;
}

- (instancetype)showInViewController:(UIViewController *)viewController
{
    self.parentViewController = viewController;
    return [self showInView:viewController.view];
}

- (instancetype)showInView:(UIView *)view
{
    NSLog(@"----- showInView -----");
    self.parentView = view;
    
    [self layoutSelfWithOrientation:UIInterfaceOrientationUnknown];
    [self layoutInnerView];
    
    [view addSubview:self];
    
    NSString *tag = @"DOPopupView_no_tag";
    if (self.tagString) {
        tag = self.tagString;
    }
    @synchronized (s_popup) {
        NSMutableArray *array = s_popup[tag];
        if (array == nil) {
            array = [@[] mutableCopy];
        }
        [array addObject:[DOWeakObject weak:self]];
        [s_popup setObject:array forKey:tag];
    }
    
    // 画面回転、ステータスバーサイズ変化、ナビゲーションバー表示/非表示・サイズ変化を検知する
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNotification:) name:UIApplicationWillChangeStatusBarFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNotification:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNotification:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNotification:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    [self.parentViewController.navigationController addObserver:self forKeyPath:@"navigationBarHidden" options:NSKeyValueObservingOptionNew context:NULL];
    [self.parentViewController.navigationController.navigationBar.layer addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:NULL];
    [self.parentViewController.navigationController.navigationBar.layer addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:NULL];
    [self.parentViewController.navigationController.navigationBar addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:NULL];
    [self.parentViewController.navigationController.navigationBar addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:NULL];
    NSLog(@"----------");
    
    return self;
}

- (void)setBackgroundView:(UIView *)backgroundView
{
    _backgroundView = backgroundView;
    
    backgroundView.autoresizingMask = UIViewAutoresizingNone;
    
    [self.baseView insertSubview:backgroundView atIndex:0];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.parentViewController.navigationController && [keyPath isEqualToString:@"navigationBarHidden"]) {
        [self setNeedsLayout];
        return;
    }
    if (object == self.parentViewController.navigationController.navigationBar.layer && [keyPath isEqualToString:@"frame"]) {
        [self setNeedsLayout];
        return;
    }
    if (object == self.parentViewController.navigationController.navigationBar.layer && [keyPath isEqualToString:@"bounds"]) {
        [self setNeedsLayout];
        return;
    }
    if (object == self.parentViewController.navigationController.navigationBar && [keyPath isEqualToString:@"frame"]) {
        [self setNeedsLayout];
        return;
    }
    if (object == self.parentViewController.navigationController.navigationBar && [keyPath isEqualToString:@"bounds"]) {
        [self setNeedsLayout];
        return;
    }
}

- (void)dealloc
{
    [self.parentViewController.navigationController removeObserver:self forKeyPath:@"navigationBarHidden" context:NULL];
    [self.parentViewController.navigationController.navigationBar.layer removeObserver:self forKeyPath:@"frame" context:NULL];
    [self.parentViewController.navigationController.navigationBar.layer removeObserver:self forKeyPath:@"bounds" context:NULL];
    [self.parentViewController.navigationController.navigationBar removeObserver:self forKeyPath:@"frame" context:NULL];
    [self.parentViewController.navigationController.navigationBar removeObserver:self forKeyPath:@"bounds" context:NULL];
}

- (void)didReceiveNotification:(NSNotification *)note
{
    NSString *name = note.name;
    
    if ([name isEqualToString:UIApplicationWillChangeStatusBarOrientationNotification] &&
        self.needRotateSelf) {
        // iOS8未満では、UIWindowが回転しないため、自分自身を回転させる必要がある
        UIInterfaceOrientation newOrientation = [note.userInfo[UIApplicationStatusBarOrientationUserInfoKey] integerValue];
        [self layoutSelfWithOrientation:newOrientation];
    }
    
    if ([name isEqualToString:UIApplicationWillChangeStatusBarFrameNotification] ||
        [name isEqualToString:UIApplicationDidChangeStatusBarFrameNotification] ||
        [name isEqualToString:UIApplicationWillChangeStatusBarOrientationNotification] ||
        [name isEqualToString:UIApplicationDidChangeStatusBarOrientationNotification]) {
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews
{
    NSLog(@"----- layoutSubviews -----");
    [super layoutSubviews];
    
    [self layoutSelfWithOrientation:UIInterfaceOrientationUnknown];
    [self layoutInnerView];
    NSLog(@"----------");
}

- (void)close
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeFromSuperview];
    
    id<DOPopupViewDelegate> delegate = self.delegate;
    if (delegate &&
        [delegate conformsToProtocol:@protocol(DOPopupViewDelegate)] &&
        [delegate respondsToSelector:@selector(popup:didCloseWithReason:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate popup:self didCloseWithReason:DOPopupViewCloseReasonCalledCloseMethod];
        });
    }
}

+ (void)closeAllPopup
{
    [self closeWithTag:nil];
}

+ (void)closeWithTag:(NSString *)tag
{
    NSDictionary *dict = [s_popup mutableCopy];
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString *t, NSMutableArray *a, BOOL *stop) {
        NSArray *array = [a mutableCopy];
        [array enumerateObjectsUsingBlock:^(DOWeakObject *w, NSUInteger idx, BOOL *stop) {
            if (!w.obj) {
                // すでに無いので、削除する
                [a removeObject:w];
                return;
            }
            
            if (tag == nil || [tag isEqualToString:t]) {
                [(DOPopupView *)w.obj close];
            }
        }];
    }];
}

- (void)setFrame:(CGRect)frame
{
    NSLog(@"----- setFrame -----");
    NSLog(@"Popup Frame: %@", NSStringFromCGRect(frame));
    [super setFrame:frame];
    NSLog(@"----------");
}

- (void)setBounds:(CGRect)bounds
{
    NSLog(@"----- setBounds -----");
    NSLog(@"Popup Bounds: %@", NSStringFromCGRect(bounds));
    [super setBounds:bounds];
    NSLog(@"----------");
}

@end
