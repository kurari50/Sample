//
//  NSObject+DOCreator.m
//  DOViewLayout
//
//  Created by kura on 2016/10/20.
//  Copyright © 2016年 kura. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NSObject+DOCreator.h"
#import <objc/runtime.h>

@interface UIViewController ()
- (void)DOCreator_didReceivePushEvent:(nullable NSNotification *)note;
@end

@implementation NSObject (DOCreator)

static NSDictionary *s_memory_DOCreator;
static id<DOCreatorDelegate> s_delegaate_DOCreator;

+ (void)setCreatorDelegate:(id<DOCreatorDelegate>)delegate
{
    s_delegaate_DOCreator = delegate;
}

+ (nullable instancetype)fromJsonObject:(nullable id)jsonObject
{
    if (jsonObject == nil || [jsonObject isKindOfClass:[NSNull class]]) {
        return nil;
    }
    
    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        return [self fromJsonDictionary:jsonObject];
    }
    if ([jsonObject isKindOfClass:[NSArray class]]) {
        return [self fromJsonArray:jsonObject];
    }
    if ([jsonObject isKindOfClass:[NSNumber class]]) {
        return [self fromJsonNumber:jsonObject];
    }
    if ([jsonObject isKindOfClass:[NSString class]]) {
        return [self fromJsonString:jsonObject];
    }
    
    return jsonObject;
}

+ (nullable instancetype)fromJsonDictionary:(nullable NSDictionary *)jsonDictionary
{
    return [self fromJsonDictionary:jsonDictionary useDelegate:YES];
}

