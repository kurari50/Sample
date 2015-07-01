//
//  DOTasker.m
//  Lib
//
//  Created by kura on 2015/02/06.
//  Copyright (c) 2015年 kura. All rights reserved.
//

#import "DOTasker.h"

const NSString *DOTaskerKeyTaskerIndex = @"DOTaskerKeyTaskerIndex";

typedef NS_ENUM(int, DOTaskerResultType) {
    DOTaskerResultTypeNotDetermined = 0,
    DOTaskerResultTypeSuccess,
    DOTaskerResultTypeFailure,
    DOTaskerResultTypeCancel,
    DOTaskerResultTypeException,
};

@interface DOTaskerResult : NSObject

@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, assign) DOTaskerResultType resultType;
@property (nonatomic, strong) NSException *exception;
@property (nonatomic, strong) NSError *error;

@end
@implementation DOTaskerResult
@end

@interface DOTasker ()

@property (nonatomic, copy) DOTaskBlock         taskBlock;
@property (nonatomic, copy) DOSuccessBlock      successBlock;
@property (nonatomic, copy) DOFailureBlock      failureBlock;
@property (nonatomic, copy) DOProgressBlock     progressBlock;
@property (nonatomic, copy) DOCancelBlock       cancelBlock;
@property (nonatomic, copy) DOExceptionBlock    exceptionBlock;
@property (nonatomic, copy) DOFinallyBlock      finallyBlock;
@property (nonatomic, copy) DOCancelledBlock    cancelledBlock;

@property (nonatomic, assign) BOOL alreadyStarted;
@property (nonatomic, assign) BOOL alreadyCallbacked;
@property (nonatomic, assign) BOOL taskBlockPassed;

@property (nonatomic, assign, readwrite) BOOL isCancelled;

@property (nonatomic, strong) DOTasker *nextTasker;
@property (nonatomic, strong) DOTasker *prevTasker;

@end

@implementation DOTasker

static int DOTasker_count;
static NSObject *DOTasker_lock;

- (instancetype)init
{
    self = [super init];
    if (self) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            DOTasker_lock = [[NSObject alloc] init];
        });
        
        @synchronized (DOTasker_lock) {
            DOTasker_count++;
            NSLog(@"DOTasker_count++ : %d %p", DOTasker_count, self);
        }
    }
    return self;
}

- (void)dealloc
{
    @synchronized (DOTasker_lock) {
        DOTasker_count--;
        NSLog(@"DOTasker_count-- : %d %p", DOTasker_count, self);
    }
}

+ (instancetype)taskerWithBlock:(DOTaskBlock)task
                        success:(DOSuccessBlock)success
                        failure:(DOFailureBlock)failure
                       progress:(DOProgressBlock)progress
                         cancel:(DOCancelBlock)cancel
                      exception:(DOExceptionBlock)exception
                        finally:(DOFinallyBlock)finally
{
    NSAssert(task, @"");
    NSAssert(success, @"");
    NSAssert(failure, @"");
    NSAssert(progress, @"");
    NSAssert(cancel, @"");
    NSAssert(exception, @"");
    NSAssert(finally, @"");
    
    DOTasker *tasker = [[DOTasker alloc] init];
    
    tasker.taskBlock        = task;
    tasker.successBlock     = success;
    tasker.failureBlock     = failure;
    tasker.progressBlock    = progress;
    tasker.cancelBlock      = cancel;
    tasker.exceptionBlock   = exception;
    tasker.finallyBlock     = finally;
    
    return tasker;
}

