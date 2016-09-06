//
//  DOLayoutUtil.m
//  DOViewLayout
//
//  Created by kura on 2016/08/30.
//  Copyright © 2016年 kura. All rights reserved.
//

#import "DOLayoutUtil.h"
#import "UIView+DOAccessor.h"

#define ORIENTATION_VALUE(_orientation, _v1, _v2) ((_orientation == DOLinearLayoutOrientationHorizontal) ? (_v1) : (_v2))
#define FLAG_CHECK(_v, _f)  (((_v) & (_f)) == _f)

//#define DOLinearLayoutLog       NSLog
#define DOLinearLayoutLog(...)

@implementation DOLayoutSubviewsParam

- (instancetype)clone
{
    DOLayoutSubviewsParam *ret = [[self.class alloc] init];
    ret.dryRun = self.dryRun;
    return ret;
}

@end

@implementation DOLinearLayoutSubviewsParam

- (instancetype)clone
{
    DOLinearLayoutSubviewsParam *ret = [super clone];
    ret.orientation = self.orientation;
    ret.gravity = self.gravity;
    ret.autoLineBreak = self.autoLineBreak;
    return ret;
}

@end

@interface DOLinearLayoutScrollView : UIScrollView

@end

@implementation DOLinearLayoutScrollView

@end

@implementation DOLayoutUtil

/**
 * viewに対してsetNeedsLayoutする
 */
+ (void)setNeedsLayout:(UIView *)view
{
#if TARGET_INTERFACE_BUILDER
    return;
#endif
    [view invalidateIntrinsicContentSize];
    [view setNeedsLayout];
}

/**
 * superviewに対してsetNeedsLayoutする
 */
+ (void)setNeedsLayoutToSuperview:(UIView *)view
{
#if TARGET_INTERFACE_BUILDER
    return;
#endif
    [self.class setNeedsLayout:[self.class linearLayoutAsSuperview:view]];
}

/**
 * Viewのコンテンツサイズ
 */
+ (CGSize)contentSize:(UIView *)view limitSize:(CGSize)limitSize
{
    CGFloat w = 0, h = 0;
    
    if (view.do_isIgnoredFromLinearLayout) {
        return CGSizeZero;
    }
    if ([view isMemberOfClass:[UIView class]]) {
        // UIViewの場合、zeroを返すことにする
        return CGSizeZero;
    }
    if ([view isKindOfClass:[DOLinearLayout class]]) {
        // contentSizeが確定するものを加算する(wrap_contentは0として扱う)
        CGSize size = CGSizeZero;
        for (UIView *v in view.subviews) {
            if ([(DOLinearLayout *)view layoutOrientation] == DOLinearLayoutOrientationHorizontal) {
                if (![v.do_layoutParam isWidthMatchParent]) {
                    size.width += v.do_contentSize.width;
                }
                if (![v.do_layoutParam isHeightMatchParent]) {
                    if (size.height < v.do_contentSize.height) {
                        size.height = v.do_contentSize.height;
                    }
                }
            } else if ([(DOLinearLayout *)view layoutOrientation] == DOLinearLayoutOrientationVertical) {
                if (![v.do_layoutParam isWidthMatchParent]) {
                    if (size.width < v.do_contentSize.width) {
                        size.width = v.do_contentSize.width;
                    }
                }
                if (![v.do_layoutParam isHeightMatchParent]) {
                    size.height += v.do_contentSize.height;
                }
            }
        }
        return size;
    } else if (view.do_enableLinearLayout) {
        // contentSizeが確定するものを加算する(wrap_contentは0として扱う)
        CGSize size = CGSizeZero;
        for (UIView *v in view.subviews) {
            if (![v.do_layoutParam isWidthMatchParent]) {
                size.width += v.do_contentSize.width;
            }
            if (![v.do_layoutParam isHeightMatchParent]) {
                if (size.height < v.do_contentSize.height) {
                    size.height = v.do_contentSize.height;
                }
            }
        }
    }
    if ([view isKindOfClass:[UIImageView class]]) {
        // UIImageViewの場合、アスペクト比キープがあるため、自前で計算する
        UIImageView *iv = (UIImageView *)view;
        w = iv.image.size.width / iv.image.scale;
        h = iv.image.size.height / iv.image.scale;
        
        CGSize s = [self.class sizeFrom:CGSizeMake(w, h) limit:limitSize aspectKeep:iv.do_aspectKeep];
        w = s.width;
        h = s.height;
        return CGSizeMake(w, h);
    }
    if (![view isKindOfClass:[UIImageView class]]) {
        // UILabelとかUIButtonとか一般的なViewの場合はsizeThatFitsを使用する
        CGSize size = [view sizeThatFits:limitSize];
        if ([view isKindOfClass:[UILabel class]]) {
            // UILabelで少しでもサイズが小さいと「...」で省略されてしまうので、切り上がるように0.5足す
            if (![[view do_layoutParam] isWidthMatchParent]) {
                size.width += 0.5;
            }
            if (![[view do_layoutParam] isHeightMatchParent]) {
                size.height += 0.5;
            }
        }
        return size;
    }
    
    return CGSizeMake(w, h);
}