+ (nullable instancetype)fromJsonDictionary:(nullable NSDictionary *)jsonDictionary useDelegate:(BOOL)useDelegate
{
    if (jsonDictionary == nil || [jsonDictionary isKindOfClass:[NSNull class]] || ![jsonDictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSObject *obj = nil;
    
    // delegateでのobjectの生成をサポートする
    id<DOCreatorDelegate> delegate = s_delegaate_DOCreator;
    if (delegate && useDelegate) {
        if (jsonDictionary.count == 1) {
            __block id ret = nil;
            [jsonDictionary enumerateKeysAndObjectsUsingBlock:^(id __nonnull key, id __nonnull obj, BOOL * __nonnull stop) {
                if ([key isKindOfClass:[NSString class]]) {
                    ret = [delegate createObjectWithKey:key object:obj defaultImplementationBlock:^id __nullable(NSString * __nullable key, id __nullable object) {
                        if (key && object) {
                            return [NSObject fromJsonDictionary:@{key : object} useDelegate:NO];
                        } else {
                            return nil;
                        }
                    }];
                }
            }];
            if (ret) {
                return ret;
            }
        }
    }
    
    if (jsonDictionary[DOCREATOR_KEY_EVAL]) {
        obj = [NSObject evalObject:jsonDictionary[DOCREATOR_KEY_EVAL]];
    }
    if (jsonDictionary[DOCREATOR_KEY_VIEW_CONTROLLER]) {
        obj = [UIViewController fromJsonObject:jsonDictionary[DOCREATOR_KEY_VIEW_CONTROLLER]];
    }
    if (jsonDictionary[DOCREATOR_KEY_VIEW]) {
        obj = [UIView fromJsonObject:jsonDictionary[DOCREATOR_KEY_VIEW]];
    }
    if (jsonDictionary[DOCREATOR_KEY_STRING]) {
        obj = [NSString fromJsonObject:jsonDictionary[DOCREATOR_KEY_STRING]];
    }
    if (jsonDictionary[DOCREATOR_KEY_COLOR]) {
        obj = [UIColor fromJsonObject:jsonDictionary[DOCREATOR_KEY_COLOR]];
    }
    if (jsonDictionary[DOCREATOR_KEY_IMAGE]) {
        obj = [UIImage fromJsonObject:jsonDictionary[DOCREATOR_KEY_IMAGE]];
    }
    if (jsonDictionary[DOCREATOR_KEY_DIMEN]) {
        obj = [DODimen fromJsonObject:jsonDictionary[DOCREATOR_KEY_DIMEN]];
    }
    
    if (obj == nil) {
        NSString *className = jsonDictionary[DOCREATOR_KEY_CLASS];
        if (className == nil) {
            NSLog(@"no class name");
            if ([[jsonDictionary class] isSubclassOfClass:self]) {
                return jsonDictionary;
            } else {
                return nil;
            }
        }
        
        Class clazz = NSClassFromString(className);
        if (clazz == nil) {
            NSLog(@"invalid class name : %@", clazz);
            return nil;
        }
        
        obj = [self objectInit:clazz];
        if (![[obj class] isSubclassOfClass:self]) {
            NSLog(@"invalid class type : %@", clazz);
            return nil;
        }
    }
    
    NSDictionary *property = jsonDictionary[DOCREATOR_KEY_PROPERTY];
    [self setPropertyTo:obj from:property];
    
    if ([obj isKindOfClass:[UIButton class]]) {
        // UIButton
        [(UIButton *)obj setEventWithDictionary:jsonDictionary[DOCREATOR_KEY_EVENT]];
    }
    if ([obj isKindOfClass:[UIViewController class]]) {
        // UIViewController
        [(UIViewController *)obj setPushEventReceiver];
    }
    
    return obj;
}

+ (nullable instancetype)fromJsonArray:(nullable NSArray *)jsonArray
{
    if (jsonArray == nil || [jsonArray isKindOfClass:[NSNull class]] || ![jsonArray isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
    NSMutableArray *array = [@[] mutableCopy];
    
    for (id t in jsonArray) {
        NSObject *obj = [self fromJsonObject:t];
        if (obj == nil) {
            NSAssert(NO, @"invalid json object");
        } else {
            [array addObject:obj];
        }
    }
    
    return array;
}

+ (nullable instancetype)fromJsonNumber:(nullable NSNumber *)jsonNumber
{
    if (jsonNumber == nil || [jsonNumber isKindOfClass:[NSNull class]] || ![jsonNumber isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    
    return jsonNumber;
}

+ (nullable instancetype)fromJsonString:(nullable id)jsonString
{
    if (jsonString == nil || [jsonString isKindOfClass:[NSNull class]]) {
        return nil;
    }
    
    if ([jsonString isKindOfClass:[NSString class]]) {
        id ret = nil;
        
        ret = [UIViewController fromJsonObject:[self memoryWith:jsonString type:DOCREATOR_KEY_VIEW_CONTROLLER]];
        if (ret) {
            return ret;
        }
        ret = [UIView fromJsonObject:[self memoryWith:jsonString type:DOCREATOR_KEY_VIEW]];
        if (ret) {
            return ret;
        }
        ret = [NSString fromJsonObject:[self memoryWith:jsonString type:DOCREATOR_KEY_STRING]];
        if (ret) {
            return ret;
        }
        ret = [UIColor fromJsonObject:[self memoryWith:jsonString type:DOCREATOR_KEY_COLOR]];
        if (ret) {
            return ret;
        }
        ret = [UIImage fromJsonObject:[self memoryWith:jsonString type:DOCREATOR_KEY_IMAGE]];
        if (ret) {
            return ret;
        }
        ret = [DODimen fromJsonObject:[self memoryWith:jsonString type:DOCREATOR_KEY_DIMEN]];
        if (ret) {
            return ret;
        }
        ret = [NSObject fromJsonObject:[self memoryWith:jsonString type:DOCREATOR_KEY_EVAL]];
        if (ret) {
            return ret;
        }
        
        return jsonString;
    }
    if ([jsonString isKindOfClass:[NSDictionary class]]) {
        id ret = [self evalObject:jsonString];
        if (ret) {
            return ret;
        }
        return jsonString;
    }
    
    return jsonString;
}

+ (nullable NSObject *)objectInit:(Class)clazz
{
    return [[clazz alloc] init];
}

+ (void)setPropertyTo:(nullable NSObject *)obj from:(nullable NSDictionary *)property
{
    if (obj == nil || property == nil || [property isKindOfClass:[NSNull class]] || ![property isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    NSMutableDictionary *objectProperty = [@{} mutableCopy];
    NSMutableDictionary *subObjectProperty = [@{} mutableCopy];
    NSMutableDictionary *subviewsProperty = [@{} mutableCopy];
    
    [property enumerateKeysAndObjectsUsingBlock:^(id __nonnull key, id __nonnull value, BOOL * __nonnull stop) {
        if (![key isKindOfClass:[NSString class]]) {
            return;
        }
        
        if ([key hasPrefix:@"//"]) {
            // コメント
        } else if ([key rangeOfString:@"."].location == NSNotFound) {
            if ([key isEqualToString:DOCREATOR_KEY_SUBVIEWS]) {
                subviewsProperty[key] = value;
            } else if ([key isEqualToString:DOCREATOR_KEY_EVENT]) {
                if ([obj isKindOfClass:[UIButton class]]) {
                    [(UIButton *)obj setEventWithDictionary:value];
                } else {
                    NSAssert(NO, @"");
                }
            } else {
                objectProperty[key] = [self fromJsonObject:value];
            }
        } else {
            NSArray *split = [key componentsSeparatedByString:@"."];
            NSString *subKey = [split subarrayWithRange:NSMakeRange(0, 1)][0];
            NSString *subValue = [[split subarrayWithRange:NSMakeRange(1, split.count - 1)] componentsJoinedByString:@"."];
            if (subObjectProperty[subKey] == nil) {
                subObjectProperty[subKey] = [@{subValue : value} mutableCopy];
            } else {
                subObjectProperty[subKey][subValue] = value;
            }
        }
    }];
    
    [subviewsProperty enumerateKeysAndObjectsUsingBlock:^(id __nonnull key, id __nonnull value, BOOL * __nonnull stop) {
        if (![key isKindOfClass:[NSString class]] || ![obj isKindOfClass:[UIView class]]) {
            return;
        }
        
        id view = [NSObject fromJsonObject:value];
        if ([view isKindOfClass:[NSArray class]]) {
            for (id v in view) {
                id t = [NSObject fromJsonObject:v];
                if (t == nil) {
                    NSAssert(NO, @"invalid subviews object");
                } else {
                    [(UIView *)obj addSubview:t];
                }
            }
        } else if ([view isKindOfClass:[UIView class]]) {
            [(UIView *)obj addSubview:view];
        } else {
            NSAssert(NO, @"invalid subviews object");
        }
    }];
    
    [subObjectProperty enumerateKeysAndObjectsUsingBlock:^(id __nonnull key, id __nonnull value, BOOL * __nonnull stop) {
        if (![key isKindOfClass:[NSString class]]) {
            return;
        }
        
        NSObject *subObject = nil;
        
        if ([key hasPrefix:DOCREATOR_KEY_SUBVIEWS]) {
            // indexでviewを指定してのプロパティの設定をサポートする
            if ([obj isKindOfClass:[UIView class]] || [obj isKindOfClass:[UIViewController class]]) {
                NSString *viewIndex = [[key componentsSeparatedByString:@"."][0] stringByReplacingOccurrencesOfString:DOCREATOR_KEY_SUBVIEWS withString:@""];
                if ([viewIndex hasPrefix:@"("] && [viewIndex hasSuffix:@")"] && viewIndex.length > 2) {
                    viewIndex = [viewIndex substringWithRange:NSMakeRange(1, viewIndex.length - 2)];
                    NSInteger viewIndexInteger = viewIndex.integerValue;
                    if ([[@(viewIndexInteger) description] isEqualToString:viewIndex]) {
                        if ([obj isKindOfClass:[UIView class]]) {
                            subObject = [(UIView *)obj subviews][viewIndexInteger];
                        } else if ([obj isKindOfClass:[UIViewController class]]) {
                            subObject = [[(UIViewController *)obj view] subviews][viewIndexInteger];
                        }
                    } else {
                        NSAssert(NO, @"");
                    }
                }
            }
        }
        if ([key hasPrefix:DOCREATOR_KEY_VIEW]) {
            // tagでviewを指定してのプロパティの設定をサポートする
            if ([obj isKindOfClass:[UIView class]] || [obj isKindOfClass:[UIViewController class]]) {
                NSString *viewTag = [[key componentsSeparatedByString:@"."][0] stringByReplacingOccurrencesOfString:DOCREATOR_KEY_VIEW withString:@""];
                if ([viewTag hasPrefix:@"("] && [viewTag hasSuffix:@")"] && viewTag.length > 2) {
                    viewTag = [viewTag substringWithRange:NSMakeRange(1, viewTag.length - 2)];
                    NSInteger viewTagInteger = viewTag.integerValue;
                    if (viewTagInteger != 0 && [[@(viewTagInteger) description] isEqualToString:viewTag]) {
                        if ([obj isKindOfClass:[UIView class]]) {
                            subObject = [(UIView *)obj viewWithTag:viewTagInteger];
                        } else if ([obj isKindOfClass:[UIViewController class]]) {
                            subObject = [[(UIViewController *)obj view] viewWithTag:viewTagInteger];
                        }
                    } else {
                        NSAssert(NO, @"");
                    }
                }
            }
        }
        if (subObject == nil) {
            subObject = [obj valueForKeyPath:key];
        }
        
        [self setPropertyTo:subObject from:value];
    }];
    
    [obj setValuesForKeysWithDictionary:objectProperty];
}

+ (nullable instancetype)memoryWith:(nullable NSString *)key type:(nullable NSString *)type
{
    return s_memory_DOCreator[type][key];
}

+ (void)setMemoryWith:(nullable NSString *)key type:(nullable NSString *)type value:(nullable NSObject *)value
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_memory_DOCreator = @{
                               DOCREATOR_KEY_EVAL : [@{} mutableCopy],
                               DOCREATOR_KEY_VIEW_CONTROLLER : [@{} mutableCopy],
                               DOCREATOR_KEY_VIEW : [@{} mutableCopy],
                               DOCREATOR_KEY_STRING : [@{} mutableCopy],
                               DOCREATOR_KEY_COLOR : [@{} mutableCopy],
                               DOCREATOR_KEY_IMAGE : [@{} mutableCopy],
                               DOCREATOR_KEY_DIMEN : [@{} mutableCopy],
                               };
    });
    
    if ([type isEqualToString:DOCREATOR_KEY_EVAL] && [value isKindOfClass:[NSDictionary class]]) {
        s_memory_DOCreator[type][key] = value;
    }
    if ([type isEqualToString:DOCREATOR_KEY_VIEW_CONTROLLER] && ([value isKindOfClass:[UIViewController class]] || [value isKindOfClass:[NSDictionary class]])) {
        s_memory_DOCreator[type][key] = value;
    }
    if ([type isEqualToString:DOCREATOR_KEY_VIEW] && ([value isKindOfClass:[UIView class]] || [value isKindOfClass:[NSDictionary class]])) {
        s_memory_DOCreator[type][key] = value;
    }
    if ([type isEqualToString:DOCREATOR_KEY_STRING] && ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSDictionary class]])) {
        s_memory_DOCreator[type][key] = value;
    }
    if ([type isEqualToString:DOCREATOR_KEY_COLOR] && ([value isKindOfClass:[UIColor class]] || [value isKindOfClass:[NSDictionary class]])) {
        s_memory_DOCreator[type][key] = value;
    }
    if ([type isEqualToString:DOCREATOR_KEY_IMAGE] && ([value isKindOfClass:[UIImage class]] || [value isKindOfClass:[NSDictionary class]])) {
        s_memory_DOCreator[type][key] = value;
    }
    if ([type isEqualToString:DOCREATOR_KEY_DIMEN] && [value isKindOfClass:[NSDictionary class]]) {
        s_memory_DOCreator[type][key] = value;
    }
}

+ (nullable instancetype)evalObject:(nullable NSDictionary *)evalObject
{
    if ([evalObject isKindOfClass:[NSString class]]) {
        return (NSString *)evalObject;
    }
    if ([evalObject isKindOfClass:[NSArray class]]) {
        __block NSObject *ret = nil;
        [(NSArray *)evalObject enumerateObjectsUsingBlock:^(id __nonnull obj, NSUInteger idx, BOOL * __nonnull stop) {
            ret = [self evalObject:obj];
        }];
        return ret;
    }
    
    if (evalObject[DOCREATOR_KEY_METHOD] == nil) {
        return nil;
    }
    
    Class clazz = NSClassFromString(evalObject[DOCREATOR_KEY_STATIC]);
    NSObject *obj = nil;
    if ([evalObject[DOCREATOR_KEY_OBJECT] isKindOfClass:[NSString class]]) {
        obj = [NSObject fromJsonString:evalObject[DOCREATOR_KEY_OBJECT]];
    } else if ([evalObject[DOCREATOR_KEY_OBJECT] isKindOfClass:[NSDictionary class]] && evalObject[DOCREATOR_KEY_OBJECT][DOCREATOR_KEY_EVAL]) {
        obj = [NSObject evalObject:evalObject[DOCREATOR_KEY_OBJECT][DOCREATOR_KEY_EVAL]];
    } else {
        obj = evalObject[DOCREATOR_KEY_OBJECT];
    }
    SEL selector = NSSelectorFromString(evalObject[DOCREATOR_KEY_METHOD]);
    
    NSMethodSignature *signature = nil;
    if (clazz) {
        signature = [clazz methodSignatureForSelector:selector];
    }
    if (obj) {
        signature = [[obj class] instanceMethodSignatureForSelector:selector];
    }
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    
    if (clazz) {
        [invocation setTarget:clazz];
    }
    if (obj) {
        [invocation setTarget:obj];
    }
    
    [evalObject[DOCREATOR_KEY_ARGS] enumerateObjectsUsingBlock:^(id __nonnull obj, NSUInteger idx, BOOL * __nonnull stop) {
        if ([obj isKindOfClass:[NSDictionary class]] && obj[DOCREATOR_KEY_EVAL]) {
            obj = [self fromJsonString:obj[DOCREATOR_KEY_EVAL]];
        } else {
            obj = [self fromJsonString:obj];
        }
        
        NSString *type = [NSString stringWithUTF8String:[signature getArgumentTypeAtIndex:2 + idx]];
        if ([type isEqualToString:@"d"]) {
            double d = [obj doubleValue];
            [invocation setArgument:&d atIndex:2 + idx];
        } else if ([type isEqualToString:@"f"]) {
            float f = [obj floatValue];
            [invocation setArgument:&f atIndex:2 + idx];
        } else if ([type isEqualToString:@"q"]) {
            long long q = [obj longLongValue];
            [invocation setArgument:&q atIndex:2 + idx];
        } else if ([type isEqualToString:@"i"]) {
            int i = [obj intValue];
            [invocation setArgument:&i atIndex:2 + idx];
        } else if ([type isEqualToString:@"B"]) {
            BOOL B = [obj boolValue];
            [invocation setArgument:&B atIndex:2 + idx];
        } else if ([type isEqualToString:@"@"]) {
            [invocation setArgument:&obj atIndex:2 + idx];
        }
    }];
    
    [invocation setSelector:selector];
    
    [invocation invoke];
    
    NSString *type = [NSString stringWithUTF8String:[signature methodReturnType]];
    if ([type isEqualToString:@"d"]) {
        double result;
        [invocation getReturnValue:&result];
        return @(result);
    } else if ([type isEqualToString:@"f"]) {
        float result;
        [invocation getReturnValue:&result];
        return @(result);
    } else if ([type isEqualToString:@"q"]) {
        long long result;
        [invocation getReturnValue:&result];
        return @(result);
    } else if ([type isEqualToString:@"i"]) {
        int result;
        [invocation getReturnValue:&result];
        return @(result);
    } else if ([type isEqualToString:@"B"]) {
        BOOL result;
        [invocation getReturnValue:&result];
        return @(result);
    } else if ([type isEqualToString:@"v"]) {
        return obj;
    } else if ([type isEqualToString:@"@"]) {
        CFTypeRef result;
        [invocation getReturnValue:&result];
        if (result) {
            CFRetain(result);
        }
        return (__bridge_transfer NSObject *)result;
    }
    
    NSAssert(NO, @"");
    return nil;
}

@end

@implementation UIButton (DOCreator)

- (void)setTitle:(nullable NSString *)title
{
    [self setTitle:title forState:UIControlStateNormal];
}

- (nullable NSString *)title
{
    return [self currentTitle];
}

- (nullable NSDictionary *)DOCreator_event
{
    return objc_getAssociatedObject(self, @selector(DOCreator_event));
}

- (void)setEventWithDictionary:(nullable NSDictionary *)eventDictionary
{
    if (eventDictionary.count == 0) {
        return;
    }
    if ([self DOCreator_event]) {
        [self removeTarget:self action:@selector(DOCreator_didPressButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
    }
    objc_setAssociatedObject(self, @selector(DOCreator_event), eventDictionary, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self addTarget:self action:@selector(DOCreator_didPressButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)DOCreator_didPressButtonEvent:(nullable id)sender
{
    NSDictionary *push = [self DOCreator_event][DOCREATOR_KEY_PUSH];
    if (push) {
        NSMutableArray *superviews = [@[] mutableCopy];
        UIView *rootView = sender;
        while (rootView.superview) {
            rootView = rootView.superview;
            [superviews addObject:rootView];
        }
        
        UIViewController *vc = [UIViewController fromJsonObject:push];
        if ([vc isKindOfClass:[UIViewController class]]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:DOCREATOR_PUSH_EVENT_NOTIFICATION_NAME object:nil userInfo:@{DOCREATOR_KEY_VIEW_CONTROLLER : vc, DOCREATOR_KEY_VIEW : superviews}];
        } else {
            NSAssert(NO, @"invalid push view controller");
        }
    }
    
    NSDictionary *eval = [self DOCreator_event][DOCREATOR_KEY_EVAL];
    if (eval) {
        [NSObject evalObject:eval];
    }
}

@end

@implementation UIViewController (DOCreator)

- (void)setPushEventReceiver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DOCREATOR_PUSH_EVENT_NOTIFICATION_NAME object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(DOCreator_didReceivePushEvent:) name:DOCREATOR_PUSH_EVENT_NOTIFICATION_NAME object:nil];
}

- (void)DOCreator_didReceivePushEvent:(nullable NSNotification *)note
{
    if ([note.name isEqualToString:DOCREATOR_PUSH_EVENT_NOTIFICATION_NAME]) {
        if ([note.userInfo[DOCREATOR_KEY_VIEW_CONTROLLER] isKindOfClass:[UIViewController class]]) {
            if ([note.userInfo[DOCREATOR_KEY_VIEW] isKindOfClass:[NSArray class]] && [note.userInfo[DOCREATOR_KEY_VIEW] containsObject:self.view]) {
                [self.navigationController pushViewController:note.userInfo[DOCREATOR_KEY_VIEW_CONTROLLER] animated:YES];
            }
            return;
        }
    }
    
    NSAssert(NO, @"invalid push view controller");
}

@end

@implementation UIView (DOCreator)

@end

@implementation UIColor (DOCreator)

+ (nullable instancetype)fromJsonObject:(nullable id)jsonObject
{
    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        return [self fromJsonObject:jsonObject[DOCREATOR_KEY_COLOR]];
    }
    
    NSString *str = [[NSString fromJsonString:jsonObject] description];
    return [self fromString:str];
}

+ (nullable instancetype)fromString:(nullable NSString *)string
{
    if ([self memoryWith:string type:DOCREATOR_KEY_COLOR]) {
        string = [self memoryWith:string type:DOCREATOR_KEY_COLOR];
    }
    
    NSScanner *colorScanner = [NSScanner scannerWithString:string];
    unsigned int color;
    if (![colorScanner scanHexInt:&color]) {
        return nil;
    }
    
    CGFloat A = ((color & 0xFF000000) >> 16) / 255.0f;
    CGFloat R = ((color & 0x00FF0000) >> 16) / 255.0f;
    CGFloat G = ((color & 0x0000FF00) >> 8) / 255.0f;
    CGFloat B = (color & 0x000000FF) / 255.0f;
    
    return [UIColor colorWithRed:R green:G blue:B alpha:A];
}

@end

@implementation NSString (DOCreator)

+ (nullable instancetype)fromJsonObject:(nullable id)jsonObject
{
    if (jsonObject == nil || [jsonObject isKindOfClass:[NSNull class]]) {
        return nil;
    }
    if ([jsonObject isKindOfClass:[NSArray class]]) {
        return nil;
    }
    if ([jsonObject isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    
    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        if (jsonObject[DOCREATOR_KEY_EVAL]) {
            return [self evalObject:jsonObject[DOCREATOR_KEY_EVAL]];
        } else if (jsonObject[DOCREATOR_KEY_STRING]) {
            return [self fromJsonObject:jsonObject[DOCREATOR_KEY_STRING]];
        } else {
            return [self fromFormat:jsonObject[DOCREATOR_KEY_FORMAT] args:jsonObject[DOCREATOR_KEY_ARGS]];
        }
    }
    if ([jsonObject isKindOfClass:[NSString class]]) {
        return [self fromJsonString:jsonObject];
    }
    
    NSAssert(NO, @"invalid json object");
    
    return nil;
}

+ (nullable instancetype)fromFormat:(nullable NSString *)format args:(nullable NSArray *)args
{
    if (format == nil || ![format isKindOfClass:[NSString class]] || ![args isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
    if ([self memoryWith:format type:DOCREATOR_KEY_STRING]) {
        format = [self memoryWith:format type:DOCREATOR_KEY_STRING];
    }
    
    if ([args count] == 0) {
        return format;
    }
    
    NSMutableArray *argList = [@[] mutableCopy];
    [args enumerateObjectsUsingBlock:^(NSDictionary * __nonnull obj, NSUInteger idx, BOOL * __nonnull stop) {
        [argList addObject:[self fromJsonString:obj]];
    }];
    
#define AAAAAAAAA(_i)       (argList.count>_i) ? [argList objectAtIndex:_i]: nil
    return [NSMutableString stringWithFormat:format,
            AAAAAAAAA(0),
            AAAAAAAAA(1),
            AAAAAAAAA(2),
            AAAAAAAAA(3),
            AAAAAAAAA(4),
            AAAAAAAAA(5),
            AAAAAAAAA(6),
            AAAAAAAAA(7),
            AAAAAAAAA(8),
            AAAAAAAAA(9),
            AAAAAAAAA(10),
            AAAAAAAAA(11),
            AAAAAAAAA(12),
            AAAAAAAAA(13),
            AAAAAAAAA(14),
            AAAAAAAAA(15),
            AAAAAAAAA(16),
            AAAAAAAAA(17),
            AAAAAAAAA(18),
            AAAAAAAAA(19),
            AAAAAAAAA(20)
            ];
}

@end

@implementation UIImage (DOCreator)

+ (nullable instancetype)fromJsonObject:(nullable id)jsonObject
{
    if (jsonObject == nil || [jsonObject isKindOfClass:[NSNull class]]) {
        return nil;
    }
    if ([jsonObject isKindOfClass:[NSArray class]]) {
        return nil;
    }
    if ([jsonObject isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    
    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        return [self imageWithName:jsonObject[DOCREATOR_KEY_NAME] capInsets:jsonObject[DOCREATOR_KEY_CAP_INSETS] resizingMode:jsonObject[DOCREATOR_KEY_RESIZING_MODE]];
    }
    if ([jsonObject isKindOfClass:[NSString class]]) {
        return [self imageWithName:jsonObject capInsets:nil resizingMode:nil];
    }
    
    NSAssert(NO, @"invalid json object");
    
    return nil;
}

+ (nullable UIImage *)imageWithName:(nullable NSString *)name capInsets:(nullable NSString *)capInsets resizingMode:(nullable NSNumber *)resizingMode
{
    if (name == nil || ![name isKindOfClass:[NSString class]]) {
        return nil;
    }
    
    UIImage *image = [self memoryWith:name type:DOCREATOR_KEY_IMAGE];
    if (image == nil) {
        image = [UIImage imageNamed:name];
    }
    if (capInsets && resizingMode) {
        image = [image resizableImageWithCapInsets:UIEdgeInsetsFromString(capInsets) resizingMode:[resizingMode intValue]];
    } else if (capInsets) {
        image = [image resizableImageWithCapInsets:UIEdgeInsetsFromString(capInsets)];
    }
    return image;
}

@end

@implementation DODimen

+ (nullable instancetype)fromJsonObject:(nullable id)jsonObject
{
    if (jsonObject == nil || [jsonObject isKindOfClass:[NSNull class]]) {
        return nil;
    }
    if ([jsonObject isKindOfClass:[NSArray class]]) {
        return nil;
    }
    if ([jsonObject isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    if ([jsonObject isKindOfClass:[NSString class]]) {
        return nil;
    }
    
    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        if (jsonObject[DOCREATOR_KEY_DIMEN]) {
            return [self fromJsonObject:jsonObject[DOCREATOR_KEY_DIMEN]];
        } else {
            DODimen *dimen = [self memoryWith:jsonObject[DOCREATOR_KEY_NAME] type:DOCREATOR_KEY_DIMEN];
            if (dimen == nil) {
                dimen = [[DODimen alloc] init];
                dimen.dictionary = jsonObject;
            }
            return dimen;
        }
    }
    
    NSAssert(NO, @"invalid json object");
    
    return nil;
}

- (BOOL)hasWidth
{
    return [self.dictionary objectForKey:DOCREATOR_KEY_WIDTH];
}

- (CGFloat)width
{
    return [[self.dictionary objectForKey:DOCREATOR_KEY_WIDTH] floatValue];
}

- (BOOL)hasHeight
{
    return [self.dictionary objectForKey:DOCREATOR_KEY_HEIGTH];
}

- (CGFloat)height
{
    return [[self.dictionary objectForKey:DOCREATOR_KEY_HEIGTH] floatValue];
}

- (BOOL)hasMarginTop
{
    return [self.dictionary objectForKey:DOCREATOR_KEY_MARGIN_TOP];
}

- (CGFloat)marginTop
{
    return [[self.dictionary objectForKey:DOCREATOR_KEY_MARGIN_TOP] floatValue];
}

- (BOOL)hasMarginLeft
{
    return [self.dictionary objectForKey:DOCREATOR_KEY_MARGIN_LEFT];
}

- (CGFloat)marginLeft
{
    return [[self.dictionary objectForKey:DOCREATOR_KEY_MARGIN_LEFT] floatValue];
}

- (BOOL)hasMarginBottom
{
    return [self.dictionary objectForKey:DOCREATOR_KEY_MARGIN_BOTTOM];
}

- (CGFloat)marginBottom
{
    return [[self.dictionary objectForKey:DOCREATOR_KEY_MARGIN_BOTTOM] floatValue];
}

- (BOOL)hasMarginRight
{
    return [self.dictionary objectForKey:DOCREATOR_KEY_MARGIN_RIGHT];
}

- (CGFloat)marginRight
{
    return [[self.dictionary objectForKey:DOCREATOR_KEY_MARGIN_RIGHT] floatValue];
}

@end
