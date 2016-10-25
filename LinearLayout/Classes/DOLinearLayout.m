//
//  DOLinearLayout.m
//  DOViewLayout
//
//  Created by kura on 2015/10/10.
//  Copyright © 2015年 kura. All rights reserved.
//

#import "DOLinearLayout.h"
#import "UIView+DOAccessor.h"
#import <objc/runtime.h>
#import "DOLayoutUtil.h"

// 継続的で頻繁なレイアウト処理はassertする
#define ASSERT_FREQUENT_LAYOUT_INTERVAL     3
#define ASSERT_FREQUENT_LAYOUT_COUNT        300

@interface DOLinearLayoutParam ()

@property (nonatomic, weak, nullable) UIView *view;

@property (nonatomic, nullable) NSString *absolutePositionString;
@property (nonatomic, nullable) NSString *relativePositionString;
@property (nonatomic, nullable) NSString *relativeMarginString;
@property (nonatomic, weak, nullable) UIView *relativeView;

@end

@implementation DOLinearLayoutParam

+ (nonnull instancetype)paramWithWidth:(CGFloat)w widthParam:(UIViewLayoutParam)wp height:(CGFloat)h heightParam:(UIViewLayoutParam)hp
{
    DOLinearLayoutParam *ret = [[DOLinearLayoutParam alloc] init];
    
    ret.width = w;
    ret.widthParam = wp;
    ret.height = h;
    ret.heightParam = hp;
    
    return ret;
}

+ (nonnull instancetype)paramWithWidth:(CGFloat)w height:(CGFloat)h
{
    return [self.class paramWithWidth:w widthParam:UIViewLayoutParamMatchParent height:h heightParam:UIViewLayoutParamMatchParent];
}

+ (nonnull instancetype)paramMatchParent
{
    return [self.class paramWithWidth:0 widthParam:UIViewLayoutParamMatchParent height:0 heightParam:UIViewLayoutParamMatchParent];
}

+ (nonnull instancetype)paramWrapContent
{
    return [self.class paramWithWidth:0 widthParam:UIViewLayoutParamWrapContent height:0 heightParam:UIViewLayoutParamWrapContent];
}

+ (nonnull instancetype)paramAbsolutePosition:(CGPoint)position
{
    DOLinearLayoutParam *p = [self.class paramWrapContent];
    p.isIgnoredFromLinearLayout = YES;
    p.absolutePositionString = NSStringFromCGPoint(position);
    return p;
}

+ (nonnull instancetype)paramSamePositionToView:(nonnull UIView *)view
{
    return [self.class paramRelativePosition:CGPointZero toView:view];
}

+ (nonnull instancetype)paramRelativePosition:(CGPoint)position toView:(nonnull UIView *)view
{
    return [self.class paramRelativePosition:CGPointZero toView:view margin:UIEdgeInsetsZero];
}

+ (nonnull instancetype)paramRelativePosition:(CGPoint)position toView:(nonnull UIView *)view margin:(UIEdgeInsets)margin
{
    DOLinearLayoutParam *p = [self.class paramWrapContent];
    p.isIgnoredFromLinearLayout = YES;
    p.relativePositionString = NSStringFromCGPoint(position);
    p.relativeView = view;
    p.relativeMarginString = NSStringFromUIEdgeInsets(margin);
    return p;
}

- (BOOL)hasAbsolutePosition
{
    return (self.absolutePositionString.length);
}

- (BOOL)hasRelativePosition
{
    return (self.relativePositionString.length);
}

- (CGPoint)absolutePosition
{
    if (self.absolutePositionString.length) {
        return CGPointFromString(self.absolutePositionString);
    } else {
        return CGPointZero;
    }
}

- (CGPoint)relativePosition
{
    if (self.relativePositionString.length) {
        return CGPointFromString(self.relativePositionString);
    } else {
        return CGPointZero;
    }
}

- (UIEdgeInsets)relativeMargin
{
    if (self.relativeMarginString.length) {
        return UIEdgeInsetsFromString(self.relativeMarginString);
    } else {
        return UIEdgeInsetsZero;
    }
}

- (void)setWeight:(CGFloat)weight
{
    _weight = weight;
    [self.view setNeedsLayout];
}

- (void)setMargin:(UIEdgeInsets)margin
{
    _margin = margin;
    [self.view setNeedsLayout];
}