/**
 * fromをlimitに入りきるサイズに調整する
 */
+ (CGSize)sizeFrom:(CGSize)from limit:(CGSize)limit aspectKeep:(BOOL)aspectKeep
{
    if (aspectKeep) {
        CGFloat ratio = from.width / from.height;
        
        BOOL needResizeWidth = from.width > limit.width;
        BOOL needResizeHeight = from.height > limit.height;
        
        if (needResizeWidth && needResizeHeight) {
            if ((from.width - limit.width) > (from.height - limit.height)) {
                needResizeHeight = NO;
            } else {
                needResizeWidth = NO;
            }
        }
        
        if (needResizeWidth) {
            from.width = MIN(from.width, limit.width);
            from.height = from.width / ratio;
        }
        if (needResizeHeight) {
            from.height = MIN(from.height, limit.height);
            from.width = from.height * ratio;
        }
    } else {
        from.width = MIN(from.width, limit.width);
        from.height = MIN(from.height, limit.height);
    }
    return from;
}

/**
 * レイアウトする
 */
+ (CGSize)layoutSubviews:(NSViewArray *)subviews inView:(UIView *)view offset:(CGPoint)offset param:(DOLinearLayoutSubviewsParam *)param;
{
    DOLinearLayoutOrientation orientation = param.orientation;
    DOLinearLayoutGravity gravity = param.gravity;
    BOOL autoLineBreak = param.autoLineBreak;
    BOOL dryRun = param.dryRun;
    
    NSAssert(orientation == DOLinearLayoutOrientationHorizontal || orientation == DOLinearLayoutOrientationVertical, @"bad orientation");
    
    BOOL isLayoutingScrollView = NO;
    if ([self.class scrollViewWithSubviews:subviews]) {
        DOLinearLayoutScrollView *scrollView = [self.class scrollViewWithSubviews:subviews];
        isLayoutingScrollView = YES;
        scrollView.frame = view.bounds;
        subviews = scrollView.subviews;
    }
    
    NSUInteger countOfSubviews = subviews.count;
    
    // サイズ計算用に一度ループ
    CGFloat totalT = 0;
    CGFloat totalWeight = 0;
    for (UIView *v in subviews) {
        if (v.do_visibility == UIViewVisibilityGone || v.do_isIgnoredFromLinearLayout) {
            // なにもしない
        } else if ([v isMatchParentWithOrientation:orientation]) {
            // weightの加算
            totalWeight += v.do_weight;
        } else {
            // サイズを加算
            totalT += ORIENTATION_VALUE(orientation, v.do_contentSize.width, v.do_contentSize.height);
        }
    }
    
    // weightで分割したサイズを算出
    CGFloat remain = ORIENTATION_VALUE(orientation, view.do_width ,view.do_height) - totalT;
    if (remain < 0) {
        if (autoLineBreak) {
            // 入りきっていないので、改行する
            CGFloat total = 0;
            for (NSInteger i = 0, len = subviews.count; i < len ; i++) {
                UIView *v = subviews[i];
                if (v.do_visibility != UIViewVisibilityGone && !v.do_isIgnoredFromLinearLayout && ![v isMatchParentWithOrientation:orientation]) {
                    // サイズを加算
                    total += ORIENTATION_VALUE(orientation, v.do_contentSize.width, v.do_contentSize.height);
                }
                if (i > 0 && ORIENTATION_VALUE(orientation, view.do_width ,view.do_height) < total) {
                    // 親より大きくなったので、ここで改行する
                    CGRect orgFrame = view.frame;
                    if (orientation == DOLinearLayoutOrientationHorizontal) {
                        orgFrame.size = CGSizeMake(orgFrame.size.width, orgFrame.size.height / 2);
                    } else {
                        orgFrame.size = CGSizeMake(orgFrame.size.width / 2, orgFrame.size.height);
                    }
                    CGPoint offset = ORIENTATION_VALUE(orientation, CGPointMake(0, orgFrame.size.height), CGPointMake(orgFrame.size.width, 0));
                    NSViewArray *subarray1 = [subviews subarrayWithRange:NSMakeRange(0, i)];
                    NSViewArray *subarray2 = [subviews subarrayWithRange:NSMakeRange(i, len - i)];
                    UIView *subview1 = [[UIView alloc] initWithFrame:orgFrame];
                    UIView *subview2 = [[UIView alloc] initWithFrame:orgFrame];
                    DOLinearLayoutSubviewsParam *noAutoLineBreakParam = [param clone];
                    noAutoLineBreakParam.autoLineBreak = NO;
                    CGSize size1 = [self.class layoutSubviews:subarray1 inView:subview1 offset:CGPointZero param:noAutoLineBreakParam];
                    CGSize size2 = [self.class layoutSubviews:subarray2 inView:subview2 offset:offset param:noAutoLineBreakParam];
                    if (orientation == DOLinearLayoutOrientationHorizontal) {
                        CGFloat w = (size1.width > size2.width) ? size1.width : size2.width;
                        return CGSizeMake(w, size1.height + size2.height);
                    } else {
                        CGFloat h = (size1.height > size2.height) ? size1.height : size2.height;
                        return CGSizeMake(size1.width + size2.width, h);
                    }
                }
            }
            NSAssert(NO, @"");
        } else {
            remain = 0;
        }
    }
    CGFloat remainPerWeight = remain / totalWeight;
    
    // frameの更新判定のために、更新前のViewのframeを保持
    NSMutableArray *subviewsFrameStringArray = [@[] mutableCopy];
    for (UIView *v in subviews) {
        [subviewsFrameStringArray addObject:NSStringFromCGRect(v.frame)];
    }
    
    // Viewに座標を設定
    CGFloat position = 0;
    CGFloat maxSelfSize = 0;
    for (NSUInteger i = 0; i < countOfSubviews; i++) {
        if (subviews[i].do_isIgnoredFromLinearLayout) {
            continue;
        }
        
        CGRect frame = [self.class updateView:subviews[i]
                                  orientation:orientation
                                       parent:view
                                      gravity:gravity
                              remainPerWeight:remainPerWeight
                                     position:position
                                       offset:offset
                                       dryRun:dryRun];
        
        ORIENTATION_VALUE(orientation, position += frame.size.width, position += frame.size.height);
        
        // wrap_content対応
        if (orientation == DOLinearLayoutOrientationHorizontal) {
            if (maxSelfSize < frame.size.height) {
                maxSelfSize = frame.size.height;
            }
        } else if (orientation == DOLinearLayoutOrientationVertical) {
            if (maxSelfSize < frame.size.width) {
                maxSelfSize = frame.size.width;
            }
        }
    }
    
    CGSize selfSize = ORIENTATION_VALUE(orientation, CGSizeMake(position, maxSelfSize), CGSizeMake(maxSelfSize, position));
    if (dryRun) {
        return selfSize;
    }
    
    // おさまりきる場合のgravity反映
    CGPoint slide = [self.class positionWithPoint:CGPointZero gravity:gravity orientation:orientation parentSize:view.do_size selfSize:CGSizeMake(position, position)];
    NSInteger slideXInt = [self.class integerWithFloat:slide.x];
    NSInteger slideYInt = [self.class integerWithFloat:slide.y];
    if (position < ORIENTATION_VALUE(orientation, view.do_width, view.do_height))  {
        for (NSUInteger i = 0; i < countOfSubviews; i++) {
            if (subviews[i].do_isIgnoredFromLinearLayout) {
                continue;
            }
            
            ORIENTATION_VALUE(orientation, subviews[i].do_x += slideXInt, subviews[i].do_y += slideYInt);
        }
    }
    
    // 自分がwrapContentの場合、親の再レイアウトが必要な場合がある
    if (([self.class linearLayoutAsSuperview:view] || view.superview.do_enableLinearLayout) && (![view isWidthMatchParent] || ![view isHeightMatchParent])) {
        // 更新前後のViewのframeに違いがあれば、親を再レイアウトする
        for (NSInteger i = 0, len = subviews.count; i < len; i++) {
            if (![NSStringFromCGRect(subviews[i].frame) isEqualToString:subviewsFrameStringArray[i]]) {
                [DOLayoutUtil setNeedsLayoutToSuperview:view];
                break;
            }
        }
    }
    
    for (UIView *v in subviews) {
        if (!v.do_isIgnoredFromLinearLayout) {
            // なにもしない
        } else {
            [DOLayoutUtil layoutIgnoredView:v];
        }
    }
    
    if ([view isKindOfClass:[DOLinearLayout class]]) {
        DOLinearLayout *ll = (DOLinearLayout *)view;
        if (isLayoutingScrollView) {
            // ScrollViewから移動
            if (!ll.enableScroll || position <= ORIENTATION_VALUE(orientation, view.do_width, view.do_height)) {
                DOLinearLayoutScrollView *scrollView = [DOLayoutUtil scrollViewWithSubviews:view.subviews];
                for (UIView *v in scrollView.subviews) {
                    [view addSubview:v];
                }
                [scrollView removeFromSuperview];
            }
        } else {
            // ScrollViewに移動
            if (ll.enableScroll && position > ORIENTATION_VALUE(orientation, view.do_width, view.do_height)) {
                DOLinearLayoutScrollView *scrollView = [[DOLinearLayoutScrollView alloc] initWithFrame:view.bounds];
                scrollView.contentSize = ORIENTATION_VALUE(orientation, CGSizeMake(position, view.do_height), CGSizeMake(view.do_weight, position));
                for (UIView *v in subviews) {
                    [scrollView addSubview:v];
                }
                [view addSubview:scrollView];
            }
        }
    }
    
#if DEBUG
    DOLinearLayoutLog(@"%@", view);
    DOLinearLayoutLog(@"%@", subviews);
#endif
    return selfSize;
}

