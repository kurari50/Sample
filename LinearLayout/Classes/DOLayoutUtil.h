//
//  DOLayoutUtil.h
//  DOViewLayout
//
//  Created by kura on 2016/08/30.
//  Copyright © 2016年 kura. All rights reserved.
//

#import "DOLinearLayout.h"

#ifdef __IPHONE_9_1
#define NSViewArray                 NSArray<UIView *>
#define NSLayoutConstraintArray     NSArray<NSLayoutConstraint *>
#else
#define NSViewArray                 NSArray
#define NSLayoutConstraintArray     NSArray
#endif

#define TESTING [DOLayoutUtil isRunningTests]

@interface DOLayoutSubviewsParam : NSObject

@property (nonatomic) BOOL dryRun;

- (nonnull instancetype)clone;

@end

@interface DOLinearLayoutSubviewsParam : DOLayoutSubviewsParam

@property (nonatomic) DOLinearLayoutOrientation orientation;
@property (nonatomic) DOLinearLayoutGravity gravity;
@property (nonatomic) BOOL autoLineBreak;

@end

@interface DOLayoutUtil : NSObject

/**
 * viewに対してsetNeedsLayoutする
 */
+ (void)setNeedsLayout:(nonnull UIView *)view;

/**
 * superviewに対してsetNeedsLayoutする
 */
+ (void)setNeedsLayoutToSuperview:(nonnull UIView *)view;

/**
 * Viewのコンテンツサイズを取得する
 */
+ (CGSize)contentSize:(nonnull UIView *)view limitSize:(CGSize)limitSize;

/**
 * fromをlimitに入りきるサイズに調整する
 */
+ (CGSize)sizeFrom:(CGSize)from limit:(CGSize)limit aspectKeep:(BOOL)aspectKeep;

/**
 * fromをsizeに合わせてサイズを調整する
 */
+ (CGSize)sizeFrom:(CGSize)from to:(CGSize)size aspectKeep:(BOOL)aspectKeep;

/**
 * レイアウトする
 */
+ (CGSize)layoutSubviews:(nonnull NSViewArray *)subviews linearLayoutParams:(nonnull NSArray *)linearLayoutParams inView:(nonnull UIView *)view offset:(CGPoint)offset param:(nonnull DOLinearLayoutSubviewsParam *)param;

/**
 * DOLinearLayoutがスクロールする場合、UIScrollViewを取得する
 */
+ (nullable UIScrollView *)scrollViewWithSubviews:(nonnull NSViewArray *)subviews;

/**
 * subviewsからDOLinearLayoutParamの配列を取得する
 */
+ (nonnull NSArray *)subviewsLinearLayoutParamsWithSubviews:(nonnull NSViewArray *)subviews;

/**
 * DOLinearLayoutから指定のtagのついたViewを取得する
 */
+ (nullable UIView *)viewWithTag:(NSInteger)tag inLinearLayout:(nonnull DOLinearLayout *)linearLayout;

/**
 * DOLinearLayoutScrollView内のViewを配置する
 */
+ (void)setSubviewsInLinearLayout:(nonnull UIScrollView *)scrollView;

/**
 * 四捨五入
 */
+ (NSInteger)integerWithFloat:(CGFloat)f;

/**
 * テストかどうか
 */
+ (BOOL)isRunningTests;

@end
