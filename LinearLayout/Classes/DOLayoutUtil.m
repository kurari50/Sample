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

- (nonnull instancetype)clone
{
    DOLayoutSubviewsParam *ret = [[self.class alloc] init];
    ret.dryRun = self.dryRun;
    return ret;
}

@end

@implementation DOLinearLayoutSubviewsParam

- (nonnull instancetype)clone
{
    DOLinearLayoutSubviewsParam *ret = [super clone];
    ret.orientation = self.orientation;
    ret.gravity = self.gravity;
    ret.autoLineBreak = self.autoLineBreak;
    return ret;
}

@end

@interface DOLinearLayoutScrollView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic) NSMutableArray *params;

@end

@implementation DOLinearLayoutScrollView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // subviewsにインジケーター用のUIImageViewが追加されるとレイアウトに影響するので、インジケーターは無しとする
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
    }
    return self;
}

- (void)setShowsHorizontalScrollIndicator:(BOOL)showsHorizontalScrollIndicator
{
    // subviewsにインジケーター用のUIImageViewが追加されるとレイアウトに影響するので、インジケーターは無しとする
    NSAssert(!showsHorizontalScrollIndicator, @"cant show scroll indicator");
    [super setShowsHorizontalScrollIndicator:showsHorizontalScrollIndicator];
}

- (void)setShowsVerticalScrollIndicator:(BOOL)showsVerticalScrollIndicator
{
    // subviewsにインジケーター用のUIImageViewが追加されるとレイアウトに影響するので、インジケーターは無しとする
    NSAssert(!showsVerticalScrollIndicator, @"cant show scroll indicator");
    [super setShowsVerticalScrollIndicator:showsVerticalScrollIndicator];
}

- (void)addParam:(nonnull DOLinearLayoutParam *)param
{
    if (self.params == nil) {
        self.params = [@[] mutableCopy];
    }
    
    [self.params addObject:param];
}