+ (CGRect)updateView:(UIView *)v
         orientation:(DOLinearLayoutOrientation)orientation
              parent:(UIView *)view
             gravity:(DOLinearLayoutGravity)gravity
     remainPerWeight:(CGFloat)remainPerWeight
            position:(CGFloat)p
              offset:(CGPoint)offset
              dryRun:(BOOL)dryRun
{
    // hiddenの設定
    if (!dryRun) {
        switch (v.do_visibility) {
            case UIViewVisibilityVisible:
                v.hidden = NO;
                break;
            case UIViewVisibilityInvisible:
            case UIViewVisibilityGone:
                v.hidden = YES;
                break;
        }
    }
    
    CGRect frame = CGRectZero;
    UIEdgeInsets margin = UIEdgeInsetsZero;
    
    // marginとframeの計算
    if (v.do_visibility == UIViewVisibilityGone) {
        margin = UIEdgeInsetsZero;
        frame = CGRectZero;
    } else if ([v isMatchParentWithOrientation:orientation]) {
        margin = v.do_layoutMargin;
        frame = [self.class frameForViewResizeWithView:v
                                           orientation:orientation
                                                parent:view
                                               gravity:gravity
                                                 weght:v.do_weight
                                       remainPerWeight:remainPerWeight];
    } else {
        margin = v.do_layoutMargin;
        frame = [self.class frameForViewNotResizeWithView:v
                                              orientation:orientation
                                                   parent:view
                                                  gravity:gravity];
    }
    
    // gravityの適用
    CGPoint gravityOffset = [self.class positionWithPoint:frame.origin
                                                  gravity:gravity
                                              orientation:orientation
                                               parentSize:view.do_size
                                                 selfSize:frame.size];
    
    // 座標を整数値に変換
    NSInteger xInt = [self.class integerWithFloat:p];
    NSInteger yInt = [self.class integerWithFloat:ORIENTATION_VALUE(orientation, gravityOffset.y, gravityOffset.x)];
    NSInteger hInt = [self.class integerWithFloat:ORIENTATION_VALUE(orientation, frame.size.height, frame.size.width)];
    NSInteger wInt;
    CGSize orgFrameSize = frame.size;
    CGFloat t = ORIENTATION_VALUE(orientation, frame.size.width, frame.size.height);
    if (v.do_visibility == UIViewVisibilityGone) {
        wInt = 0;
    } else {
        if ([v isMatchParentWithOrientation:orientation]) {
            wInt = [self.class integerWithFloat:p + t] - xInt;
        } else {
            wInt = [self.class integerWithFloat:t];
        }
    }
    
    // frameの計算とmarginの適用
    NSInteger offsetXInt = [self.class integerWithFloat:offset.x];
    NSInteger offsetYInt = [self.class integerWithFloat:offset.y];
    if (orientation == DOLinearLayoutOrientationHorizontal) {
        frame = CGRectMake(xInt + offsetXInt, yInt + offsetYInt, wInt, hInt);
    } else if (orientation == DOLinearLayoutOrientationVertical) {
        frame = CGRectMake(yInt + offsetXInt, xInt + offsetYInt, hInt, wInt);
    }
    frame = UIEdgeInsetsInsetRect(frame, margin);
    if (!dryRun) {
        v.frame = frame;
    }
    
    if (!dryRun && !CGRectEqualToRect(v.frame, frame)) {
        // 画面回転直後は、アニメーション中でframeの更新が上手くいかないようなので、再度レイアウトを促す
        dispatch_async(dispatch_get_main_queue(), ^{
            [DOLayoutUtil setNeedsLayoutToSuperview:v];
        });
    }
    
    return ORIENTATION_VALUE(orientation, CGRectMake(0, 0, t, orgFrameSize.height), CGRectMake(0, 0, orgFrameSize.width, t));
}

