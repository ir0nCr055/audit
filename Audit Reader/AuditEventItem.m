//
//  AuditEventItem.m
//  Audit Reader
//
//  Created by Mike Cross on 2/2/16.
//
//

#import "AuditEventItem.h"
#import <libproc.h>
#import <sys/sysctl.h>

@implementation AuditEventItem
@synthesize processId = _processId;

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
        auditEventDateFormatter.timeZone = [NSTimeZone systemTimeZone];
    });
    
    NSDate *returnDate = nil;
    
    if (timestamp) {
        returnDate = [auditEventDateFormatter dateFromString:timestamp];
    }
    return returnDate;
}

+(NSString*)descriptionForTimestamp:(NSDate*)timestamp {
    static dispatch_once_t descriptionTimeStampInit;
    static NSDateFormatter *timestampFormatter = nil;
    dispatch_once(&descriptionTimeStampInit, ^{
        timestampFormatter = [[NSDateFormatter alloc] init];
        [timestampFormatter setDateFormat:@"EEE MMM dd h:mm:ss a yyyy"];
        timestampFormatter.timeZone = [NSTimeZone systemTimeZone];
    });
    
    NSString *timestampDesc = nil;
    if (timestamp) {
        timestampDesc = [timestampFormatter stringFromDate:timestamp];
    }
    return timestampDesc;
}

+ (NSString*)processNameForPID:(int)pid {
    
    NSString *theProcessName = nil;
    
    size_t len;
    static struct kinfo_proc kp;
    int name[] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, pid};
    
    len = sizeof(kp);
    if (sysctl(name, 4, &kp, &len, NULL, 0) == -1) {
        //Error
    }
    else if (len > 0) {
        theProcessName = [NSString stringWithUTF8String:kp.kp_proc.p_comm];
    }

    return theProcessName;
}

-(NSString*)timeDescription {
    return [AuditEventItem descriptionForTimestamp:self.timestamp];
}

-(NSString*)processId {
    return _processId;
}

-(void)setProcessId:(NSString *)processId {
    _processId = processId;
    if (_processId) {
        self.processName = [AuditEventItem processNameForPID:_processId.intValue];
    }
    else {
        self.processName = @"";
    }
}

@end