+ (id<DOTaskerCantCall>)taskerWithTaskers:(NSArray *)taskers
                                  success:(DOSuccessBlock)success
                                  failure:(DOFailureBlock)failure
                                 progress:(DOProgressBlock)progress
                                   cancel:(DOCancelBlock)cancel
                                exception:(DOExceptionBlock)exception
                                  finally:(DOFinallyBlock)finally;
{
    __block DOTasker *newTasker = [DOTasker taskerWithBlock:^(DOTasker *tasker, NSMutableDictionary *userInfo) {
        NSArray *results = nil; {
            NSMutableArray *t = [NSMutableArray arrayWithCapacity:taskers.count];
            for (int i = 0, len = (int)taskers.count; i < len; i++) {
                [t addObject:[[DOTaskerResult alloc] init]];
            }
            results = t;
        }
        
        [taskers enumerateObjectsUsingBlock:^(DOTasker *tasker, NSUInteger idx, BOOL *stop) {
            NSAssert([tasker isKindOfClass:[DOTasker class]], @"");
            
            ((DOTaskerResult *)results[idx]).resultType = DOTaskerResultTypeNotDetermined;
            
            ((DOTaskerResult *)results[idx]).index = idx;
            [userInfo setObject:@(idx) forKey:DOTaskerKeyTaskerIndex];
            
            // 結果をフックするように変更
            
            DOSuccessBlock orgSuccessBlock = tasker.successBlock;
            DOSuccessBlock newSuccessBlock = ^(DOTasker *tasker, NSMutableDictionary *userInfo) {
                if (orgSuccessBlock) {
                    orgSuccessBlock(tasker, userInfo);
                }
                
                ((DOTaskerResult *)results[idx]).resultType = DOTaskerResultTypeSuccess;
            };
            tasker.successBlock = newSuccessBlock;

            DOFailureBlock orgFailureBlock = tasker.failureBlock;
            DOFailureBlock newFailureBlock = ^(DOTasker *tasker, NSError *error, NSMutableDictionary *userInfo) {
                if (orgFailureBlock) {
                    orgFailureBlock(tasker, error, userInfo);
                }
                
                ((DOTaskerResult *)results[idx]).error = error;
                ((DOTaskerResult *)results[idx]).resultType = DOTaskerResultTypeFailure;
            };
            tasker.failureBlock = newFailureBlock;
            
            DOCancelBlock orgCancelBlock = tasker.cancelBlock;
            DOCancelBlock newCancelBlock = ^(DOTasker *tasker, NSMutableDictionary *userInfo) {
                if (orgCancelBlock) {
                    orgCancelBlock(tasker, userInfo);
                }
                
                ((DOTaskerResult *)results[idx]).resultType = DOTaskerResultTypeCancel;
            };
            tasker.cancelBlock = newCancelBlock;
            
            DOExceptionBlock orgExceptionBlock = tasker.exceptionBlock;
            DOExceptionBlock newExceptionBlock = ^(DOTasker *tasker, NSException *exception, NSMutableDictionary *userInfo) {
                if (orgExceptionBlock) {
                    orgExceptionBlock(tasker, exception, userInfo);
                }
                
                ((DOTaskerResult *)results[idx]).exception = exception;
                ((DOTaskerResult *)results[idx]).resultType = DOTaskerResultTypeException;
            };
            tasker.exceptionBlock = newExceptionBlock;
            
            DOFinallyBlock orgFinallyBlock = tasker.finallyBlock;
            DOFinallyBlock newFinallyBlock = ^(DOTasker *tasker, NSMutableDictionary *userInfo) {
                if (orgFinallyBlock) {
                    orgFinallyBlock(tasker, userInfo);
                }
                
                // 並列実行Taskerの全完了判定
                __block BOOL allFinished = YES;
                __block BOOL allSuccessed = YES;
                __block BOOL cancelled = NO;
                __block BOOL hasException = NO;
                __block int countOfNotFinished = 0;
                __block NSError *error = nil;
                __block NSException *exception = nil;
                [results enumerateObjectsUsingBlock:^(DOTaskerResult *r, NSUInteger idx, BOOL *stop) {
                    NSAssert([r isKindOfClass:[DOTaskerResult class]], @"");
                    
                    if (r.resultType != DOTaskerResultTypeSuccess) {
                        if (allSuccessed) {
                            allSuccessed = NO;
                        }
                    }
                    if (r.resultType == DOTaskerResultTypeCancel) {
                        if (!cancelled) {
                            cancelled = YES;
                        }
                    }
                    if (r.resultType == DOTaskerResultTypeException) {
                        if (!hasException) {
                            hasException = YES;
                        }
                        exception = r.exception;
                    }
                    if (r.resultType == DOTaskerResultTypeFailure) {
                        error = r.error;
                    }
                    if (r.resultType == DOTaskerResultTypeNotDetermined) {
                        countOfNotFinished++;
                        
                        if (allFinished) {
                            allFinished = NO;
                        }
                    }
                }];
                
                // progressはtasker単位で計算
                float total = (float)results.count;
                [newTasker callProgressWithProgress:(total - countOfNotFinished)/(total) userInfo:userInfo];
                
                if (allFinished) {
                    if (cancelled) {
                        // 一つでもcancelされたらcancel
                        [newTasker callCancelWithUserInfo:userInfo];
                    } else if (hasException) {
                        // 一つでもexceptionが発生したらexception
                        [newTasker callExceptionWithException:exception userInfo:userInfo];
                    } else {
                        if (allSuccessed) {
                            // 全て成功したらsuccess
                            [newTasker callSuccessWithUserInfo:userInfo];
                        } else {
                            // 一つでも失敗したらfailure
                            [newTasker callFailureWithError:error userInfo:userInfo];
                        }
                    }
                }
            };
            tasker.finallyBlock = newFinallyBlock;
            
            [tasker startWithUserInfo:userInfo];
        }];
    } success:success failure:failure progress:progress cancel:cancel exception:exception finally:finally];
    
    return newTasker;
}

- (void)cancel:(DOCancelledBlock)block
{
    NSAssert(block, @"");
    NSAssert(!self.isCancelled, @"");
    
    DOTasker *lastTasker = self.nextTasker;
    while (!self.prevTasker) {
        [lastTasker cancel:block];
        
        if (lastTasker.nextTasker == nil) {
            break;
        } else {
            lastTasker = lastTasker.nextTasker;
        }
    }
    
    if (self.alreadyCallbacked) {
        return;
    }
    
    self.cancelledBlock = block;
    
    self.isCancelled = YES;
    
    DOCancelExecBlock b = self.cancelExecBlock;
    if (b) {
        b(self);
    }
}

