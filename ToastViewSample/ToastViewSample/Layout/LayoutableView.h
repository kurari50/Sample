//
//  LayoutableView.h
//  ToastViewSample
//
//  Created by kura on 2014/12/06.
//  Copyright (c) 2014年 kura. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, LayoutableViewLayoutParam) {
    LayoutableViewLayoutParamWrapContent = 0,
    LayoutableViewLayoutParamMatchParent,
};

typedef NS_ENUM(NSInteger, LayoutableViewLayoutGravity) {
    LayoutableViewLayoutGravityNone = 0,
    LayoutableViewLayoutGravityLeft,
    LayoutableViewLayoutGravityRight,
    LayoutableViewLayoutGravityCenter,
};

typedef NS_ENUM(NSInteger, LayoutableViewLayoutVisibility) {
    LayoutableViewLayoutVisibilityVisible = 0,
    LayoutableViewLayoutVisibilityInvisible,
    LayoutableViewLayoutVisibilityGone,
};

@interface LayoutGravity : NSObject

@property (nonatomic, assign) LayoutableViewLayoutGravity horizontal;
@property (nonatomic, assign) LayoutableViewLayoutGravity vertical;

+ (instancetype)layoutGravityH:(LayoutableViewLayoutGravity)h V:(LayoutableViewLayoutGravity)v;

@end

@interface LayoutParam : NSObject

@property (nonatomic, assign) LayoutableViewLayoutParam width;
@property (nonatomic, assign) LayoutableViewLayoutParam height;

+ (instancetype)layoutParamW:(LayoutableViewLayoutParam)w H:(LayoutableViewLayoutParam)h;

@end

@interface LayoutableView : UIView

@property (nonatomic, assign) CGFloat weight;
@property (nonatomic, strong) LayoutGravity *gravity;
@property (nonatomic, strong) LayoutParam *param;
@property (nonatomic, assign) LayoutableViewLayoutVisibility visibility;

@end
