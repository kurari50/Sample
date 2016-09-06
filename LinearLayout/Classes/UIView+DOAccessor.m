//
//  UIView+DOAccessor.m
//  DOViewLayout
//
//  Created by kura on 2015/10/10.
//  Copyright © 2015年 kura. All rights reserved.
//

#import "UIView+DOAccessor.h"

@implementation UIView (DOAccessor)

- (void)setDo_x:(CGFloat)do_x
{
    self.frame = CGRectMake(do_x, self.do_y, self.do_width, self.do_height);
}

- (CGFloat)do_x
{
    return self.frame.origin.x;
}

- (void)setDo_y:(CGFloat)do_y
{
    self.frame = CGRectMake(self.do_x, do_y, self.do_width, self.do_height);
}

- (CGFloat)do_y
{
    return self.frame.origin.y;
}

- (void)setDo_width:(CGFloat)do_width
{
    self.frame = CGRectMake(self.do_x, self.do_y, do_width, self.do_height);
}

- (CGFloat)do_width
{
    return self.frame.size.width;
}

- (void)setDo_height:(CGFloat)do_height
{
    self.frame = CGRectMake(self.do_x, self.do_y, self.do_width, do_height);
}

- (CGFloat)do_height
{
    return self.frame.size.height;
}

- (void)setDo_origin:(CGPoint)do_origin
{
    self.frame = CGRectMake(do_origin.x, do_origin.y, self.do_width, self.do_height);
}

- (CGPoint)do_origin
{
    return self.frame.origin;
}

- (void)setDo_size:(CGSize)do_size
{
    self.frame = CGRectMake(self.do_x, self.do_y, do_size.width, do_size.height);
}

- (CGSize)do_size
{
    return self.frame.size;
}

@end
