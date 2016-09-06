//
//  UIView+DOAccessor.h
//  DOViewLayout
//
//  Created by kura on 2015/10/10.
//  Copyright © 2015年 kura. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (DOAccessor)

/**
 * frame.origin.x
 */
@property (nonatomic) CGFloat do_x;

/**
 * frame.origin.y
 */
@property (nonatomic) CGFloat do_y;

/**
 * frame.size.width
 */
@property (nonatomic) CGFloat do_width;

/**
 * frame.size.heigth
 */
@property (nonatomic) CGFloat do_height;

/**
 * frame.origin
 */
@property (nonatomic) CGPoint do_origin;

/**
 * frame.size
 */
@property (nonatomic) CGSize do_size;

@end
