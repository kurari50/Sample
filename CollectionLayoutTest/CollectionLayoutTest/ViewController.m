//
//  ViewController.m
//  CollectionLayoutTest
//
//  Created by kura on 2015/08/16.
//  Copyright (c) 2015年 kura. All rights reserved.
//

#import "ViewController.h"
#import "LabeledCollectionUtil.h"
#import "SectionIndexView.h"

@interface DividerView : UIView
@end
@implementation DividerView
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor yellowColor];
    }
    return self;
}
@end

@interface CollectionViewLayout : UICollectionViewLayout

@property (nonatomic, strong) LabeledCollectionUtil *util;
@property (nonatomic, weak) SectionIndexView *sectionIndexView;

@end
@implementation CollectionViewLayout

//- (CGFloat)offsetOfSection:(NSInteger)section
//{
//    return [self.util offsetOfSection:section];
//}

- (void)prepareLayout
{
    [super prepareLayout];
    
    self.util = [[LabeledCollectionUtil alloc] initWithCollectionViewLayout:self];
    [self.util setSectionIndexView:self.sectionIndexView];
    self.util.dividerViewClass = [DividerView class];
    [self.util prepareLayout];
}

- (CGSize)collectionViewContentSize
{
    return [self.util collectionViewContentSize];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    return [self.util layoutAttributesForElementsInRect:rect];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.util layoutAttributesForItemAtIndexPath:indexPath];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    return [self.util layoutAttributesForSupplementaryViewOfKind:elementKind atIndexPath:indexPath];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    return [self.util layoutAttributesForDecorationViewOfKind:elementKind atIndexPath:indexPath];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return [self.util shouldInvalidateLayoutForBoundsChange:newBounds];
}

@end

@interface ViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SectionIndexViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"HeaderLable" bundle:nil]
          forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                 withReuseIdentifier:@"headerLable"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"HeaderLable" bundle:nil]
          forSupplementaryViewOfKind:@"divider"
                 withReuseIdentifier:@"divider"];
    [self.collectionView.collectionViewLayout registerNib:[UINib nibWithNibName:@"HeaderLable" bundle:nil]
                                  forDecorationViewOfKind:@"divider"];
    
    SectionIndexView *sectionIndexView = [[SectionIndexView alloc] init];
    sectionIndexView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    sectionIndexView.frame = CGRectMake(0, 0, 20, self.view.bounds.size.height);
    sectionIndexView.delegate = self;
    [self.view addSubview:sectionIndexView];
    
    NSMutableArray *array = [@[] mutableCopy];
    NSArray *t = @[@"あ", @"か", @"さ", @"た", @"な", @"は", @"ま", @"や", @"ら", @"わ"];
    for (int i = 0; i < self.collectionView.numberOfSections; i++) {
        if ([self.collectionView numberOfItemsInSection:i] == 0) {
            continue;
        }
        
        SectionIndex *si = [[SectionIndex alloc] init];
        si.indexChar = t[i];
        si.section = i;
        [array addObject:si];
    }
    sectionIndexView.sectionIndexArray = array;
    [(CollectionViewLayout *)self.collectionView.collectionViewLayout setSectionIndexView:sectionIndexView];
    
    dispatch_after(0, dispatch_get_main_queue(), ^{
        NSLog(@"reload");
        [self.collectionView reloadData];
    });
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(90, 150);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 10;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 50;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 4 * section + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    cell.backgroundColor = [UIColor redColor];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = nil;
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        identifier = @"headerLable";
    } else {
        identifier = @"divider";
    }
    UICollectionViewCell *cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:identifier forIndexPath:indexPath];
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        cell.backgroundColor = [UIColor blueColor];
    } else {
        cell.backgroundColor = [UIColor greenColor];
    }
    
    return cell;
}

- (void)sectionIndexView:(SectionIndexView *)sectionIndexView didChangeSelectedSectionIndex:(SectionIndex *)sectionIndex
{
    [self.collectionView setContentOffset:CGPointMake(0, sectionIndex.offset) animated:NO];
}

@end
