//
//  MargeSortArray.m
//  EventSortTest
//
//  Created by kura on 2015/03/14.
//  Copyright (c) 2015年 kura. All rights reserved.
//

#import "MargeSortArray.h"

#define SORT_EACH_ADD       0
#define ENABLE_ASSERTION    0

@interface MargeSortArray ()

@property (nonatomic, assign, readwrite) BOOL isOverLimit;

@property (nonatomic, strong) NSMutableArray *pool;
@property (nonatomic, copy) NSComparator comparatorBlock;
@property (nonatomic, copy) NSArray *sortedArrayCache;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, assign) int limit;
@property (nonatomic, assign) NSUInteger countInPool;

@end

@implementation MargeSortArray

+ (instancetype)margeSortArrayWithLimit:(int)limit comparatorBlock:(NSComparator)comparatorBlock;
{
    MargeSortArray *r = [[MargeSortArray alloc] init];
    r.comparatorBlock = comparatorBlock;
    r.limit = limit;
    return r;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _pool = [NSMutableArray array];
        _queue = dispatch_queue_create("marge-sort-array-queue", NULL);
    }
    return self;
}

- (void)dealloc
{
    self.comparatorBlock = nil;
    self.pool = nil;
    self.queue = nil;
    self.sortedArrayCache = nil;
}

- (void)setCountInPool:(NSUInteger)countInPool
{
    _countInPool = countInPool;
    
    self.isOverLimit = (countInPool >= self.limit);
}

- (void)addObject:(id)object
{
#if SORT_EACH_ADD
    dispatch_sync(self.queue, ^{
        self.sortedArrayCache = nil;
        
#if SORT_EACH_ADD
        [self.pool addObject:object];
        self.pool = [[self.pool sortedArrayUsingComparator:self.comparatorBlock] mutableCopy];
        if (self.pool.count > self.limit) {
            [self.pool removeObjectsInRange:NSMakeRange(self.limit, self.pool.count - self.limit)];
        }
#else
#endif
    });
#else
    [self addSortedArray:@[object]];
#endif
}

- (void)addSortedArray:(NSArray *)array
{
    dispatch_sync(self.queue, ^{
        self.sortedArrayCache = nil;
#if SORT_EACH_ADD
        [self.pool addObjectsFromArray:array];
        self.pool = [[self.pool sortedArrayUsingComparator:self.comparatorBlock] mutableCopy];
        if (self.pool.count > self.limit) {
            [self.pool removeObjectsInRange:NSMakeRange(self.limit, self.pool.count - self.limit)];
        }
#else
        
#if ENABLE_ASSERTION
        NSAssert([[array sortedArrayUsingComparator:self.comparatorBlock] isEqualToArray:array], @"");
#endif
        
        if (array.count <= 10 && self.pool.count >= 2) {
            int poolIndex = 0;
            if ([self.pool[0] count] > [self.pool[1] count]) {
                poolIndex = 1;
            }
            int start = 0;
            for (int i = 0, len = (int)array.count; i < len; i++) {
                NSArray *p = self.pool[poolIndex];
                id a = array[i];
                
                NSIndexSet *is = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(start, p.count - start)];
                NSUInteger index = NSNotFound;
                if (self.comparatorBlock(a, p.lastObject) == NSOrderedAscending) {
                    index = [p indexOfObjectAtIndexes:is options:NSEnumerationConcurrent passingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                        return self.comparatorBlock(a, obj) == NSOrderedAscending;
                    }];
                    NSAssert(index != NSNotFound, @"");
                }
                
                NSMutableArray *new = nil;
                if ([p isKindOfClass:[NSMutableArray class]]) {
                    new = (NSMutableArray *)p;
                } else {
                    new = [p mutableCopy];
                }
            
                if (index < p.count) {
                    [new insertObject:a atIndex:index];
                    self.pool[poolIndex] = new;
                    start = (int)index + 1;
                } else {
                    [new addObjectsFromArray:[array subarrayWithRange:NSMakeRange(i, array.count - i)]];
                    self.pool[poolIndex] = new;
                    break;
                }
            }
            self.countInPool += array.count;
            
#if ENABLE_ASSERTION
            NSAssert([[self.pool[poolIndex] sortedArrayUsingComparator:self.comparatorBlock] isEqualToArray:self.pool[poolIndex]], @"");
#endif
        } else {
            [self.pool addObject:array];
            self.countInPool += array.count;
        }
        
        if (array.count <= 0) {
            [self sortPool];
        } else {
            [self sortPoolIfNeed];
        }
#endif
    });
}

- (NSArray *)sortedArray
{
    dispatch_sync(self.queue, ^{
        if (!self.sortedArrayCache) {
#if SORT_EACH_ADD
            self.sortedArrayCache = [self.pool sortedArrayUsingComparator:self.comparatorBlock];
            self.sortedArrayCache = [self.sortedArrayCache subarrayWithRange:NSMakeRange(0, self.limit)];
#else
            [self sortPool];
            self.sortedArrayCache = self.pool[0];
#endif
        }
    });
    
    return self.sortedArrayCache;
}

#pragma mark - Private

- (void)sortPoolIfNeed
{
    if (self.countInPool <= self.limit * 1.5) {
        return;
    }
    
    [self sortPool];
}

