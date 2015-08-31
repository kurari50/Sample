//
//  SectionIndexView.m
//  CollectionLayoutTest
//
//  Created by kura on 2015/08/31.
//  Copyright (c) 2015年 kura. All rights reserved.
//

#import "SectionIndexView.h"

@implementation SectionIndex

@end

@implementation SectionIndexView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = self.frame;
    
    CGFloat w = frame.size.width;
    CGFloat h = frame.size.height;
    CGFloat indexCharHeight = 20;
    
    NSArray *sectionIndexArray = self.sectionIndexArray;
    NSUInteger sectionIndexCount = sectionIndexArray.count;
    CGFloat marginHeight = 0;
//    if (sectionIndexCount == 0 || sectionIndexCount == 1) {
//        marginHeight = (h - (indexCharHeight * sectionIndexCount));
//    } else {
        marginHeight = (h - (indexCharHeight * sectionIndexCount)) / (sectionIndexCount + 1);
//    }
    
    NSAssert(indexCharHeight * sectionIndexCount < h, @"");
    
    for (int i = 0; i < sectionIndexCount; i++) {
        UIView *v = self.subviews[i];
        CGRect f = v.frame;
        f.size = CGSizeMake(w, indexCharHeight);
//        f.origin = CGPointMake(0, i * (marginHeight + indexCharHeight));
        f.origin = CGPointMake(0, (i + 1) * marginHeight + i * indexCharHeight);
        v.frame = f;
    }
}

- (void)setSectionIndexArray:(NSArray *)sectionIndexArray
{
    _sectionIndexArray = sectionIndexArray;
    
    for (UIView *v in self.subviews) {
        [v removeFromSuperview];
    }
    
    for (SectionIndex *i in sectionIndexArray) {
        UILabel *label = [[UILabel alloc] init];
        label.text = i.indexChar;
        [self addSubview:label];
    }
    
    [self setNeedsLayout];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    UITouch *t = touches.anyObject;
    
    [self scrollWithSectionIndexTouch:t];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    
    UITouch *t = touches.anyObject;
    
    [self scrollWithSectionIndexTouch:t];
}

- (void)scrollWithSectionIndexTouch:(UITouch *)touch
{
    CGPoint p = [touch locationInView:self];
    for (int i = 0; i < self.subviews.count; i++) {
        UIView *v = self.subviews[i];
        if (CGRectContainsPoint(v.frame, p)) {
            [self scrollWithSectionIndex:self.sectionIndexArray[i]];
            break;
        }
    }
}

- (void)scrollWithSectionIndex:(SectionIndex *)sectionIndex
{
    id<SectionIndexViewDelegate> d = self.delegate;
    if (d) {
        [d sectionIndexView:self didChangeSelectedSectionIndex:sectionIndex];
    }
}

@end