- (void)setVisibility:(UIViewVisibility)visibility
{
    _visibility = visibility;
    [self.view setNeedsLayout];
}

- (void)setContentSize:(CGSize)contentSize
{
    _contentSize = contentSize;
    [self.view setNeedsLayout];
}

- (void)setWidth:(CGFloat)width
{
    _width = width;
    [self.view setNeedsLayout];
}

- (void)setWidthParam:(UIViewLayoutParam)widthParam
{
    _widthParam = widthParam;
    [self.view setNeedsLayout];
}

- (void)setHeight:(CGFloat)height
{
    _height = height;
    [self.view setNeedsLayout];
}

- (void)setHeightParam:(UIViewLayoutParam)heightParam
{
    _heightParam = heightParam;
    [self.view setNeedsLayout];
}

- (BOOL)isHeightMatchParent
{
    return self.height == 0 && self.heightParam == UIViewLayoutParamMatchParent;
}

- (BOOL)isWidthMatchParent
{
    return self.width == 0 && self.widthParam == UIViewLayoutParamMatchParent;
}

- (BOOL)isMatchParentWithOrientation:(DOLinearLayoutOrientation)orientation
{
    if (orientation == DOLinearLayoutOrientationHorizontal) {
        return [self isWidthMatchParent];
    } else {
        return [self isHeightMatchParent];
    }
}

@end

@implementation UIView (DOLinearLayout)

- (void)setDo_isIgnoredFromLinearLayout:(BOOL)do_isIgnoredFromLinearLayout
{
    [self do_layoutParam].isIgnoredFromLinearLayout = do_isIgnoredFromLinearLayout;
}

- (BOOL)do_isIgnoredFromLinearLayout
{
    return [self do_layoutParam].isIgnoredFromLinearLayout;
}

- (void)setDo_weight:(CGFloat)do_weight
{
    objc_setAssociatedObject(self, @selector(do_weight), @(do_weight), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self do_layoutParam].weight = do_weight;
    
    [DOLayoutUtil setNeedsLayoutToSuperview:self];
}

- (CGFloat)do_weight
{
    return [self do_layoutParam].weight;
}