- (void)sortPool
{
#if ENABLE_ASSERTION
    NSAssert(dispatch_get_current_queue() == self.queue, @"");
#endif
    
//    NSTimeInterval start = [NSDate date].timeIntervalSince1970;
    
    NSMutableArray *sortedArray = [NSMutableArray array];
    
//    NSLog(@"pool count: %d", (int)self.pool.count);
//    for (NSArray *a in self.pool) {
//        NSLog(@"count: %d", (int)a.count);
//    }
    
    while (YES) {
        if (self.pool.count == 0) {
            break;
        }
        
        __block NSInteger minObjIndex = -1;
        __block NSInteger min2ObjIndex = -1;
        __block id obj = nil;
        __block id obj2 = nil;
        
//        NSTimeInterval start_one_loop = [NSDate date].timeIntervalSince1970;
        [self.pool enumerateObjectsUsingBlock:^(NSArray *a, NSUInteger idx, BOOL *stop) {
            if (!obj || self.comparatorBlock(obj, a[0]) == NSOrderedDescending) {
                if (obj2 && self.comparatorBlock(obj2, obj) == NSOrderedDescending) {
                    obj2 = obj;
                    min2ObjIndex = minObjIndex;
                }
                
                obj = a[0];
                minObjIndex = idx;
            }
            if (obj != a[0]) {
                if (!obj2 || self.comparatorBlock(obj2, a[0]) == NSOrderedDescending) {
                    obj2 = a[0];
                    min2ObjIndex = idx;
                }
            }
        }];
//        NSTimeInterval finish_one_loop = [NSDate date].timeIntervalSince1970;
//        NSLog(@"one loop time: %f sec", finish_one_loop - start_one_loop);
        
        [sortedArray addObject:obj];
        if ([self.pool[minObjIndex] count] == 1) {
            [self.pool removeObjectAtIndex:minObjIndex];
            if (minObjIndex < min2ObjIndex) {
                min2ObjIndex--;
            }
            
            if (min2ObjIndex >= 0) {
                [sortedArray addObject:self.pool[min2ObjIndex][0]];
                if ([self.pool[min2ObjIndex] count] == 1) {
                    [self.pool removeObjectAtIndex:min2ObjIndex];
                } else {
                    [self.pool[min2ObjIndex] removeObjectAtIndex:0];
                }
            }
            
            if (self.pool.count == 1) {
                [sortedArray addObjectsFromArray:self.pool[0]];
                [self.pool removeObjectAtIndex:0];
            }
        } else {
            [self.pool[minObjIndex] removeObjectAtIndex:0];
            
            if (min2ObjIndex >= 0) {
                if (self.comparatorBlock(self.pool[minObjIndex][0], self.pool[min2ObjIndex][0]) == NSOrderedAscending) {
#if 0
                    // 5.146270 sec
                    // 9.904212 sec
                    NSUInteger index = [self.pool[minObjIndex] indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                        return self.comparatorBlock(self.pool[min2ObjIndex][0], obj) == NSOrderedAscending;
                    }];
                    
                    if (index < [self.pool[minObjIndex] count]) {
                        NSRange range = NSMakeRange(0, index);
                        [sortedArray addObjectsFromArray:[self.pool[minObjIndex] subarrayWithRange:range]];
                        [self.pool[minObjIndex] removeObjectsInRange:range];
                    } else {
                        [sortedArray addObjectsFromArray:self.pool[minObjIndex]];
                        [self.pool removeObjectAtIndex:minObjIndex];
                    }
#else
                    // 5.240063 sec
                    // 9.431322 sec
                    while (self.comparatorBlock(self.pool[minObjIndex][0], self.pool[min2ObjIndex][0]) == NSOrderedAscending) {
                        [sortedArray addObject:self.pool[minObjIndex][0]];
                        
                        if ([self.pool[minObjIndex] count] == 1) {
                            [self.pool removeObjectAtIndex:minObjIndex];
                            break;
                        } else {
                            [self.pool[minObjIndex] removeObjectAtIndex:0];
                        }
                    }
#endif
                } else {
                    [sortedArray addObject:self.pool[min2ObjIndex][0]];
                    
                    if ([self.pool[min2ObjIndex] count] == 1) {
                        [self.pool removeObjectAtIndex:min2ObjIndex];
                    } else {
                        [self.pool[min2ObjIndex] removeObjectAtIndex:0];
                    }
                }
            }
        }
    }
    
#if ENABLE_ASSERTION
    NSAssert([[sortedArray sortedArrayUsingComparator:self.comparatorBlock] isEqualToArray:sortedArray], @"");
#endif
    
    if (sortedArray.count > self.limit) {
        [sortedArray removeObjectsInRange:NSMakeRange(self.limit, sortedArray.count - self.limit)];
    }
    [self.pool addObject:sortedArray];
    self.countInPool = sortedArray.count;
    
//    NSTimeInterval finish = [NSDate date].timeIntervalSince1970;
//    NSLog(@"marge sort time: %f sec", finish - start);
    
#if ENABLE_ASSERTION
    NSAssert(self.pool.count == 1, @"");
    NSAssert(self.pool.count <= self.limit, @"");
#endif
}

@end
