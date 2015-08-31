//
//  LabeledCollectionUtil.m
//  CollectionLayoutTest
//
//  Created by kura on 2015/08/31.
//  Copyright (c) 2015年 kura. All rights reserved.
//

#import "LabeledCollectionUtil.h"
#import "SectionIndexView.h"

@interface LabeledCollectionUtil ()

@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic, weak) UICollectionViewLayout *layout;

@property (nonatomic, assign) CGFloat contentSizeHeight;

@property (nonatomic, strong) NSMutableArray *sectionElements;
@property (nonatomic, strong) NSMutableDictionary *supplementaryViewElements;

@end

@implementation LabeledCollectionUtil

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [self init];
    if (self) {
        _layout = layout;
        _collectionView = layout.collectionView;
        
        _paddingTop = 50;
        _paddingBottom = 50;
        _marginOfLine = 30;
        _sectionLabelHeight = 30;
        _dividerViewHeight = 10;
        _basicCellHeight = 150;
    }
    return self;
}

- (CGRect)dividerViewFrameShowedSection:(NSInteger)showedSection section:(NSInteger)section
{
    CGFloat y = self.paddingTop;
    y += showedSection * self.sectionLabelHeight;
    y += (section + 1) * self.basicCellHeight;
    y += (section) * self.marginOfLine;
    
    CGSize collectionViewSize = self.collectionView.bounds.size;
    return CGRectMake(0, y, collectionViewSize.width, self.dividerViewHeight);
}

- (UIView *)partBackgroundShowedSection:(NSInteger)showedSection
{
    UIView *v = [[UIView alloc] initWithFrame:self.collectionView.bounds];
    v.backgroundColor = [UIColor clearColor];
    
    for (NSInteger i = showedSection;; i++) {
        if (self.dividerViewClass == nil) {
            continue;
        }
        
        UIView *divider = [[self.dividerViewClass alloc] init];
        divider.frame = [self dividerViewFrameShowedSection:showedSection section:i];
        [v addSubview:divider];
        
        if (CGRectGetMaxY(divider.frame) > self.collectionView.bounds.size.height) {
            break;
        }
    }
    
    return v;
}

- (UIView *)emptyBackground
{
    return [self partBackgroundShowedSection:0];
}

- (CGFloat)offsetOfSection:(NSInteger)section
{
    NSArray *headers = self.supplementaryViewElements[UICollectionElementKindSectionHeader];
    UICollectionViewLayoutAttributes *attr = headers[section];
    return attr.frame.origin.y;
}

- (void)setSectionIndexView:(SectionIndexView *)sectionIndexView
{
    _sectionIndexView = sectionIndexView;
    
    [self updateSectionIndexViewOffset];
}

- (void)updateSectionIndexViewOffset
{
    NSArray *headers = self.supplementaryViewElements[UICollectionElementKindSectionHeader];
    NSArray *sectionIndexArray = self.sectionIndexView.sectionIndexArray;
    for (int i = 0; i < headers.count && i < sectionIndexArray.count; i++) {
        ((SectionIndex *)sectionIndexArray[i]).offset = [self offsetOfSection:i];
    }
}

+ (id<UICollectionViewDelegateFlowLayout>)delegateWithCollectionView:(UICollectionView *)collectionView
{
    __strong id<UICollectionViewDelegateFlowLayout> layout = nil;
    __strong id<UICollectionViewDelegate> delegate = collectionView.delegate;
    if ([delegate conformsToProtocol:@protocol(UICollectionViewDelegateFlowLayout)]) {
        layout = (id<UICollectionViewDelegateFlowLayout>)delegate;
    }
    return layout;
}

- (id<UICollectionViewDelegateFlowLayout>)delegate
{
    return [LabeledCollectionUtil delegateWithCollectionView:self.collectionView];
}

+ (CGSize)sizeWithIndexPath:(NSIndexPath *)indexPath delegate:(id<UICollectionViewDelegateFlowLayout>)delegate layout:(UICollectionViewLayout *)layout
{
    CGSize size = CGSizeMake(44, 44);
    
    if ([delegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]) {
        size = [delegate collectionView:layout.collectionView layout:layout sizeForItemAtIndexPath:indexPath];
    }
    
    return size;
}

- (CGSize)sizeWithIndexPath:(NSIndexPath *)indexPath
{
    return [LabeledCollectionUtil sizeWithIndexPath:indexPath delegate:self.delegate layout:self.layout];
}

+ (CGFloat)minimumLineSpacingForSectionAtIndex:(NSInteger)section delegate:(id<UICollectionViewDelegateFlowLayout>)delegate layout:(UICollectionViewLayout *)layout
{
    CGFloat minimumLineSpacing = 0;
    
    if ([delegate respondsToSelector:@selector(collectionView:layout:minimumLineSpacingForSectionAtIndex:)]) {
        minimumLineSpacing = [delegate collectionView:layout.collectionView layout:layout minimumLineSpacingForSectionAtIndex:section];
    }
    
    return minimumLineSpacing;
}

