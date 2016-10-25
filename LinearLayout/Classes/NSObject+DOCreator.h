//
//  NSObject+DOCreator.h
//  DOViewLayout
//
//  Created by kura on 2016/10/20.
//  Copyright © 2016年 kura. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DOCREATOR_PUSH_EVENT_NOTIFICATION_NAME  @"@DOCREATOR_PUSH_EVENT_NOTIFICATION_NAME"

#define DOCREATOR_KEY_CLASS                     @"@class"
#define DOCREATOR_KEY_PROPERTY                  @"@property"

#define DOCREATOR_KEY_EVAL                      @"@eval"
#define DOCREATOR_KEY_STATIC                    @"@static"
#define DOCREATOR_KEY_OBJECT                    @"@object"
#define DOCREATOR_KEY_METHOD                    @"@method"

#define DOCREATOR_KEY_VIEW_CONTROLLER           @"@view_controller"
#define DOCREATOR_KEY_EVENT                     @"@event"
#define DOCREATOR_KEY_PUSH                      @"@push"

#define DOCREATOR_KEY_VIEW                      @"@view"
#define DOCREATOR_KEY_SUBVIEWS                  @"@subviews"

#define DOCREATOR_KEY_STRING                    @"@string"
#define DOCREATOR_KEY_FORMAT                    @"@format"
#define DOCREATOR_KEY_ARGS                      @"@args"

#define DOCREATOR_KEY_COLOR                     @"@color"

#define DOCREATOR_KEY_IMAGE                     @"@image"
#define DOCREATOR_KEY_NAME                      @"@name"
#define DOCREATOR_KEY_CAP_INSETS                @"@cap_insets"
#define DOCREATOR_KEY_RESIZING_MODE             @"@resizing_mode"

#define DOCREATOR_KEY_DIMEN                     @"@dimen"
#define DOCREATOR_KEY_WIDTH                     @"@width"
#define DOCREATOR_KEY_HEIGTH                    @"@height"
#define DOCREATOR_KEY_MARGIN_TOP                @"@margin_top"
#define DOCREATOR_KEY_MARGIN_LEFT               @"@margin_left"
#define DOCREATOR_KEY_MARGIN_BOTTOM             @"@margin_bottom"
#define DOCREATOR_KEY_MARGIN_RIGHT              @"@margin_right"

@protocol DOCreatorDelegate <NSObject>

- (nullable id)createObjectWithKey:(nullable NSString *)key object:(nullable id)object defaultImplementationBlock:(id __nullable (^ __nullable)(NSString * __nullable key, id __nullable object))defaultImplementationBlock;

@end

@interface NSObject (DOCreator)

+ (void)setCreatorDelegate:(nullable id<DOCreatorDelegate>)delegate;

+ (nullable instancetype)fromJsonObject:(nullable id)jsonObject;

+ (void)setPropertyTo:(nullable NSObject *)obj from:(nullable NSDictionary *)property;

+ (void)setMemoryWith:(nullable NSString *)key type:(nullable NSString *)type value:(nullable NSObject *)value;

@end

@interface UIViewController (DOCreator)

- (void)setPushEventReceiver;

@end

@interface UIButton (DOCreator)

@property (nonatomic, nullable) NSString *title;

- (void)setEventWithDictionary:(nullable NSDictionary *)eventDictionary;

@end

@interface UIView (DOCreator)

@end

@interface UIColor (DOCreator)

@end

@interface NSString (DOCreator)

@end

@interface UIImage (DOCreator)

@end

@interface DODimen : NSObject

@property (nonatomic, nullable) NSDictionary *dictionary;

- (BOOL)hasWidth;
- (BOOL)hasHeight;

- (CGFloat)width;
- (CGFloat)height;

- (BOOL)hasMarginTop;
- (BOOL)hasMarginLeft;
- (BOOL)hasMarginBottom;
- (BOOL)hasMarginRight;

- (CGFloat)marginTop;
- (CGFloat)marginLeft;
- (CGFloat)marginBottom;
- (CGFloat)marginRight;

@end