- (void)setDo_layoutParam:(nonnull DOLinearLayoutParam *)do_layoutParam
{
    NSInteger viewTag = [objc_getAssociatedObject(self, @selector(do_layoutParam)) viewTag];
    
    if (do_layoutParam == nil) {
        do_layoutParam = [DOLinearLayoutParam paramMatchParent];
    }
    objc_setAssociatedObject(self, @selector(do_layoutParam), do_layoutParam, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    CGFloat weight = [objc_getAssociatedObject(self, @selector(do_weight)) doubleValue];
    if (weight) {
        // UIView.do_weightに設定されていたものを残す
        do_layoutParam.weight = weight;
    }
    UIEdgeInsets margin = UIEdgeInsetsFromString(objc_getAssociatedObject(self, @selector(do_layoutMargin)));
    if (!UIEdgeInsetsEqualToEdgeInsets(margin, UIEdgeInsetsZero)) {
        // UIView.do_layoutMarginに設定されていたものを残す
        do_layoutParam.margin = margin;
    }
    UIViewVisibility visibility = [objc_getAssociatedObject(self, @selector(do_visibility)) intValue];
    if (visibility != UIViewVisibilityVisible) {
        // UIView.do_layoutMarginに設定されていたものを残す
        do_layoutParam.visibility = visibility;
    }
    if (viewTag) {
        // UIView.tagに設定されていたものを残す
        do_layoutParam.viewTag = viewTag;
    }
    
    do_layoutParam.view = self.superview;
    
    [DOLayoutUtil setNeedsLayoutToSuperview:self];
}

- (nonnull DOLinearLayoutParam *)do_layoutParam
{
    DOLinearLayoutParam *p = objc_getAssociatedObject(self, @selector(do_layoutParam));
    if (p == nil) {
        [self setDo_layoutParam:[DOLinearLayoutParam paramMatchParent]];
        p = self.do_layoutParam;
    }
    return p;
}

- (void)setDo_layoutParamWidth:(CGFloat)do_layoutParamWidth
{
    [self do_layoutParam].width = do_layoutParamWidth;
}

- (CGFloat)do_layoutParamWidth
{
    return [self do_layoutParam].width;
}

- (void)setDo_layoutParamWidthIsWrapContent:(BOOL)do_layoutParamWidthIsWrapContent
{
    UIViewLayoutParam p = (do_layoutParamWidthIsWrapContent) ? UIViewLayoutParamWrapContent : UIViewLayoutParamMatchParent;
    [self do_layoutParam].widthParam = p;
}

- (BOOL)do_layoutParamWidthIsWrapContent
{
    return [self do_layoutParam].widthParam == UIViewLayoutParamWrapContent;
}

- (void)setDo_layoutParamHeight:(CGFloat)do_layoutParamHeight
{
    [self do_layoutParam].height = do_layoutParamHeight;
}

- (CGFloat)do_layoutParamHeight
{
    return [self do_layoutParam].height;
}

- (void)setDo_layoutParamHeightIsWrapContent:(BOOL)do_layoutParamHeightIsWrapContent
{
    UIViewLayoutParam p = (do_layoutParamHeightIsWrapContent) ? UIViewLayoutParamWrapContent : UIViewLayoutParamMatchParent;
    [self do_layoutParam].heightParam = p;
}

- (BOOL)do_layoutParamHeightIsWrapContent
{
    return [self do_layoutParam].heightParam == UIViewLayoutParamWrapContent;
}

- (void)setDo_layoutMargin:(UIEdgeInsets)do_layoutMargin
{
    objc_setAssociatedObject(self, @selector(do_layoutMargin), NSStringFromUIEdgeInsets(do_layoutMargin), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self do_layoutParam].margin = do_layoutMargin;
    
    [DOLayoutUtil setNeedsLayoutToSuperview:self];
}

- (UIEdgeInsets)do_layoutMargin
{
    return [self do_layoutParam].margin;
}

- (CGFloat)do_layoutMarginTop
{
    return [self do_layoutMargin].top;
}

- (void)setDo_layoutMarginTop:(CGFloat)do_layoutMarginTop
{
    UIEdgeInsets edgeInsets = [self do_layoutMargin];
    edgeInsets.top = do_layoutMarginTop;
    [self setDo_layoutMargin:edgeInsets];
}

- (CGFloat)do_layoutMarginLeft
{
    return [self do_layoutMargin].left;
}

- (void)setDo_layoutMarginLeft:(CGFloat)do_layoutMarginLeft
{
    UIEdgeInsets edgeInsets = [self do_layoutMargin];
    edgeInsets.left = do_layoutMarginLeft;
    [self setDo_layoutMargin:edgeInsets];
}

- (CGFloat)do_layoutMarginBottom
{
    return [self do_layoutMargin].bottom;
}

- (void)setDo_layoutMarginBottom:(CGFloat)do_layoutMarginBottom
{
    UIEdgeInsets edgeInsets = [self do_layoutMargin];
    edgeInsets.bottom = do_layoutMarginBottom;
    [self setDo_layoutMargin:edgeInsets];
}

- (CGFloat)do_layoutMarginRight
{
    return [self do_layoutMargin].right;
}

- (void)setDo_layoutMarginRight:(CGFloat)do_layoutMarginRight
{
    UIEdgeInsets edgeInsets = [self do_layoutMargin];
    edgeInsets.right = do_layoutMarginRight;
    [self setDo_layoutMargin:edgeInsets];
}

- (void)setDo_visibility:(UIViewVisibility)do_visibility
{
    objc_setAssociatedObject(self, @selector(do_visibility), @(do_visibility), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self do_layoutParam].visibility = do_visibility;
    
    [DOLayoutUtil setNeedsLayoutToSuperview:self];
}

- (UIViewVisibility)do_visibility
{
    return [self do_layoutParam].visibility;
}

- (void)setDo_contentSize:(CGSize)do_contentSize
{
    objc_setAssociatedObject(self, @selector(do_contentSize), NSStringFromCGSize(do_contentSize), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self do_layoutParam].contentSize = do_contentSize;
    
    [DOLayoutUtil setNeedsLayoutToSuperview:self];
}

- (CGSize)do_contentSize
{
    CGSize (^applyLayoutMarginBlock)(UIView * __nonnull v, CGSize size) = ^(UIView * __nonnull v, CGSize size) {
        UIEdgeInsets margin = [v do_layoutMargin];
        if (UIEdgeInsetsEqualToEdgeInsets(margin, UIEdgeInsetsZero)) {
            return size;
        }
        
        CGFloat w = size.width;
        CGFloat h = size.height;
        
        if (![v isWidthMatchParent]) {
            w += margin.right + margin.left;
        }
        if (![v isHeightMatchParent]) {
            h += margin.top + margin.bottom;
        }
        
        return CGSizeMake(w, h);
    };
    
    id contentSize = objc_getAssociatedObject(self, @selector(do_contentSize));
    if (contentSize) {
        return CGSizeFromString(contentSize);
    }
    
    DOLinearLayoutParam *lp = [self do_layoutParam];
    CGFloat w = lp.width, h = lp.height;
    CGSize limit = CGSizeMake(w, h);
    if (lp && (w != 0 && h != 0)) {
        if ([self isKindOfClass:[UIImageView class]] && ((UIImageView *)self).do_aspectKeep) {
            return applyLayoutMarginBlock(self, [DOLayoutUtil contentSize:self limitSize:limit]);
        } else {
            return CGSizeMake(w, h);
        }
    }
    
    limit = CGSizeMake(w, h);
    if (limit.width == 0) {
        if ([self isWidthMatchParent]) {
            UIEdgeInsets margin = self.do_layoutMargin;
            limit.width = self.superview.do_width - (margin.right + margin.left);
        } else {
            limit.width = INT_MAX;
        }
    }
    if (limit.height == 0) {
        if ([self isHeightMatchParent]) {
            UIEdgeInsets margin = self.do_layoutMargin;
            limit.height = self.superview.do_height - (margin.top + margin.bottom);
        } else {
            limit.height = INT_MAX;
        }
    }
    CGSize s = applyLayoutMarginBlock(self, [DOLayoutUtil contentSize:self limitSize:limit]);
    if (s.width != 0 && w == 0) {
        w = s.width;
    }
    if (s.height != 0 && h == 0) {
        h = s.height;
    }
    if (w != 0 && h != 0) {
        return CGSizeMake(w, h);
    }
    
    NSLayoutConstraintArray *constraints = [self constraints];
    for (NSLayoutConstraint *lc in constraints) {
        if (lc.firstAttribute == NSLayoutAttributeWidth) {
            if (w == 0) {
                w = lc.constant;
            }
        }
        if (lc.firstAttribute == NSLayoutAttributeHeight) {
            if (h == 0) {
                h = lc.constant;
            }
        }
    }
    if (w != 0 && h != 0) {
        return CGSizeMake(w, h);
    }
    
    return CGSizeMake(w, h);
}

- (BOOL)isHeightMatchParent
{
    return self.do_layoutParam == nil || [self.do_layoutParam isHeightMatchParent];
}

- (BOOL)isWidthMatchParent
{
    return self.do_layoutParam == nil || [self.do_layoutParam isWidthMatchParent];
}

- (BOOL)isMatchParentWithOrientation:(DOLinearLayoutOrientation)orientation
{
    if (orientation == DOLinearLayoutOrientationHorizontal) {
        return [self isWidthMatchParent];
    } else {
        return [self isHeightMatchParent];
    }
}

@end

@implementation UIImageView (DOLinearLayout)

- (void)setDo_aspectKeep:(BOOL)do_aspectKeep
{
    objc_setAssociatedObject(self, @selector(do_aspectKeep), @(do_aspectKeep), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [DOLayoutUtil setNeedsLayoutToSuperview:self];
}

- (BOOL)do_aspectKeep
{
    return [objc_getAssociatedObject(self, @selector(do_aspectKeep)) boolValue];
}

@end

@interface DOLinearLayout ()

@property (nonatomic) CGSize prevSize;

@property (nonatomic) NSTimeInterval prevTimeOfLayout;
@property (nonatomic) int countOfLayoutAtInterval;

@end

@interface UIView (DOLinearLayoutable_Private)

- (void)layoutSubviews_DOLinearLayout;
- (void)didAddSubview_DOLinearLayout:(nonnull UIView *)subview;
- (void)willRemoveSubview_DOLinearLayout:(nonnull UIView *)subview;
- (void)setNeedsLayout_DOLinearLayout;
- (void)setDo_size_DOLinearLayout:(CGSize)do_size;
- (void)setTag_DOLinearLayout:(NSInteger)tag;

@end

@implementation DOLinearLayout

+ (void)load
{
    [super load];
    [DOLinearLayout prepareLinearLayoutable];
}

static BOOL preparedLinearLayoutable;
+ (void)prepareLinearLayoutable
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method fromMethod;
        Method toMethod;
        
        fromMethod = class_getInstanceMethod([UIView class], @selector(layoutSubviews));
        toMethod = class_getInstanceMethod([UIView class], @selector(layoutSubviews_DOLinearLayout));
        method_exchangeImplementations(fromMethod, toMethod);
        
        fromMethod = class_getInstanceMethod([UIView class], @selector(didAddSubview:));
        toMethod = class_getInstanceMethod([UIView class], @selector(didAddSubview_DOLinearLayout:));
        method_exchangeImplementations(fromMethod, toMethod);
        
        fromMethod = class_getInstanceMethod([UIView class], @selector(willRemoveSubview:));
        toMethod = class_getInstanceMethod([UIView class], @selector(willRemoveSubview_DOLinearLayout:));
        method_exchangeImplementations(fromMethod, toMethod);
        
        fromMethod = class_getInstanceMethod([UIView class], @selector(setNeedsLayout));
        toMethod = class_getInstanceMethod([UIView class], @selector(setNeedsLayout_DOLinearLayout));
        method_exchangeImplementations(fromMethod, toMethod);
        
        fromMethod = class_getInstanceMethod([UIView class], @selector(setDo_size:));
        toMethod = class_getInstanceMethod([UIView class], @selector(setDo_size_DOLinearLayout:));
        method_exchangeImplementations(fromMethod, toMethod);
        
        fromMethod = class_getInstanceMethod([UIView class], @selector(setTag:));
        toMethod = class_getInstanceMethod([UIView class], @selector(setTag_DOLinearLayout:));
        method_exchangeImplementations(fromMethod, toMethod);
        
        preparedLinearLayoutable = YES;
    });
}

