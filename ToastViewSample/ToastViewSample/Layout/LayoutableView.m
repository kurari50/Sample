//
//  LayoutableView.m
//  ToastViewSample
//
//  Created by kura on 2014/12/06.
//  Copyright (c) 2014年 kura. All rights reserved.
//

#import "LayoutableView.h"

@implementation LayoutParam

+ (instancetype)layoutParamW:(LayoutableViewLayoutParam)w H:(LayoutableViewLayoutParam)h
{
    LayoutParam *p = [[LayoutParam alloc] init];
    p.width = w;
    p.height = h;
    return p;
}

@end

@implementation LayoutGravity

+ (instancetype)layoutGravityH:(LayoutableViewLayoutGravity)h V:(LayoutableViewLayoutGravity)v
{
    LayoutGravity *g = [[LayoutGravity alloc] init];
    g.horizontal = h;
    g.vertical = v;
    return g;
}

@end

@implementation LayoutableView

@end