- (CGFloat)minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return [LabeledCollectionUtil minimumLineSpacingForSectionAtIndex:section delegate:self.delegate layout:self.layout];
}

+ (UICollectionViewLayoutAttributes *)attrWithIndexPath:(NSIndexPath *)indexPath
{
    return [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
}

+ (UICollectionViewLayoutAttributes *)headerAttrWithIndexPath:(NSIndexPath *)indexPath
{
    return [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:indexPath];
}

+ (UICollectionViewLayoutAttributes *)dividerAttrWithIndexPath:(NSIndexPath *)indexPath
{
//    return [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:@"divider" withIndexPath:indexPath];
    return [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:@"divider" withIndexPath:indexPath];
}

- (void)prepareLayout
{
    UICollectionView *collectionView = self.collectionView;
    CGSize collectionViewSize = collectionView.frame.size;
    
    NSMutableArray *sectionElements = [@[] mutableCopy];
    NSMutableDictionary *supplementaryViewElements = [@{} mutableCopy];
    self.sectionElements = sectionElements;
    self.supplementaryViewElements = supplementaryViewElements;
    
    CGFloat paddingTop = self.paddingTop;
    CGFloat paddingBottom = self.paddingBottom;
    CGFloat marginOfLine = self.marginOfLine;
    CGFloat sectionLabelHeight = self.sectionLabelHeight;
    CGFloat dividerViewHeight = self.dividerViewHeight;
    
    BOOL fitSide = NO;
    
    CGFloat x = 0, y = paddingTop;
    
    BOOL isTopSection = YES;
    NSInteger sectionCount = collectionView.numberOfSections;
    for (NSInteger i = 0; i < sectionCount; i++) {
        NSInteger itemCount = [collectionView numberOfItemsInSection:i];
        if (itemCount == 0) {
            [sectionElements addObject:@[]];
            continue;
        }
        
        NSMutableArray *array = [@[] mutableCopy];
        
        x = 0;
        y += sectionLabelHeight;
        if (!isTopSection) {
            y += [self minimumLineSpacingForSectionAtIndex:(i - 1)];
        }
        isTopSection = NO;
        
        CGFloat widthBetweenCells = 0;
        CGFloat widthHalfBetweenCells = 0;
        CGFloat maxCellHeight = 0;
        NSInteger count = 0;
        NSInteger index = 0;
        
        for (NSInteger j = 0; j < itemCount; j++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:j inSection:i];
            UICollectionViewLayoutAttributes *attr = [LabeledCollectionUtil attrWithIndexPath:indexPath];
            CGSize size = [self sizeWithIndexPath:indexPath];
            
            // y座標変更
            if ((x + size.width) > collectionViewSize.width) {
                if (fitSide) {
                    widthBetweenCells = (collectionViewSize.width - x) / (count - 1);
                } else {
                    widthHalfBetweenCells = (collectionViewSize.width - x) / (count * 2);
                }
                for (NSInteger k = 0; k < count; k++) {
                    if (fitSide) {
                        if (k == 0) continue;
                    }
                    
                    UICollectionViewLayoutAttributes *attr = array[index + k];
                    if (fitSide) {
                        attr.center = CGPointMake(attr.center.x + widthBetweenCells * k, attr.center.y);
                    } else {
                        CGFloat d = 0;
                        if (k == 0) {
                            d = widthHalfBetweenCells;
                        } else {
                            d = widthHalfBetweenCells + (widthHalfBetweenCells * 2) * k;
                        }
                        attr.center = CGPointMake(attr.center.x + d, attr.center.y);
                    }
                }
                
                x = 0;
                y += maxCellHeight + marginOfLine;
                maxCellHeight = 0;
                count = 0;
                index = j;
            }
            
            attr.size = size;
            attr.center = CGPointMake(x + size.width / 2.0, y + size.height / 2.0);
            
            [array addObject:attr];
            
            // 最大値判定
            if (maxCellHeight < size.height) {
                maxCellHeight = size.height;
            }
            count++;
            
            // x座標変更
            x += size.width;
        }
        y += maxCellHeight;
        
        // 改行されなかった場合、座標を決めるためにwidthBetweenCellsを計算
        if (widthHalfBetweenCells == 0 && widthBetweenCells == 0 && array.count) {
            UICollectionViewLayoutAttributes *attr = array[0];
            CGSize size = attr.size;
            
            CGFloat x = 0;
            NSInteger count = 0;
            while ((x + size.width) < collectionViewSize.width) {
                x += size.width;
                count++;
            }
            
            if (fitSide) {
                widthBetweenCells = (collectionViewSize.width - x) / (count - 1);
            } else {
                widthHalfBetweenCells = (collectionViewSize.width - x) / (count * 2);
            }
        }
        
        // 座標を更新
        for (NSInteger j = index, len = array.count; j < len; j++) {
            if (fitSide) {
                if (j == index) continue;
            }
            
            UICollectionViewLayoutAttributes *attr = array[j];
            if (fitSide) {
                attr.center = CGPointMake(attr.center.x + widthBetweenCells * (j - index), attr.center.y);
            } else {
                CGFloat d = 0;
                if (j == index) {
                    d = widthHalfBetweenCells;
                } else {
                    d = widthHalfBetweenCells + (widthHalfBetweenCells * 2) * (j - index);
                }
                attr.center = CGPointMake(attr.center.x + d, attr.center.y);
            }
        }
        
        [sectionElements addObject:array];
    }
    
    // セクションラベル
    NSMutableArray *array = [@[] mutableCopy];
    for (NSInteger i = 0; i < sectionCount; i++) {
        NSInteger itemCount = [collectionView numberOfItemsInSection:i];
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:i];
        
        if (itemCount == 0) {
            UICollectionViewLayoutAttributes *attr = [LabeledCollectionUtil headerAttrWithIndexPath:indexPath];
            [array addObject:attr];
        } else {
            UICollectionViewLayoutAttributes *sectionTopAttr = [self layoutAttributesForItemAtIndexPath:indexPath];
            
            UICollectionViewLayoutAttributes *attr = [LabeledCollectionUtil headerAttrWithIndexPath:indexPath];
            attr.size = CGSizeMake(collectionViewSize.width, sectionLabelHeight);
            attr.center = CGPointMake(collectionViewSize.width / 2, sectionTopAttr.frame.origin.y - attr.size.height / 2);
            [array addObject:attr];
        }
        
        supplementaryViewElements[UICollectionElementKindSectionHeader] = array;
    }
    
    // 区切り
    array = [@[] mutableCopy];
    CGFloat currentY = -1;
    for (NSInteger i = 0; i < sectionCount; i++) {
        NSInteger itemCount = [collectionView numberOfItemsInSection:i];
        for (NSInteger j = 0; j < itemCount; j++) {
            UICollectionViewLayoutAttributes *attr = sectionElements[i][j];
            if (attr.frame.origin.y != currentY) {
                currentY = attr.frame.origin.y;
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:j inSection:i];
                UICollectionViewLayoutAttributes *dividerAttr = [LabeledCollectionUtil dividerAttrWithIndexPath:indexPath];
                dividerAttr.size = CGSizeMake(collectionViewSize.width, dividerViewHeight);
                dividerAttr.center = CGPointMake(collectionViewSize.width / 2, CGRectGetMaxY(attr.frame) + dividerAttr.size.height / 2);
                [array addObject:dividerAttr];
                supplementaryViewElements[@"divider"] = array;
            }
        }
    }
    
    // 要素が少ない場合でも画面内は区切りを表示する
    UICollectionViewLayoutAttributes *lastDividerAttr = [supplementaryViewElements[@"divider"] lastObject];
    if (CGRectGetMaxY(lastDividerAttr.frame) < collectionViewSize.height) {
        int tag = 9328932;
        
        [[self.collectionView viewWithTag:tag] removeFromSuperview];
        
        UIView *bg = [self partBackgroundShowedSection:sectionCount];
        bg.tag = tag;
        [self.collectionView addSubview:bg];
        [self.collectionView sendSubviewToBack:bg];
    }
    
    self.contentSizeHeight = y + paddingBottom;
    [self updateSectionIndexViewOffset];
}