+ (CGRect)frameForViewNotResizeWithView:(UIView *)v
                            orientation:(DOLinearLayoutOrientation)orientation
                                 parent:(UIView *)view
                                gravity:(DOLinearLayoutGravity)gravity
{
    // 基本はcontentSize
    CGFloat x = 0;
    CGFloat y = 0;
    CGFloat w = v.do_contentSize.width;
    CGFloat h = v.do_contentSize.height;
    
    // match_parent対応
    if (orientation == DOLinearLayoutOrientationHorizontal && [v isMatchParentWithOrientation:DOLinearLayoutOrientationVertical]) {
        h = view.do_height;
    } else if (orientation == DOLinearLayoutOrientationVertical && [v isMatchParentWithOrientation:DOLinearLayoutOrientationHorizontal]) {
        w = view.do_width;
    }
    
    return CGRectMake(x, y, w, h);
}

+ (CGRect)frameForViewResizeWithView:(UIView *)v
                         orientation:(DOLinearLayoutOrientation)orientation
                              parent:(UIView *)view
                             gravity:(DOLinearLayoutGravity)gravity
                               weght:(CGFloat)weight
                     remainPerWeight:(CGFloat)remainPerWeight
{
    // 基本はparentSize
    CGFloat x = 0;
    CGFloat y = 0;
    CGSize parentSize = view.frame.size;
    CGFloat w = parentSize.width;
    CGFloat h = parentSize.height;
    
    // wrap_content対応
    if (orientation == DOLinearLayoutOrientationHorizontal && ![v isMatchParentWithOrientation:DOLinearLayoutOrientationVertical]) {
        h = v.do_contentSize.height;
    } else if (orientation == DOLinearLayoutOrientationVertical && ![v isMatchParentWithOrientation:DOLinearLayoutOrientationHorizontal]) {
        w = v.do_contentSize.width;
    }
    
    // weightの適用
    CGFloat t = weight * remainPerWeight;
    if (weight) {
        ORIENTATION_VALUE(orientation, w = t, h = t);
    } else {
        ORIENTATION_VALUE(orientation, w = 0, h = 0);
    }
    
    return CGRectMake(x, y, w, h);
}