- (nullable UIScrollView *)scrollView
{
    return [DOLayoutUtil scrollViewWithSubviews:self.subviews];
}

- (instancetype)initWithCoder:(nonnull NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        for (UIView *v in self.subviews) {
            // DOLinearLayoutのAutoLayoutを解除する
            if ([v isKindOfClass:[DOLinearLayout class]]) {
                v.translatesAutoresizingMaskIntoConstraints = YES;
            }
        }
        
        [self convertConstraintToLayoutParam];
    }
    return self;
}

+ (BOOL)requiresConstraintBasedLayout
{
    return NO;
}

- (CGSize)intrinsicContentSize
{
    CGSize intrinsicContentSize = [self do_contentSize];
    
    for (DOLinearLayoutParam *p in self.subviewsLinearLayoutParams) {
        if (p.isIgnoredFromLinearLayout) {
            continue;
        }
        
        if ([p isWidthMatchParent]) {
            intrinsicContentSize.width = UIViewNoIntrinsicMetric;
            
            if (intrinsicContentSize.height == UIViewNoIntrinsicMetric) {
                break;
            }
        }
        if ([p isHeightMatchParent]) {
            intrinsicContentSize.height = UIViewNoIntrinsicMetric;
            
            if (intrinsicContentSize.width == UIViewNoIntrinsicMetric) {
                break;
            }
        }
    }
    
    return intrinsicContentSize;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    DOLinearLayoutSubviewsParam *param = [[DOLinearLayoutSubviewsParam alloc] init];
    param.orientation = self.layoutOrientation;
    param.gravity = self.layoutGravity;
    param.autoLineBreak = self.enableAutoLineBreak;
    param.dryRun = YES;
    NSViewArray *subviews = self.subviews;
    NSArray *subviewsLinearLayoutParams = self.subviewsLinearLayoutParams;
    CGSize sizeThatFits = [DOLayoutUtil layoutSubviews:subviews linearLayoutParams:subviewsLinearLayoutParams inView:view offset:CGPointZero param:param];
    return sizeThatFits;
}

