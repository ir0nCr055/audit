//
//  AuditEventItem.m
//  Audit Reader
//
//  Created by Mike Cross on 2/2/16.
//
//

#import "AuditEventItem.h"

@implementation AuditEventItem

-(instancetype)init {
    
    return [self initWithEventString:nil
                        andTimestamp:nil
                   andRawDescription:nil];
}

-(instancetype)initWithEventString:(NSString*)type
                      andTimestamp:(NSString*)time
                 andRawDescription:(NSString*)description {
    self = [super init];
    if (self) {
        self.event = type;
        self.timestamp = [AuditEventItem dateForTimestampString:time];
        self.rawDescription = description;
        self.properties = [NSMutableArray array];
    }
    return self;
}

+(NSDate*)dateForTimestampString:(NSString*)timestamp {
    
    static dispatch_once_t onceToken;
    static NSDateFormatter *auditEventDateFormatter = nil;
    dispatch_once(&onceToken, ^{
        auditEventDateFormatter = [[NSDateFormatter alloc] init];
        [auditEventDateFormatter setDateFormat:@"EEE MMM dd HH:mm:ss yyyy"];
    });
    
    NSDate *returnDate = nil;
    
    if (timestamp) {
        returnDate = [auditEventDateFormatter dateFromString:timestamp];
    }
    return returnDate;
}

@end
