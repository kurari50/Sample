//
//  DOTasker.h
//  Lib
//
//  Created by kura on 2015/02/06.
//  Copyright (c) 2015年 kura. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DOTasker;

typedef void (^DOTaskBlock)(DOTasker *tasker, NSMutableDictionary *userInfo);
typedef void (^DOSuccessBlock)(DOTasker *tasker, NSMutableDictionary *userInfo);
typedef void (^DOFailureBlock)(DOTasker *tasker, NSError *error, NSMutableDictionary *userInfo);
typedef void (^DOProgressBlock)(DOTasker *tasker, float progress, NSMutableDictionary *userInfo);
typedef void (^DOCancelBlock)(DOTasker *tasker, NSMutableDictionary *userInfo);
typedef void (^DOExceptionBlock)(DOTasker *tasker, NSException *exception, NSMutableDictionary *userInfo);
typedef void (^DOFinallyBlock)(DOTasker *tasker, NSMutableDictionary *userInfo);
typedef void (^DOCancelledBlock)(NSMutableDictionary *userInfo);
typedef void (^DOCancelExecBlock)(DOTasker *tasker);

@protocol DOTasker <NSObject>
@end

@protocol DOTaskerCantCall <NSObject>

@required

- (instancetype)nextTasker:(DOTasker *)tasker;

- (void)startWithUserInfo:(NSMutableDictionary *)userInfo;

- (void)cancel:(DOCancelledBlock)block;

@end

@interface DOTasker : NSObject <DOTaskerCantCall>

@property (nonatomic, assign, readonly) BOOL isCancelled;
@property (nonatomic, copy) DOCancelExecBlock cancelExecBlock;

+ (instancetype)taskerWithBlock:(DOTaskBlock)task
                        success:(DOSuccessBlock)success
                        failure:(DOFailureBlock)failure
                       progress:(DOProgressBlock)progress
                         cancel:(DOCancelBlock)cancel
                      exception:(DOExceptionBlock)exception
                        finally:(DOFinallyBlock)finally;

+ (id<DOTaskerCantCall>)taskerWithTaskers:(NSArray *)taskers
                                  success:(DOSuccessBlock)success
                                  failure:(DOFailureBlock)failure
                                 progress:(DOProgressBlock)progress
                                   cancel:(DOCancelBlock)cancel
                                exception:(DOExceptionBlock)exception
                                  finally:(DOFinallyBlock)finally;

+ (instancetype)taskerWithStartTasker:(DOTasker *)startTasker
                        successTasker:(DOTasker *)successTasker
                        failureTasker:(DOTasker *)failureTasker;

- (void)callSuccessWithUserInfo:(NSMutableDictionary *)userInfo;
- (void)callFailureWithError:(NSError *)error userInfo:(NSMutableDictionary *)userInfo;
- (void)callProgressWithProgress:(float)progress userInfo:(NSMutableDictionary *)userInfo;

@end