- (instancetype)nextTasker:(DOTasker *)nextTasker
{
    NSAssert(nextTasker, @"");
    
    DOTasker *lastTasker = self;
    while (YES) {
        if (lastTasker.nextTasker == nil) {
            break;
        } else {
            lastTasker = lastTasker.nextTasker;
        }
    }
    
    DOFinallyBlock org = lastTasker.finallyBlock;
    DOFinallyBlock b = ^(DOTasker *tasker, NSMutableDictionary *userInfo) {
        if (org) {
            org(tasker, userInfo);
        }
        
        [nextTasker startWithUserInfo:userInfo];
    };
    lastTasker.finallyBlock = b;
    
    lastTasker.nextTasker = nextTasker;
    nextTasker.prevTasker = lastTasker;
    
    return self;
}

- (void)startWithUserInfo:(NSMutableDictionary *)userInfo
{
    NSAssert(!self.alreadyCallbacked, @"");
    NSAssert(!self.alreadyStarted, @"");
    
    self.isCancelled = NO;
    self.alreadyStarted = YES;
    __block DOTasker *blockSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        DOTaskBlock b = blockSelf.taskBlock;
        if (b) {
            @try {
                if (blockSelf.isCancelled) {
                    [blockSelf callCancelWithUserInfo:userInfo];
                    return;
                }
                
                b(blockSelf, userInfo);
                
                if (blockSelf.isCancelled) {
                    [blockSelf callCancelWithUserInfo:userInfo];
                }
                
                self.taskBlockPassed = YES;
            }
            @catch (NSException *exception) {
                [blockSelf callExceptionWithException:exception userInfo:userInfo];
            }
            @finally {
            }
        } else {
            [blockSelf callFainallyWithUserInfo:userInfo];
        }
    });
}

- (void)callSuccessWithUserInfo:(NSMutableDictionary *)userInfo
{
    NSAssert(!self.alreadyCallbacked, @"");
    NSAssert(self.alreadyStarted, @"");
    if (self.isCancelled) {
        return;
    }
    NSAssert(!self.isCancelled, @"");
    
    __block DOTasker *blockSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        DOSuccessBlock b = blockSelf.successBlock;
        if (b) {
            b(blockSelf, userInfo);
        }
    });
    
    [self callFainallyWithUserInfo:userInfo];
}

- (void)callFailureWithError:(NSError *)error userInfo:(NSMutableDictionary *)userInfo
{
    NSAssert(!self.alreadyCallbacked, @"");
    NSAssert(self.alreadyStarted, @"");
    if (self.isCancelled) {
        return;
    }
    NSAssert(!self.isCancelled, @"");
    
    __block DOTasker *blockSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        DOFailureBlock b = blockSelf.failureBlock;
        if (b) {
            b(blockSelf, error, userInfo);
        }
    });
    
    [self callFainallyWithUserInfo:userInfo];
}

- (void)callProgressWithProgress:(float)progress userInfo:(NSMutableDictionary *)userInfo
{
    NSAssert(!self.alreadyCallbacked, @"");
    NSAssert(self.alreadyStarted, @"");
    if (self.isCancelled) {
        return;
    }
    NSAssert(!self.isCancelled, @"");
    
    __block DOTasker *blockSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        DOProgressBlock b = blockSelf.progressBlock;
        if (b) {
            b(blockSelf, progress, userInfo);
        }
    });
}

- (void)callCancelWithUserInfo:(NSMutableDictionary *)userInfo
{
    if (self.alreadyCallbacked) {
        return;
    }
    
    NSAssert(!self.alreadyCallbacked, @"");
    NSAssert(self.alreadyStarted, @"");
    NSAssert(self.isCancelled, @"");
    
    __block DOTasker *blockSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        DOCancelBlock b = blockSelf.cancelBlock;
        if (b) {
            b(blockSelf, userInfo);
        }
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        DOCancelledBlock b = blockSelf.cancelledBlock;
        if (b) {
            b(userInfo);
        }
    });
    
    [self callFainallyWithUserInfo:userInfo];
}

- (void)callExceptionWithException:(NSException *)exception userInfo:(NSMutableDictionary *)userInfo
{
    NSAssert(!self.alreadyCallbacked, @"");
    NSAssert(self.alreadyStarted, @"");
    NSAssert(!self.isCancelled, @"");
    
    __block DOTasker *blockSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        DOExceptionBlock b = blockSelf.exceptionBlock;
        if (b) {
            b(blockSelf, exception, userInfo);
        }
    });
    
    [self callFainallyWithUserInfo:userInfo];
}

- (void)callFainallyWithUserInfo:(NSMutableDictionary *)userInfo
{
    self.alreadyCallbacked = YES;
    
    __block DOTasker *blockSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        DOFinallyBlock b = blockSelf.finallyBlock;
        if (b) {
            b(blockSelf, userInfo);
        }
    });
}

@end
