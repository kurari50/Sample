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

- (instancetype)clone;

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
+ (void)setNeedsLayout:(UIView *)view;

/**
 * superviewに対してsetNeedsLayoutする
 */
+ (void)setNeedsLayoutToSuperview:(UIView *)view;

/**
 * Viewのコンテンツサイズを取得する
 */
+ (CGSize)contentSize:(UIView *)view limitSize:(CGSize)limitSize;

/**
 * fromをlimitに入りきるサイズに調整する
 */
+ (CGSize)sizeFrom:(CGSize)from limit:(CGSize)limit aspectKeep:(BOOL)aspectKeep;

/**
 * レイアウトする
 */
+ (CGSize)layoutSubviews:(NSViewArray *)subviews inView:(UIView *)view offset:(CGPoint)offset param:(DOLinearLayoutSubviewsParam *)param;

/**
 * 四捨五入
 */
+ (NSInteger)integerWithFloat:(CGFloat)f;

/**
 * テストかどうか
 */
+ (BOOL)isRunningTests;

@end
