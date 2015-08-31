//
//  LabeledCollectionUtil.h
//  CollectionLayoutTest
//
//  Created by kura on 2015/08/31.
//  Copyright (c) 2015年 kura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class SectionIndexView;

@interface LabeledCollectionUtil : NSObject

@property (nonatomic, assign) CGFloat paddingTop;           // default 50
@property (nonatomic, assign) CGFloat paddingBottom;        // default 50
@property (nonatomic, assign) CGFloat marginOfLine;         // default 30
@property (nonatomic, assign) CGFloat sectionLabelHeight;   // default 30
@property (nonatomic, assign) CGFloat dividerViewHeight;    // default 10
@property (nonatomic, assign) CGFloat basicCellHeight;      // default 150

@property (nonatomic, assign) Class dividerViewClass;

@property (nonatomic, weak) SectionIndexView *sectionIndexView;

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout;

#pragma mark - 委譲用メソッド

- (void)prepareLayout;
- (CGSize)collectionViewContentSize;
- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect;
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath;
- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath;
- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath;
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds;

@end
