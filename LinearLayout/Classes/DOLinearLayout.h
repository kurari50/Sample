//
//  DOLinearLayout.h
//  DOViewLayout
//
//  Created by kura on 2015/10/10.
//  Copyright © 2015年 kura. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DOLinearLayout;

/**
 * layout orientation
 */
typedef NS_ENUM(int, DOLinearLayoutOrientation) {
    /**
     * horizontal
     */
    DOLinearLayoutOrientationHorizontal,
    
    /**
     * vertical
     */
    DOLinearLayoutOrientationVertical,
};

/**
 * layout gravity
 */
typedef NS_ENUM(int, DOLinearLayoutGravity) {
    /**
     * left
     */
    DOLinearLayoutGravityLeft               = 0b0000001,
    
    /**
     * right
     */
    DOLinearLayoutGravityRight              = 0b0000010,

    /**
     * top
     */
    DOLinearLayoutGravityTop                = 0b0000100,

    /**
     * bottom
     */
    DOLinearLayoutGravityBottom             = 0b0001000,
    
    /**
     * center vertical
     */
    DOLinearLayoutGravityCenterVertical     = 0b0010000,
    
    /**
     * center horizontal
     */
    DOLinearLayoutGravityCenterHorizontal   = 0b0100000,
    
    /**
     * center
     */
    DOLinearLayoutGravityCenter             = DOLinearLayoutGravityCenterVertical | DOLinearLayoutGravityCenterHorizontal,
};

/**
 * layout param
 */
typedef NS_ENUM(int, UIViewLayoutParam) {
    /**
     * match parent
     */
    UIViewLayoutParamMatchParent        = 0b00000,
    
    /**
     * wrap content
     */
    UIViewLayoutParamWrapContent        = 0b00001,
};

/**
 * visibility
 */
typedef NS_ENUM(int, UIViewVisibility) {
    /**
     * visible
     */
    UIViewVisibilityVisible     = 0,
    
    /**
     * invisible
     */
    UIViewVisibilityInvisible,
    
    /**
     * gone
     */
    UIViewVisibilityGone,
};

@interface DOLinearLayoutParam : NSObject

@property (nonatomic) UIViewLayoutParam widthParam;
@property (nonatomic) UIViewLayoutParam heightParam;
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;

- (BOOL)isHeightMatchParent;
- (BOOL)isWidthMatchParent;

+ (instancetype)paramWithWidth:(CGFloat)w widthParam:(UIViewLayoutParam)wp height:(CGFloat)h heightParam:(UIViewLayoutParam)hp;
+ (instancetype)paramWithWidth:(CGFloat)w height:(CGFloat)h;
+ (instancetype)paramMatchParent;
+ (instancetype)paramWrapContent;

@property (nonatomic) BOOL isIgnoredFromLinearLayout;
@property (nonatomic, readonly) BOOL hasAbsolutePosition;
@property (nonatomic, readonly) BOOL hasRelativePosition;
@property (nonatomic, readonly) CGPoint absolutePosition;
@property (nonatomic, readonly) CGPoint relativePosition;
@property (nonatomic, readonly) UIEdgeInsets relativeMargin;
@property (nonatomic, weak, readonly) UIView *relativeView;

+ (instancetype)paramAbsolutePosition:(CGPoint)position;
+ (instancetype)paramSamePositionToView:(UIView *)view;
+ (instancetype)paramRelativePosition:(CGPoint)position toView:(UIView *)view;
+ (instancetype)paramRelativePosition:(CGPoint)position toView:(UIView *)view margin:(UIEdgeInsets)margin;

@end

IB_DESIGNABLE

@interface UIView (DOLinearLayout)

/**
 * ignored from LinearLayout
 */
@property (nonatomic) IBInspectable BOOL do_isIgnoredFromLinearLayout;

/**
 * weight
 */
@property (nonatomic) IBInspectable CGFloat do_weight;

/**
 * layout param
 */
@property (nonatomic) DOLinearLayoutParam *do_layoutParam;

/**
 * layout param width
 */
@property (nonatomic) IBInspectable CGFloat do_layoutParamWidth;

/**
 * layout param width is wrap content
 */
@property (nonatomic) IBInspectable BOOL do_layoutParamWidthIsWrapContent;

/**
 * layout param height
 */
@property (nonatomic) IBInspectable CGFloat do_layoutParamHeight;

/**
 * layout param height is wrap content
 */
@property (nonatomic) IBInspectable BOOL do_layoutParamHeightIsWrapContent;

/**
 * layout margin
 */
@property (nonatomic) UIEdgeInsets do_layoutMargin;

/**
 * layout margin top
 */
@property (nonatomic) IBInspectable CGFloat do_layoutMarginTop;

/**
 * layout margin left
 */
@property (nonatomic) IBInspectable CGFloat do_layoutMarginLeft;

/**
 * layout margin bottom
 */
@property (nonatomic) IBInspectable CGFloat do_layoutMarginBottom;

/**
 * layout margin right
 */
@property (nonatomic) IBInspectable CGFloat do_layoutMarginRight;

/**
 * visible
 */
#if TARGET_INTERFACE_BUILDER
@property (nonatomic) IBInspectable int do_visibility;
#else
@property (nonatomic) UIViewVisibility do_visibility;
#endif

/**
 * content size
 */
@property (nonatomic) IBInspectable CGSize do_contentSize;

/**
 * check match parent
 */
- (BOOL)isHeightMatchParent;
- (BOOL)isWidthMatchParent;
- (BOOL)isMatchParentWithOrientation:(DOLinearLayoutOrientation)orientation;

@end

IB_DESIGNABLE

@interface UIImageView (DOLinearLayout)

/**
 * keep aspect ratio
 */
@property (nonatomic) IBInspectable BOOL do_aspectKeep;

@end

typedef void (^DOLinearLayoutDidChangeSizeBlock)(DOLinearLayout *linearLayout, CGSize size);

IB_DESIGNABLE

@interface DOLinearLayout : UIView

@property (nonatomic, copy) DOLinearLayoutDidChangeSizeBlock didChangeSizeBlock;

/**
 * layout orientation
 */
#if TARGET_INTERFACE_BUILDER
@property (nonatomic) IBInspectable int layoutOrientation;
#else
@property (nonatomic) DOLinearLayoutOrientation layoutOrientation;
#endif

/**
 * layout gravity
 */
#if TARGET_INTERFACE_BUILDER
@property (nonatomic) IBInspectable int layoutGravity;
#else
@property (nonatomic) DOLinearLayoutGravity layoutGravity;
#endif

/**
 * auto line break
 */
@property (nonatomic) IBInspectable BOOL enableAutoLineBreak;

/**
 * scroll
 */
@property (nonatomic) IBInspectable BOOL enableScroll;

@end

@interface UIView (DOLinearLayoutable)

@property (nonatomic) BOOL do_enableLinearLayout;

@end