/**
 * gravityの適用
 */
+ (CGPoint)positionWithPoint:(CGPoint)p
                     gravity:(DOLinearLayoutGravity)gravity
                 orientation:(DOLinearLayoutOrientation)orientation
                  parentSize:(CGSize)parentSize
                    selfSize:(CGSize)selfSize
{
    CGFloat x = p.x, y = p.y;
    
    BOOL isGravityCenter = FLAG_CHECK(gravity, DOLinearLayoutGravityCenter);
    BOOL needCentering = NO;
    if (isGravityCenter) {
        needCentering = YES;
    } else {
        needCentering |= (orientation == DOLinearLayoutOrientationHorizontal && FLAG_CHECK(gravity, DOLinearLayoutGravityCenterVertical));
        needCentering |= (orientation == DOLinearLayoutOrientationVertical && FLAG_CHECK(gravity, DOLinearLayoutGravityCenterHorizontal));
    }
    
    if (needCentering ||
        (orientation == DOLinearLayoutOrientationHorizontal && FLAG_CHECK(gravity, DOLinearLayoutGravityBottom)) ||
        (orientation == DOLinearLayoutOrientationVertical && FLAG_CHECK(gravity, DOLinearLayoutGravityRight))) {
        int centering = 1;
        if (needCentering) {
            centering = 2;
        }
        if (isGravityCenter || orientation == DOLinearLayoutOrientationHorizontal) {
            y = (parentSize.height - selfSize.height) / centering;
        }
        if (isGravityCenter || orientation == DOLinearLayoutOrientationVertical) {
            x = (parentSize.width - selfSize.width) / centering;
        }
    }
    
    return CGPointMake(x, y);
}

