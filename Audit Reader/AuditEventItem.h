//
//  AuditEventItem.h
//  Audit Reader
//
//  Created by Mike Cross on 2/2/16.
//
//

#import <Foundation/Foundation.h>

@interface AuditEventItem : NSObject

@property (strong) NSString             *event;             // human readable string for event type
@property (strong) NSString             *processId;         // process Id
@property (strong) NSDate               *timestamp;         // event timestamp
@property (strong) NSString             *returnStatus;      // "success", "error...", etc.
@property (strong) NSString             *rawDescription;    // raw string of event including header, tokens, footer
@property (strong) NSMutableArray       *properties;        // Dictionary of human readable event values keyed by value type

//derived
@property (readonly) NSString           *timeDescription;   // Human readable time stamp
@property (nonatomic, strong) NSString  *processName;       // Name of process

-(instancetype)initWithEventString:(NSString*)type
                      andTimestamp:(NSString*)time
                 andRawDescription:(NSString*)description;

+(NSDate*)dateForTimestampString:(NSString*)timestamp;

@end
