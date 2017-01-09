//
//  CircleProgress.m
//  GridProgress
//
//  Created by kura on 2017/01/10.
//  Copyright © 2017年 kura. All rights reserved.
//

#import "CircleProgress.h"

@implementation CircleProgress

- (void)setup
{
    self.backgroundColor = [UIColor redColor];
    self.circleColor = [UIColor blueColor];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextBeginTransparencyLayer(context, NULL);
    
    CGContextSetFillColorWithColor(context, self.backgroundColor.CGColor);
    CGContextFillRect(context, rect);
    
    if (self.circleImage) {
        [self.circleImage drawInRect:rect];
    }
    
    CGFloat x = rect.origin.x + rect.size.width / 2.0;
    CGFloat y = rect.origin.y + rect.size.height / 2.0;
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, x, y);
    CGPathAddArc(path, NULL, x, y, x, -M_PI_2, -M_PI_2 + M_PI * 2 * self.progress, self.circleImage != 0);
    CGPathAddLineToPoint(path, NULL, x, y);
    CGContextAddPath(context, path);
    
    CGContextSetBlendMode(context, kCGBlendModeClear);
    CGContextSetFillColorWithColor(context, self.circleColor.CGColor);
    CGContextSetStrokeColorWithColor(context,[UIColor clearColor].CGColor);
    
    CGContextSetLineWidth(context, 0);
    CGContextDrawPath(context, kCGPathFillStroke);
    
    CGContextEndTransparencyLayer(context);
    CGContextRestoreGState(context);
}

@end
