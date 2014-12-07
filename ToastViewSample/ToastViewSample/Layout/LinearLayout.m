//
//  LinearLayout.m
//  ToastViewSample
//
//  Created by kura on 2014/12/06.
//  Copyright (c) 2014年 kura. All rights reserved.
//

#import "Layout.h"

@interface LinearLayout ()

@property (nonatomic, assign, readwrite) CGFloat layoutedHeight;

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) NSMutableArray *addedViews;

@end

@implementation LinearLayout

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.clipsToBounds = YES;
    _separatorSize = CGSizeMake(0, 0);
    _addedViews = [NSMutableArray array];
}

- (void)setScrollable:(BOOL)scrollable
{
    _scrollable = scrollable;
    
    [self setNeedsLayout];
}

- (void)setSeparatorSize:(CGSize)separatorSize
{
    _separatorSize = separatorSize;
    
    [self setNeedsLayout];
}

- (void)setReverseLayout:(BOOL)reverseLayout
{
    _reverseLayout = reverseLayout;
    
    [self setNeedsLayout];
}

- (void)addSubview:(UIView *)view
{
    if (self.addTop) {
        [self insertSubview:view atIndex:0];
        [self.addedViews insertObject:view atIndex:0];
    } else {
        [super addSubview:view];
        [self.addedViews addObject:view];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.scrollable) {
        if (!self.scrollView) {
            self.scrollView = [[UIScrollView alloc] init];
        }
    }
    
    {
        CGRect f = self.frame;
        f.origin = CGPointZero;
        f.size = self.frame.size;
        self.scrollView.frame = f;
        self.scrollView.contentSize = f.size;
    }
    
    {
        NSArray *subviews = (self.scrollView.superview)? self.scrollView.subviews:self.subviews;
        NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
        [self.addedViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (![subviews containsObject:obj]) {
                [set addIndex:idx];
            }
        }];
        [self.addedViews removeObjectsAtIndexes:set];
    }
    
    NSArray *subviews = [self.addedViews mutableCopy];
    
    __block BOOL hasWeight = NO;
    __block BOOL hasLayoutableView = NO;
    __block CGFloat totalHeight = 0;
    __block CGFloat totalWeight = 0;
    __block NSUInteger countOfExistView = 0;
    
    [subviews enumerateObjectsUsingBlock:^(LayoutableView *view, NSUInteger idx, BOOL *stop) {
        if ([view isKindOfClass:[LayoutableView class]]) {
            LayoutableView *layoutableView = (LayoutableView *)view;
            
            hasLayoutableView = YES;
            
            BOOL gone = NO;
            if (layoutableView.visibility == LayoutableViewLayoutVisibilityInvisible) {
                layoutableView.hidden = YES;
                countOfExistView++;
            } else if (layoutableView.visibility == LayoutableViewLayoutVisibilityGone) {
                layoutableView.hidden = YES;
                gone = YES;
            } else {
                layoutableView.hidden = NO;
                countOfExistView++;
            }
            
            if (gone) {
                return;
            }
            
            CGFloat weight = view.weight;
            if (weight == 0) {
                totalHeight += view.frame.size.height;
            } else {
                hasWeight = YES;
                totalWeight += weight;
            }
        } else {
            countOfExistView++;
            totalHeight += view.frame.size.height;
        }
    }];
    
    CGFloat separatorHeight = (countOfExistView - 1) * self.separatorSize.height;
    if (hasLayoutableView && hasWeight) {
        CGFloat remainHeight = self.frame.size.height - totalHeight - separatorHeight;
        if (remainHeight < 0) {
            remainHeight = 0;
        }
        
        [subviews enumerateObjectsUsingBlock:^(LayoutableView *view, NSUInteger idx, BOOL *stop) {
            if (![view isKindOfClass:[LayoutableView class]]) {
                return;
            }
            
            if (view.weight == 0) {
                return;
            }
            if (view.visibility == LayoutableViewLayoutVisibilityGone) {
                return;
            }
            
            CGRect f = view.frame;
            CGFloat h = remainHeight * (view.weight / totalWeight);
            
            view.frame = CGRectMake(0, 0, f.size.width, h);
        }];
    }
    
    __weak LinearLayout *weakSelf = self;
    __block CGFloat y = 0;
    [subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        if (![view isKindOfClass:[UIView class]]) {
            return;
        }
        __strong LinearLayout *strongSelf = weakSelf;
        
        CGRect f = view.frame;
        CGFloat x = 0;
        CGFloat w = f.size.width;
        
        if (hasLayoutableView) {
            if ([view isKindOfClass:[LayoutableView class]]) {
                LayoutableView *layoutableView = (LayoutableView *)view;
                
                if (layoutableView.param.width == LayoutableViewLayoutParamMatchParent) {
                    w = strongSelf.frame.size.width;
                } else {
                    if (layoutableView.gravity.horizontal == LayoutableViewLayoutGravityCenter) {
                        x = (strongSelf.frame.size.width - view.frame.size.width) / 2;
                    }
                    if (layoutableView.gravity.horizontal == LayoutableViewLayoutGravityRight) {
                        x = strongSelf.frame.size.width - view.frame.size.width;
                    }
                }
                
                if (layoutableView.visibility == LayoutableViewLayoutVisibilityGone) {
                    return;
                }
            }
        }
        
        if (strongSelf.reverseLayout) {
            CGFloat h = (strongSelf.scrollView.superview)? totalHeight + separatorHeight:strongSelf.frame.size.height;
            view.frame = CGRectMake(x, h - y - f.size.height, w, f.size.height);
        } else {
            view.frame = CGRectMake(x, y, w, f.size.height);
        }
        
        y += f.size.height;
        y += strongSelf.separatorSize.height;
    }];
    
    y -= self.separatorSize.height;
    
    if (hasWeight) {
        self.layoutedHeight = y;
        
        self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, self.layoutedHeight);
        if (self.scrollable && (self.frame.size.height < self.layoutedHeight)) {
            if (!self.scrollView.superview) {
                [self.scrollView.subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                    [view removeFromSuperview];
                }];
                [subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                    [self.scrollView addSubview:view];
                }];
                [self addSubview:self.scrollView];
                [self.addedViews removeObject:self.scrollView];
            }
        } else {
            if (self.scrollView.superview) {
                [self.scrollView.subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                    [view removeFromSuperview];
                    [self.addedViews removeObject:view];
                }];
                [subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
                    [self addSubview:view];
                }];
                [self.scrollView removeFromSuperview];
            }
        }
    }
}

@end