- (void)addConstraint:(nonnull NSLayoutConstraint *)constraint
{
    if ([constraint isKindOfClass:NSClassFromString(@"NSIBPrototypingLayoutConstraint")]) {
        // InterfaceBuilderで自動で設定される制約は無視する
        return;
    }
    if (![constraint isMemberOfClass:[NSLayoutConstraint class]]) {
        if ([constraint isKindOfClass:NSClassFromString(@"NSContentSizeLayoutConstraint")] && ![self.superview isKindOfClass:[DOLinearLayout class]]) {
            // superviewがDOLinearLayoutではない場合、intrinsicContentSizeによって自動で設定される制約は有効とする
        } else {
            return;
        }
    }
    
    [super addConstraint:constraint];
}

- (void)removeConstraint:(nonnull NSLayoutConstraint *)constraint
{
    if (![constraint isMemberOfClass:[NSLayoutConstraint class]]) {
        return;
    }
    
    [super removeConstraint:constraint];
}

- (void)setLayoutOrientation:(DOLinearLayoutOrientation)layoutOrientation
{
    _layoutOrientation = layoutOrientation;
    
    if (layoutOrientation == DOLinearLayoutOrientationHorizontal) {
        if (self.layoutGravity == DOLinearLayoutGravityLeft) {
            self.layoutGravity = DOLinearLayoutGravityTop;
        }
        if (self.layoutGravity == DOLinearLayoutGravityRight) {
            self.layoutGravity = DOLinearLayoutGravityBottom;
        }
    } else if (layoutOrientation == DOLinearLayoutOrientationVertical) {
        if (self.layoutGravity == DOLinearLayoutGravityTop) {
            self.layoutGravity = DOLinearLayoutGravityLeft;
        }
        if (self.layoutGravity == DOLinearLayoutGravityBottom) {
            self.layoutGravity = DOLinearLayoutGravityRight;
        }
    }
    
    [DOLayoutUtil setNeedsLayout:self];
}