+ (void)layoutIgnoredView:(UIView *)view
{
    if (view.do_layoutParam.hasAbsolutePosition) {
        // 絶対位置
        view.do_origin = view.do_layoutParam.absolutePosition;
    } else if (view.do_layoutParam.hasRelativePosition) {
        // 相対位置
        CGRect frame = view.do_layoutParam.relativeView.frame;
        CGPoint offset = view.do_layoutParam.relativePosition;
        UIEdgeInsets margin = view.do_layoutParam.relativeMargin;
        frame.origin = CGPointMake(frame.origin.x + offset.x - margin.left, frame.origin.y + offset.y - margin.top);
        frame.size = CGSizeMake(frame.size.width + margin.left + margin.right, frame.size.height + margin.top + margin.bottom);
        view.frame = frame;
    }
}

+ (DOLinearLayoutScrollView *)scrollViewWithSubviews:(NSViewArray *)subviews
{
    if (subviews.count == 1 && [subviews[0] isKindOfClass:[DOLinearLayoutScrollView class]]) {
        return (DOLinearLayoutScrollView *)subviews[0];
    }
    return nil;
}

+ (DOLinearLayout *)linearLayoutAsSuperview:(UIView *)view
{
    UIView *superview = view.superview;
    if ([view isKindOfClass:[DOLinearLayout class]] && [superview isKindOfClass:[DOLinearLayoutScrollView class]]) {
        superview = superview.superview;
    }
    
    if ([superview isKindOfClass:[DOLinearLayout class]]) {
        return (DOLinearLayout *)superview;
    } else {
        return nil;
    }
}

/**
 * 四捨五入
 */
+ (NSInteger)integerWithFloat:(CGFloat)f
{
    return (NSInteger)(((long long)(f * 10LL) + ((f < 0) ? -5LL : 5LL)) / 10.0);
}

/**
 * テストかどうか
 */
+ (BOOL)isRunningTests
{
#if DEBUG
    static BOOL runningTests;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSDictionary* environment = [[NSProcessInfo processInfo] environment];
        NSString* injectBundle = environment[@"XCInjectBundle"];
        NSString* pathExtension = [injectBundle pathExtension];
        runningTests = ([pathExtension isEqualToString:@"octest"] ||
                        [pathExtension isEqualToString:@"xctest"]);
        runningTests |= (environment[@"XCInjectBundleInto"] != nil);
    });
    return runningTests;
#else
    return NO;
#endif
}

@end