- (void)removeParam:(nonnull DOLinearLayoutParam *)param
{
    if (self.params == nil) {
        self.params = [@[] mutableCopy];
    }
    
    [self.params removeObject:param];
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated
{
    if (CGPointEqualToPoint(contentOffset, self.contentOffset)) {
        [self scrollViewDidScroll:self];
    }
    
    [super setContentOffset:contentOffset animated:animated];
}

- (void)setContentOffset:(CGPoint)contentOffset
{
    if (CGPointEqualToPoint(contentOffset, self.contentOffset)) {
        [self scrollViewDidScroll:self];
    }
    
    [super setContentOffset:contentOffset];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [DOLayoutUtil setSubviewsInLinearLayout:self];
}

@end

@implementation DOLayoutUtil

/**
 * viewに対してsetNeedsLayoutする
 */
+ (void)setNeedsLayout:(nonnull UIView *)view
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
+ (void)setNeedsLayoutToSuperview:(nonnull UIView *)view
{
#if TARGET_INTERFACE_BUILDER
    return;
#endif
    [self.class setNeedsLayout:[self.class linearLayoutAsSuperview:view]];
}

/**
 * Viewのコンテンツサイズ
 */
+ (CGSize)contentSize:(nonnull UIView *)view limitSize:(CGSize)limitSize
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
        DOLinearLayoutOrientation orientation = [(DOLinearLayout *)view layoutOrientation];
        for (UIView *v in view.subviews) {
            if (orientation == DOLinearLayoutOrientationHorizontal) {
                if (![v.do_layoutParam isWidthMatchParent]) {
                    size.width += v.do_contentSize.width;
                }
                if (![v.do_layoutParam isHeightMatchParent]) {
                    if (size.height < v.do_contentSize.height) {
                        size.height = v.do_contentSize.height;
                    }
                }
            } else if (orientation == DOLinearLayoutOrientationVertical) {
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
        
        if ([(DOLinearLayout *)view enableAutoLineBreak] && ORIENTATION_VALUE(orientation, view.do_width, view.do_height) < ORIENTATION_VALUE(orientation, size.width, size.height)) {
            size = [view sizeThatFits:view.frame.size];
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
+ (CGSize)layoutSubviews:(nonnull NSViewArray *)subviews linearLayoutParams:(nonnull NSArray *)linearLayoutParams inView:(nonnull UIView *)view offset:(CGPoint)offset param:(nonnull DOLinearLayoutSubviewsParam *)param
{
    DOLinearLayoutOrientation orientation = param.orientation;
    DOLinearLayoutGravity gravity = param.gravity;
    BOOL autoLineBreak = param.autoLineBreak;
    BOOL dryRun = param.dryRun;
    
    NSAssert(orientation == DOLinearLayoutOrientationHorizontal || orientation == DOLinearLayoutOrientationVertical, @"bad orientation");
    
    BOOL isLayoutingScrollView = NO;
    if ([self.class scrollViewWithSubviews:subviews]) {
        UIScrollView *scrollView = [self.class scrollViewWithSubviews:subviews];
        isLayoutingScrollView = YES;
        scrollView.frame = view.bounds;
        subviews = scrollView.subviews;
        if ([scrollView isKindOfClass:[DOLinearLayoutScrollView class]]) {
            linearLayoutParams = [((DOLinearLayoutScrollView *)scrollView).params mutableCopy];
        } else {
            NSAssert(NO, @"");
            linearLayoutParams = scrollView.subviewsLinearLayoutParams;
        }
    }
    
    __strong id<DOLinearLayoutDelegate> delegate;
    if ([view isKindOfClass:[DOLinearLayout class]]) {
        delegate = ((DOLinearLayout *)view).linearLayoutDelegate;
    }
    if (!delegate) {
        NSAssert(subviews.count == linearLayoutParams.count, @"bad param count");
    }
    
    NSUInteger countOfSubviews = linearLayoutParams.count;
    
    // サイズ計算用に一度ループ
    CGFloat totalT = 0;
    CGFloat totalWeight = 0;
    for (NSUInteger i = 0; i < countOfSubviews; i++) {
        UIView *v = (delegate == nil) ? subviews[i] : nil;
        DOLinearLayoutParam *p = linearLayoutParams[i];
        if (p.visibility == UIViewVisibilityGone || p.isIgnoredFromLinearLayout) {
            // なにもしない
        } else if ([p isMatchParentWithOrientation:orientation]) {
            // weightの加算
            totalWeight += p.weight;
        } else {
            // サイズを加算
            if (v) {
                totalT += ORIENTATION_VALUE(orientation, v.do_contentSize.width, v.do_contentSize.height);
            } else {
                totalT += ORIENTATION_VALUE(orientation, p.width, p.height);
            }
        }
    }
    
    // weightで分割したサイズを算出
    CGFloat remain = ORIENTATION_VALUE(orientation, view.do_width ,view.do_height) - totalT;
    if (remain < 0) {
        if (autoLineBreak && linearLayoutParams.count > 1) {
            // 入りきっていないので、改行する
            CGFloat total = 0;
            for (NSInteger i = 0, len = linearLayoutParams.count; i < len ; i++) {
                DOLinearLayoutParam *p = linearLayoutParams[i];
                UIView *v = subviews[i];
                if (p.visibility != UIViewVisibilityGone && !p.isIgnoredFromLinearLayout && ![p isMatchParentWithOrientation:orientation]) {
                    // サイズを加算
                    total += ORIENTATION_VALUE(orientation, v.do_contentSize.width, v.do_contentSize.height);
                }
                if (ORIENTATION_VALUE(orientation, view.do_width, view.do_height) < total) {
                    // 親より大きくなったので、その前で改行する
                    NSRange range1;
                    NSRange range2;
                    if (i == 0) {
                        range1 = NSMakeRange(0, 1);
                        range2 = NSMakeRange(1, len - 1);
                    } else {
                        range1 = NSMakeRange(0, i);
                        range2 = NSMakeRange(i, len - i);
                    }
                    
                    NSViewArray *subarray1 = [subviews subarrayWithRange:range1];
                    NSViewArray *subarray2 = [subviews subarrayWithRange:range2];
                    NSArray *subparray1 = [linearLayoutParams subarrayWithRange:range1];
                    NSArray *subparray2 = [linearLayoutParams subarrayWithRange:range2];
                    UIView *subview1 = [[UIView alloc] initWithFrame:view.frame];
                    UIView *subview2 = [[UIView alloc] initWithFrame:view.frame];
                    
                    NSAssert(subarray1.count, @"");
                    NSAssert(subarray2.count, @"");
                    NSAssert(subparray1.count, @"");
                    NSAssert(subparray2.count, @"");
                    NSAssert(subarray1.count + subarray2.count == len, @"");
                    NSAssert(subparray1.count + subparray2.count == len, @"");
                    
                    DOLinearLayoutSubviewsParam *cloneParam = [param clone];
                    if (orientation == DOLinearLayoutOrientationHorizontal) {
                        if (cloneParam.gravity & DOLinearLayoutGravityCenterVertical) {
                            cloneParam.gravity &= ~DOLinearLayoutGravityCenterVertical;
                        }
                    } else {
                        if (cloneParam.gravity & DOLinearLayoutGravityCenterHorizontal) {
                            cloneParam.gravity &= ~DOLinearLayoutGravityCenterHorizontal;
                        }
                    }
                    CGSize size1 = [self.class layoutSubviews:subarray1 linearLayoutParams:subparray1 inView:subview1 offset:offset param:cloneParam];
                    CGPoint subOffset;
                    if (orientation == DOLinearLayoutOrientationHorizontal) {
                        subOffset = CGPointMake(0, size1.height + offset.y);
                    } else {
                        subOffset = CGPointMake(size1.width + offset.x, 0);
                    }
                    CGSize size2 = [self.class layoutSubviews:subarray2 linearLayoutParams:subparray2 inView:subview2 offset:subOffset param:cloneParam];
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
        UIView *v = (delegate == nil) ? subviews[i] : nil;
        DOLinearLayoutParam *p = linearLayoutParams[i];
        if (p.isIgnoredFromLinearLayout) {
            continue;
        }
        
        CGRect frame = [self.class updateView:v
                                  layoutParam:p
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
            UIView *v = (delegate == nil) ? subviews[i] : nil;
            DOLinearLayoutParam *p = linearLayoutParams[i];
            if (p.isIgnoredFromLinearLayout) {
                continue;
            }
            
            ORIENTATION_VALUE(orientation, v.do_x += slideXInt, v.do_y += slideYInt);
            if (orientation == DOLinearLayoutOrientationHorizontal) {
                p.frame = CGRectMake(p.frame.origin.x + slideXInt, p.frame.origin.y, p.frame.size.width, p.frame.size.height);
            } else {
                p.frame = CGRectMake(p.frame.origin.x, p.frame.origin.y + slideYInt, p.frame.size.width, p.frame.size.height);
            }
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
        DOLinearLayoutScrollView *scrollView = (DOLinearLayoutScrollView *)ll.scrollView;
        CGSize scrollViewContentSize = ORIENTATION_VALUE(orientation, CGSizeMake(position, view.do_height), CGSizeMake(view.do_weight, position));
        BOOL over = (position > ORIENTATION_VALUE(orientation, view.do_width, view.do_height));
        if (over) {
            scrollView.contentSize = scrollViewContentSize;
        } else {
            scrollView.contentOffset = CGPointZero;
            scrollView.contentSize = CGSizeZero;
        }
        
        if (isLayoutingScrollView) {
            // ScrollViewから移動
            if (scrollView && (!over || !ll.enableScroll) && !delegate) {
                for (UIView *v in scrollView.subviews) {
                    [view addSubview:v];
                }
                if (delegate) {
                    if ([scrollView isKindOfClass:[DOLinearLayoutScrollView class]]) {
                        [[(DOLinearLayoutScrollView *)scrollView params] removeAllObjects];
                    } else {
                        NSAssert(NO, @"");
                    }
                }
                [scrollView removeFromSuperview];
            }
        } else {
            // ScrollViewに移動
            if (ll.enableScroll && !scrollView) {
                scrollView = [[DOLinearLayoutScrollView alloc] initWithFrame:view.bounds];
                scrollView.delegate = scrollView;
                if (over) {
                    scrollView.contentSize = scrollViewContentSize;
                } else {
                    scrollView.contentOffset = CGPointZero;
                    scrollView.contentSize = CGSizeZero;
                }
                
                if (delegate) {
                    for (NSNumber *t in [delegate tagsForContentViews]) {
                        DOLinearLayoutParam *p = [delegate linearLayoutParamWithTag:[t integerValue]];
                        p.viewTag = [t integerValue];
                        if (p) {
                            if (!over) {
                                UIView *v = [scrollView viewWithTag:[t integerValue]];
                                if (!v) {
                                    v = [delegate viewInLinearLayoutWithTag:[t integerValue]];
                                    
                                    NSAssert(v.tag == [t integerValue], @"");
                                    NSAssert(v.tag == p.viewTag, @"");
                                    NSAssert(v.tag, @"");
                                    NSAssert(p.viewTag, @"");
                                    
                                    v.do_layoutParam = p;
                                    [scrollView addSubview:v];
                                } else {
                                    NSAssert(NO, @"");
                                }
                            }
                            
                            [scrollView addParam:p];
                        } else {
                            NSAssert(NO, @"");
                        }
                    }
                } else {
                    for (UIView *v in subviews) {
                        [scrollView addSubview:v];
                        [scrollView addParam:v.do_layoutParam];
                    }
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

+ (CGRect)updateView:(nonnull UIView *)v
         layoutParam:(nonnull DOLinearLayoutParam *)param
         orientation:(DOLinearLayoutOrientation)orientation
              parent:(nonnull UIView *)view
             gravity:(DOLinearLayoutGravity)gravity
     remainPerWeight:(CGFloat)remainPerWeight
            position:(CGFloat)p
              offset:(CGPoint)offset
              dryRun:(BOOL)dryRun
{
    // hiddenの設定
    if (!dryRun) {
        switch (param.visibility) {
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
    if (param.visibility == UIViewVisibilityGone) {
        margin = UIEdgeInsetsZero;
        frame = CGRectZero;
    } else if ([param isMatchParentWithOrientation:orientation]) {
        margin = v.do_layoutMargin;
        frame = [self.class frameForViewResizeWithView:v
                                           layoutParam:param
                                           orientation:orientation
                                                parent:view
                                               gravity:gravity
                                                 weght:v.do_weight
                                       remainPerWeight:remainPerWeight];
    } else {
        margin = v.do_layoutMargin;
        frame = [self.class frameForViewNotResizeWithView:v
                                              layoutParam:param
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
    if (param.visibility == UIViewVisibilityGone) {
        wInt = 0;
    } else {
        if ([param isMatchParentWithOrientation:orientation]) {
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
    param.frame = frame;
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

+ (CGRect)frameForViewNotResizeWithView:(nullable UIView *)v
                            layoutParam:(nonnull DOLinearLayoutParam *)param
                            orientation:(DOLinearLayoutOrientation)orientation
                                 parent:(nonnull UIView *)view
                                gravity:(DOLinearLayoutGravity)gravity
{
    // 基本はcontentSize
    CGFloat x = 0;
    CGFloat y = 0;
    CGFloat w;
    if (v) {
        w = v.do_contentSize.width;
    } else {
        w = param.width;
    }
    CGFloat h;
    if (v) {
        h  = v.do_contentSize.height;
    } else {
        h = param.height;
    }
    
    // match_parent対応
    if (orientation == DOLinearLayoutOrientationHorizontal && [param isMatchParentWithOrientation:DOLinearLayoutOrientationVertical]) {
        h = view.do_height;
    } else if (orientation == DOLinearLayoutOrientationVertical && [param isMatchParentWithOrientation:DOLinearLayoutOrientationHorizontal]) {
        w = view.do_width;
    }
    
    return CGRectMake(x, y, w, h);
}

+ (CGRect)frameForViewResizeWithView:(nullable UIView *)v
                         layoutParam:(nonnull DOLinearLayoutParam *)param
                         orientation:(DOLinearLayoutOrientation)orientation
                              parent:(nonnull UIView *)view
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
    if (orientation == DOLinearLayoutOrientationHorizontal && ![param isMatchParentWithOrientation:DOLinearLayoutOrientationVertical]) {
        if (v) {
            h = v.do_contentSize.height;
        } else {
            h = param.height;
        }
    } else if (orientation == DOLinearLayoutOrientationVertical && ![param isMatchParentWithOrientation:DOLinearLayoutOrientationHorizontal]) {
        if (v) {
            w = v.do_contentSize.width;
        } else {
            w = param.width;
        }
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

+ (void)layoutIgnoredView:(nonnull UIView *)view
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

+ (nullable UIScrollView *)scrollViewWithSubviews:(nonnull NSViewArray *)subviews
{
    if (subviews.count == 1 && [subviews[0] isKindOfClass:[DOLinearLayoutScrollView class]]) {
        return (DOLinearLayoutScrollView *)subviews[0];
    }
    return nil;
}

+ (DOLinearLayout *)linearLayoutAsSuperview:(nonnull UIView *)view
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
 * subviewsからDOLinearLayoutParamの配列を取得する
 */
+ (NSArray *)subviewsLinearLayoutParamsWithSubviews:(NSViewArray *)subviews
{
    NSMutableArray *subviewsLinearLayoutParams = [@[] mutableCopy];
    
    for (UIView *v in subviews) {
        if (v.do_layoutParam) {
            [subviewsLinearLayoutParams addObject:v.do_layoutParam];
        } else {
            [subviewsLinearLayoutParams addObject:[[DOLinearLayoutParam alloc] init]];
        }
    }
    
    return subviewsLinearLayoutParams;
}

/**
 * DOLinearLayoutから指定のtagのついたViewを取得する
 */
+ (nullable UIView *)viewWithTag:(NSInteger)tag inLinearLayout:(nonnull DOLinearLayout *)linearLayout
{
    UIView *v = nil;
    
    id<DOLinearLayoutDelegate> deletage = linearLayout.linearLayoutDelegate;
    if (deletage) {
        v = [deletage viewInLinearLayoutWithTag:tag];
        
        NSAssert(v.tag == tag, @"");
        NSAssert(v.tag, @"");
        NSAssert(tag, @"");
        
        DOLinearLayoutScrollView *scrollView = (DOLinearLayoutScrollView *)linearLayout.scrollView;
        if (v && scrollView) {
            for (DOLinearLayoutParam *p in [scrollView.params mutableCopy]) {
                if (p.viewTag == tag) {
                    v.frame = p.frame;
                    break;
                }
            }
        }
    }
    
    return v;
}

/**
 * DOLinearLayoutScrollView内のViewを配置する
 */
+ (void)setSubviewsInLinearLayout:(nonnull DOLinearLayoutScrollView *)scrollView
{
    DOLinearLayout *ll = (DOLinearLayout *)scrollView.superview;
    if (!ll) {
        return;
    }
    if (![ll isKindOfClass:[DOLinearLayout class]]) {
        NSAssert(NO, @"");
        return;
    }
    if (![scrollView isKindOfClass:[DOLinearLayoutScrollView class]]) {
        NSAssert(NO, @"");
        return;
    }
    id<DOLinearLayoutDelegate> delegate = ll.linearLayoutDelegate;
    if (!delegate) {
        return;
    }
    
    CGPoint offset = scrollView.contentOffset;
    CGSize size = scrollView.frame.size;
    
    CGRect visibleRect = CGRectZero;
    visibleRect.origin = offset;
    visibleRect.size = size;
    
    for (DOLinearLayoutParam *p in [scrollView.params mutableCopy]) {
        if (CGRectEqualToRect(p.frame, CGRectZero)) {
            continue;
        }
        
        NSAssert(p.viewTag != 0, @"");
        if (p.viewTag == 0) {
            continue;
        }
        
        UIView *v = [scrollView viewWithTag:p.viewTag];
        if (CGRectIntersectsRect(p.frame, visibleRect)) {
            if (!v.subviews) {
                // 見える範囲にViewが配置されているので、addSubViewする
                v = [delegate viewInLinearLayoutWithTag:p.viewTag];
                
                NSAssert(v.tag == p.viewTag, @"");
                NSAssert(v.tag, @"");
                NSAssert(p.viewTag, @"");
                
                if (v) {
                    [scrollView addSubview:v];
                } else {
                    NSAssert(NO, @"");
                }
            }
            v.frame = p.frame;
        } else {
            if (v.subviews) {
                // 見える範囲に外にViewが配置されているので、removeFromSuperviewする
                [v removeFromSuperview];
            }
        }
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