- (void)setLayoutGravity:(DOLinearLayoutGravity)layoutGravity
{
    _layoutGravity = layoutGravity;
    
    if (layoutGravity == DOLinearLayoutGravityLeft) {
        if (self.layoutOrientation == DOLinearLayoutOrientationHorizontal) {
            self.layoutGravity = DOLinearLayoutGravityTop;
        }
    } else if (layoutGravity == DOLinearLayoutGravityRight) {
        if (self.layoutOrientation == DOLinearLayoutOrientationHorizontal) {
            self.layoutGravity = DOLinearLayoutGravityBottom;
        }
    } else if (layoutGravity == DOLinearLayoutGravityTop) {
        if (self.layoutOrientation == DOLinearLayoutOrientationVertical) {
            self.layoutGravity = DOLinearLayoutGravityLeft;
        }
    } else if (layoutGravity == DOLinearLayoutGravityBottom) {
        if (self.layoutOrientation == DOLinearLayoutOrientationVertical) {
            self.layoutGravity = DOLinearLayoutGravityRight;
        }
    }
    
    [DOLayoutUtil setNeedsLayout:self];
}

- (UIView *)viewWithTag:(NSInteger)tag
{
    UIView *v = [super viewWithTag:tag];
    if (v == nil) {
        v = [DOLayoutUtil viewWithTag:tag inLinearLayout:self];
    }
    return v;
}

- (void)addSubview:(nonnull UIView *)view
{
    [super addSubview:view];
}

- (void)layoutLinearLayoutSubviews:(nonnull NSViewArray *)subviews linearLayoutParams:(nonnull NSArray *)linearLayoutParams
{
    DOLinearLayoutSubviewsParam *param = [[DOLinearLayoutSubviewsParam alloc] init];
    param.orientation = self.layoutOrientation;
    param.gravity = self.layoutGravity;
    param.autoLineBreak = self.enableAutoLineBreak;
    param.dryRun = NO;
    [DOLayoutUtil layoutSubviews:subviews linearLayoutParams:linearLayoutParams inView:self offset:CGPointZero param:param];
}

/**
 * AutoLayoutの制約からDOLinearLayoutParamを設定する
 */
