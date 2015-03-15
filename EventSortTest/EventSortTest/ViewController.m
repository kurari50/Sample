//
//  ViewController.m
//  EventSortTest
//
//  Created by kura on 2015/03/14.
//  Copyright (c) 2015年 kura. All rights reserved.
//

#import "ViewController.h"
#import "MargeSortArray.h"

#define APPLICATION_TITLE   @"EventSortTest"
#define EVENT_TITLE_PREFIX  @"[" APPLICATION_TITLE @"]"
#define ADD_EVENT_COUNT     4000
#define DURATION_FROM_NOW   (10 * 24 * 60 * 60)
#define LIMIT_EVENT_COUNT   3000

@import EventKit;

@interface ViewController ()

@property (nonatomic, strong) EKEventStore *eventStore;

@property (nonatomic, copy) NSArray *calendars;
@property (nonatomic, strong) EKCalendar *targetCalendar;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.eventStore = [[EKEventStore alloc] init];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        NSLog(@"granted: %d", (int)granted);
    }];
}

- (void)loadCalendar
{
    self.calendars = [self.eventStore calendarsForEntityType:EKEntityTypeEvent];
    [self.calendars enumerateObjectsUsingBlock:^(EKCalendar *c, NSUInteger idx, BOOL *stop) {
        NSLog(@"calendar title: %@", c.title);
        
        if ([c.title isEqualToString:APPLICATION_TITLE]) {
            self.targetCalendar = c;
            *stop = YES;
        }
    }];
    
    if (!self.targetCalendar) {
        EKCalendar *defaultCalendar = [self.eventStore defaultCalendarForNewEvents];
        __block EKSource *source = defaultCalendar.source;
        if (!source) {
            [self.eventStore.sources enumerateObjectsUsingBlock:^(EKSource *s, NSUInteger idx, BOOL *stop) {
                if (/*s.sourceType == EKSourceTypeLocal || */s.sourceType == EKSourceTypeExchange || s.sourceType == EKSourceTypeCalDAV) {
                    NSLog(@"sourceType: %d", (int)s.sourceType);
                    source = s;
                    *stop = YES;
                }
            }];
        }
        
        EKCalendar *targetCalendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:self.eventStore];
        targetCalendar.title = APPLICATION_TITLE;
        targetCalendar.source = source;
        NSError *error = nil;
        BOOL ret = [self.eventStore saveCalendar:targetCalendar commit:YES error:&error];
        if (!ret || error) {
            NSLog(@"ERROR: %@", error);
        } else {
            self.targetCalendar = targetCalendar;
        }
    }
    
    NSAssert(self.targetCalendar, @"");
}

- (void)setup
{
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [self loadCalendar];
}