- (CGSize)collectionViewContentSize
{
    CGSize size = CGSizeMake(self.collectionView.bounds.size.width, self.contentSizeHeight);
    return size;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *ret = [@[] mutableCopy];
    
    NSInteger sectionCount = self.collectionView.numberOfSections;
    for (NSInteger i = 0; i < sectionCount; i++) {
        NSInteger itemCount = [self.collectionView numberOfItemsInSection:i];
        for (NSInteger j = 0; j < itemCount; j++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:j inSection:i];
            UICollectionViewLayoutAttributes *attr = [self layoutAttributesForItemAtIndexPath:indexPath];
            if (CGRectIntersectsRect(rect, attr.frame)) {
                [ret addObject:attr];
            }
        }
    }
    
    for (NSInteger i = 0; i < sectionCount; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:i];
        UICollectionViewLayoutAttributes *attr = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];
        if (CGRectIntersectsRect(rect, attr.frame)) {
            [ret addObject:attr];
        }
    }
    
    NSInteger len = [self.supplementaryViewElements[@"divider"] count];
    for (NSInteger i = 0; i < len; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:i];
//        UICollectionViewLayoutAttributes *attr = [self layoutAttributesForSupplementaryViewOfKind:@"divider" atIndexPath:indexPath];
        UICollectionViewLayoutAttributes *attr = [self layoutAttributesForDecorationViewOfKind:@"divider" atIndexPath:indexPath];
        if (CGRectIntersectsRect(rect, attr.frame)) {
            [ret addObject:attr];
        }
    }
    
    return [ret copy];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.sectionElements[indexPath.section][indexPath.item];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    return self.supplementaryViewElements[elementKind][indexPath.section];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    return self.supplementaryViewElements[elementKind][indexPath.section];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

@end