- (void)convertConstraintToLayoutParam
{
    NSViewArray *subviews = self.subviews;
    for (UIView *v in subviews) {
        NSLayoutConstraintArray *constraints = [v constraints];
        BOOL hasWidthConstraint = NO;
        BOOL hasHeightConstraint = NO;
        for (NSLayoutConstraint *lc in constraints) {
            if ([lc isKindOfClass:NSClassFromString(@"NSIBPrototypingLayoutConstraint")]) {
                // InterfaceBuilderで自動で設定される制約は無視する
                [v removeConstraint:lc];
                continue;
            }
            
            if (lc.firstAttribute == NSLayoutAttributeWidth) {
                hasWidthConstraint = YES;
                
                if (v.do_layoutParam == nil) {
                    v.do_layoutParam = [DOLinearLayoutParam paramMatchParent];
                }
                v.do_layoutParam.width = lc.constant;
                v.do_layoutParam.widthParam = UIViewLayoutParamWrapContent;
            }
            if (lc.firstAttribute == NSLayoutAttributeHeight) {
                hasHeightConstraint = YES;
                
                if (v.do_layoutParam == nil) {
                    v.do_layoutParam = [DOLinearLayoutParam paramMatchParent];
                }
                v.do_layoutParam.height = lc.constant;
                v.do_layoutParam.heightParam = UIViewLayoutParamWrapContent;
            }
            
            if ((lc.firstAttribute == NSLayoutAttributeWidth) ||
                (lc.firstAttribute == NSLayoutAttributeHeight)) {
                // 幅、高さの制約は削除
                [v removeConstraint:lc];
            }
            if ((lc.firstItem == self && [subviews containsObject:lc.secondItem]) ||
                (lc.secondItem == self && [subviews containsObject:lc.firstItem])) {
                // selfとsubviewの制約は削除
                [v removeConstraint:lc];
            }
        }
    }
}

@end

@implementation UIView (DOLinearLayoutable)

