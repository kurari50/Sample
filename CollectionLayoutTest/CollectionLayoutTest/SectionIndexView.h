//
//  SectionIndexView.h
//  CollectionLayoutTest
//
//  Created by kura on 2015/08/31.
//  Copyright (c) 2015年 kura. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SectionIndex, SectionIndexView;

@protocol SectionIndexViewDelegate

- (void)sectionIndexView:(SectionIndexView *)sectionIndexView didChangeSelectedSectionIndex:(SectionIndex *)sectionIndex;

@end

@interface SectionIndex : NSObject

@property (nonatomic, copy) NSString *indexChar;
@property (nonatomic, assign) CGFloat offset;
@property (nonatomic, assign) NSInteger section;

@end

@interface SectionIndexView : UIView

@property (nonatomic, copy) NSArray/* SectionIndex */ *sectionIndexArray;
@property (nonatomic, weak) id<SectionIndexViewDelegate> delegate;

@end
