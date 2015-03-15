//
//  MargeSortArray.h
//  EventSortTest
//
//  Created by kura on 2015/03/14.
//  Copyright (c) 2015年 kura. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MargeSortArray : NSObject

@property (nonatomic, assign, readonly) BOOL isOverLimit;

+ (instancetype)margeSortArrayWithLimit:(int)limit comparatorBlock:(NSComparator)comparatorBlock;

- (void)addObject:(id)object;
- (void)addSortedArray:(NSArray *)array;

- (NSArray *)sortedArray;

@end