- (void)setDo_enableLinearLayout:(BOOL)do_enableLinearLayout
{
    objc_setAssociatedObject(self, @selector(do_enableLinearLayout), @(do_enableLinearLayout), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [DOLayoutUtil setNeedsLayoutToSuperview:self];
}

- (BOOL)do_enableLinearLayout
{
    return [objc_getAssociatedObject(self, @selector(do_enableLinearLayout)) boolValue];
}

- (void)setDo_size_DOLinearLayout:(CGSize)do_size
{
    [self setDo_size_DOLinearLayout:do_size];
    
    if (TESTING) {
        [self setNeedsLayout];
    }
}

- (void)setTag_DOLinearLayout:(NSInteger)tag
{
    [self setTag_DOLinearLayout:tag];
    
    self.do_layoutParam.viewTag = tag;
}

- (void)layoutSubviews_DOLinearLayout
{
    [self layoutSubviews_DOLinearLayout];
    
    if ([self isKindOfClass:[DOLinearLayout class]]) {
        [(DOLinearLayout *)self layoutLinearLayoutSubviews:self.subviews linearLayoutParams:self.subviewsLinearLayoutParams];
        [DOLayoutUtil setSubviewsInLinearLayout:((DOLinearLayout *)self).scrollView];
        
        CGSize size = self.do_size;
        if (!CGSizeEqualToSize([(DOLinearLayout *)self prevSize], size)) {
            [self invalidateIntrinsicContentSize];
            
            DOLinearLayoutDidChangeSizeBlock didChangeSizeBlock = [(DOLinearLayout *)self didChangeSizeBlock];
            if (didChangeSizeBlock) {
                didChangeSizeBlock((DOLinearLayout *)self, size);
            }
            
            [(DOLinearLayout *)self setPrevSize:size];
        }
        
#if ASSERT_FREQUENT_LAYOUT_INTERVAL > 0 && ASSERT_FREQUENT_LAYOUT_COUNT > 0
        // 継続的で頻繁なレイアウト処理はassertする
        NSTimeInterval t = [NSDate timeIntervalSinceReferenceDate];
        NSTimeInterval d = t - ((DOLinearLayout *)self).prevTimeOfLayout;
        if (d > 0 && d <= ASSERT_FREQUENT_LAYOUT_INTERVAL) {
            ((DOLinearLayout *)self).countOfLayoutAtInterval++;
            NSAssert(((DOLinearLayout *)self).countOfLayoutAtInterval <= ASSERT_FREQUENT_LAYOUT_COUNT, @"ASSERT_FREQUENT_LAYOUT");
        } else {
            ((DOLinearLayout *)self).countOfLayoutAtInterval = 0;
            ((DOLinearLayout *)self).prevTimeOfLayout = t;
        }
#endif
    } else if (self.do_enableLinearLayout) {
        DOLinearLayoutSubviewsParam *param = [[DOLinearLayoutSubviewsParam alloc] init];
        param.orientation = DOLinearLayoutOrientationHorizontal;
        param.gravity = DOLinearLayoutGravityCenter;
        param.autoLineBreak = NO;
        param.dryRun = NO;
        NSViewArray *subviews = self.subviews;
        NSArray *subviewsLinearLayoutParams = self.subviewsLinearLayoutParams;
        [DOLayoutUtil layoutSubviews:subviews linearLayoutParams:subviewsLinearLayoutParams inView:self offset:CGPointZero param:param];
    }
}

- (void)setNeedsLayout_DOLinearLayout
{
    [self setNeedsLayout_DOLinearLayout];
    
    if ([self isKindOfClass:[DOLinearLayout class]]) {
        [self invalidateIntrinsicContentSize];
        
        if (TESTING) {
            [(DOLinearLayout *)self layoutLinearLayoutSubviews:self.subviews linearLayoutParams:self.subviewsLinearLayoutParams];
        }
    } else if (self.do_enableLinearLayout) {
        if (TESTING) {
            DOLinearLayoutSubviewsParam *param = [[DOLinearLayoutSubviewsParam alloc] init];
            param.orientation = DOLinearLayoutOrientationHorizontal;
            param.gravity = DOLinearLayoutGravityCenter;
            param.autoLineBreak = NO;
            param.dryRun = NO;
            NSViewArray *subviews = self.subviews;
            NSArray *subviewsLinearLayoutParams = self.subviewsLinearLayoutParams;
            [DOLayoutUtil layoutSubviews:subviews linearLayoutParams:subviewsLinearLayoutParams inView:self offset:CGPointZero param:param];
        }
    }
}

- (void)didAddSubview_DOLinearLayout:(nonnull UIView *)subview
{
    [self didAddSubview_DOLinearLayout:subview];
    
    if ([self isKindOfClass:[DOLinearLayout class]]) {
        [self invalidateIntrinsicContentSize];
        
        if (TESTING) {
            [self setNeedsLayout];
        }
    } else if (self.do_enableLinearLayout) {
        if (TESTING) {
            [self setNeedsLayout];
        }
    }
}

- (void)willRemoveSubview_DOLinearLayout:(nonnull UIView *)subview
{
    [self willRemoveSubview_DOLinearLayout:subview];
    
    if ([self isKindOfClass:[DOLinearLayout class]]) {
        [self invalidateIntrinsicContentSize];
        
        if (TESTING) {
            NSMutableArray *t = [self.subviews mutableCopy];
            NSMutableArray *t2 = [self.subviewsLinearLayoutParams mutableCopy];
            if ([t indexOfObject:subview] != NSNotFound) {
                [t2 removeObjectAtIndex:[t indexOfObject:subview]];
            }
            [t removeObject:subview];
            [(DOLinearLayout *)self layoutLinearLayoutSubviews:t linearLayoutParams:t2];
        }
    } else if (self.do_enableLinearLayout) {
        if (TESTING) {
            NSMutableArray *t = [self.subviews mutableCopy];
            NSMutableArray *t2 = [self.subviewsLinearLayoutParams mutableCopy];
            if ([t indexOfObject:subview] != NSNotFound) {
                [t2 removeObjectAtIndex:[t indexOfObject:subview]];
            }
            [t removeObject:subview];
            DOLinearLayoutSubviewsParam *param = [[DOLinearLayoutSubviewsParam alloc] init];
            param.orientation = DOLinearLayoutOrientationHorizontal;
            param.gravity = DOLinearLayoutGravityCenter;
            param.autoLineBreak = NO;
            param.dryRun = NO;
            [DOLayoutUtil layoutSubviews:t linearLayoutParams:t2 inView:self offset:CGPointZero param:param];
        }
    }
}

- (nonnull NSArray *)subviewsLinearLayoutParams
{
    NSMutableArray *subviewsLinearLayoutParams = [@[] mutableCopy];
    
    __strong id<DOLinearLayoutDelegate> linearLayoutDelegate;
    if ([self isKindOfClass:[DOLinearLayout class]]) {
        linearLayoutDelegate = ((DOLinearLayout *)self).linearLayoutDelegate;
    }
    if (linearLayoutDelegate) {
        NSArray *tags = [linearLayoutDelegate tagsForContentViews];
        for (NSNumber *tag in tags) {
            DOLinearLayoutParam *p = [linearLayoutDelegate linearLayoutParamWithTag:[tag integerValue]];
            p.viewTag = [tag integerValue];
            [subviewsLinearLayoutParams addObject:p];
        }
    } else {
        [subviewsLinearLayoutParams addObjectsFromArray:[DOLayoutUtil subviewsLinearLayoutParamsWithSubviews:self.subviews]];
    }
    
    return subviewsLinearLayoutParams;
}

@end