- (void)setdown
{
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

- (IBAction)pressedAddButton:(id)sender
{
    [self setup];
    
    NSLog(@"カレンダー追加開始");
    NSDate *startDateOrig = [NSDate date];
    for (int i = 0; i < ADD_EVENT_COUNT; i++) {
        @autoreleasepool {
            NSLog(@"%d", i);
            
            EKEvent *event = [EKEvent eventWithEventStore:self.eventStore];
            event.calendar = self.targetCalendar;
            event.startDate = [startDateOrig dateByAddingTimeInterval:60 * i];
            event.endDate = [event.startDate dateByAddingTimeInterval:24 * 60 * 60];
            event.title = [NSString stringWithFormat:EVENT_TITLE_PREFIX "test%04d", i];
            
            NSError *error = nil;
            BOOL last = ((ADD_EVENT_COUNT - 1) == i);
            BOOL ret = [self.eventStore saveEvent:event span:EKSpanThisEvent commit:last error:&error];
            if (!ret || error) {
                NSLog(@"ERROR: %@", error);
            }
        }
    }
    NSLog(@"カレンダー追加終了");
    
    [self setdown];
}

- (IBAction)pressedDeleteButton:(id)sender
{
    [self setup];
    
    NSLog(@"カレンダー削除開始");
    NSError *error = nil;
    BOOL ret = [self.eventStore removeCalendar:self.targetCalendar commit:YES error:&error];
    if (!ret || error) {
        NSLog(@"ERROR: %@", error);
    }
    
    [self enumerateEventsWithBlock:^(EKEvent *event, BOOL *stop) {
        if (![event.title hasPrefix:EVENT_TITLE_PREFIX]) {
            return;
        }
        
        NSError *error = nil;
        BOOL ret = [self.eventStore removeEvent:event span:EKSpanThisEvent commit:YES error:&error];
        if (!ret || error) {
            NSLog(@"ERROR: %@", error);
        }
    }];
    NSLog(@"カレンダー削除終了");
    
    [self setdown];
}

- (IBAction)pressedReadButton:(id)sender
{
    [self setup];
    
    NSLog(@"カレンダー読み込み開始");
    [self enumerateEventsWithBlock:^(EKEvent *event, BOOL *stop) {
        
    }];
    NSLog(@"カレンダー読み込み終了");
    
    [self setdown];
}

- (void)enumerateEventsWithBlock:(EKEventSearchCallback)block
{
    NSDate *now = [NSDate date];
    NSDate *start = [now dateByAddingTimeInterval:-DURATION_FROM_NOW];
    NSDate *end = [now dateByAddingTimeInterval:DURATION_FROM_NOW];
    NSPredicate *predicate = [self.eventStore predicateForEventsWithStartDate:start endDate:end calendars:@[self.targetCalendar]];
    
//    [self.eventStore enumerateEventsMatchingPredicate:predicate usingBlock:block];
//    return;
    
    NSTimeInterval start_sortedEvents = [NSDate date].timeIntervalSince1970;
    NSArray *events = [self.eventStore eventsMatchingPredicate:predicate];
    NSArray *sortedEvents = [events sortedArrayUsingComparator:^NSComparisonResult(EKEvent *e1, EKEvent *e2) {
        return [e2 compareStartDateWithEvent:e1];
    }];
    NSTimeInterval finish_sortedEvents = [NSDate date].timeIntervalSince1970;

    NSArray *sortedEvents3000 = [sortedEvents subarrayWithRange:NSMakeRange(0, LIMIT_EVENT_COUNT)];
    
    NSTimeInterval start_enumerateEventsMatchingPredicate = [NSDate date].timeIntervalSince1970;
    __block NSMutableArray *events3000 = [NSMutableArray array];
    [self.eventStore enumerateEventsMatchingPredicate:predicate usingBlock:^(EKEvent *event, BOOL *stop) {
        [events3000 addObject:event];
        [events3000 sortUsingComparator:^NSComparisonResult(EKEvent *e1, EKEvent *e2) {
            return [e2 compareStartDateWithEvent:e1];
        }];
        if (events3000.count > LIMIT_EVENT_COUNT) {
            [events3000 removeLastObject];
        }
    }];
    NSTimeInterval finish_enumerateEventsMatchingPredicate = [NSDate date].timeIntervalSince1970;
    
    NSTimeInterval start_marge = [NSDate date].timeIntervalSince1970;
    
//#define MARGE_LOG(...) NSLog(__VA_ARGS__)
#define MARGE_LOG(...) 
    
    MargeSortArray *margeSortArray = [MargeSortArray margeSortArrayWithLimit:LIMIT_EVENT_COUNT comparatorBlock:^NSComparisonResult(EKEvent *e1, EKEvent *e2) {
        return [e2 compareStartDateWithEvent:e1];
    }];
    __block NSDate *prevStartDate = nil;
    __block NSMutableArray *partArray = [NSMutableArray array];
    [self.eventStore enumerateEventsMatchingPredicate:predicate usingBlock:^(EKEvent *event, BOOL *stop) {
//        [margeSortArray addObject:event];
//        return;
        
        if (!prevStartDate || [prevStartDate earlierDate:event.startDate] == prevStartDate || partArray.count == 0) {
            
        } else {
            MARGE_LOG(@"まとまり: %d", (int)partArray.count);
            NSMutableArray *t = [NSMutableArray array];
            [partArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [t addObject:obj];
            }];
            partArray = t;
            [margeSortArray addSortedArray:partArray];
            partArray = [NSMutableArray array];
        }
        
        MARGE_LOG(@"%@", event.title);
        MARGE_LOG(@"%@", event.startDate);
        
        [partArray addObject:event];
        prevStartDate = event.startDate;
    }];
    if (partArray.count) {
        MARGE_LOG(@"まとまり: %d", (int)partArray.count);
        NSMutableArray *t = [NSMutableArray array];
        [partArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [t addObject:obj];
        }];
        partArray = t;
        [margeSortArray addSortedArray:partArray];
        partArray = nil;
    }
    
    NSArray *margeSortArray3000 = [margeSortArray sortedArray];
    NSTimeInterval finish_marge = [NSDate date].timeIntervalSince1970;
    
    NSLog(@"予定データ件数: %d", events.count);
    NSLog(@"isEqualToArray: %d", [events isEqualToArray:sortedEvents]);
    NSLog(@"isEqualToArray3000: %d", [events3000 isEqualToArray:sortedEvents3000]);
    NSLog(@"isEqualToArrayMarge: %d", [events3000 isEqualToArray:margeSortArray3000]);
    
    NSLog(@"sortedEvents: %f sec", finish_sortedEvents - start_sortedEvents);
    NSLog(@"enumerateEventsMatchingPredicate: %f sec", finish_enumerateEventsMatchingPredicate - start_enumerateEventsMatchingPredicate);
    NSLog(@"marge: %f sec", finish_marge - start_marge);
//    NSLog(@"events3000[0]: %@", events3000[0]);
//    NSLog(@"events3000[last]: %@", events3000.lastObject);
//    NSLog(@"sortedEvents3000[0]: %@", sortedEvents3000[0]);
//    NSLog(@"sortedEvents3000[last]: %@", sortedEvents3000.lastObject);
//    NSLog(@"margeSortArray3000[0]: %@", margeSortArray3000[0]);
//    NSLog(@"margeSortArray3000[last]: %@", margeSortArray3000.lastObject);
    [self.eventStore enumerateEventsMatchingPredicate:predicate usingBlock:block];
}

@end
