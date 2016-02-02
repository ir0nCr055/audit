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
@property (assign) NSString             *processId;         // process Id
@property (assign) u_int16_t            eventType;          // raw event type enum (e.g. "AUE_FORK", "AUE_KILL", "AUE_OPEN_EXTENDED")
@property (strong) NSDate               *timestamp;         // event timestamp
@property (strong) NSString             *returnStatus;      // "success", "error...", etc.
@property (strong) NSString             *rawDescription;    // raw string of event including header, tokens, footer
@property (strong) NSMutableArray       *properties;        // Dictionary of human readable event values keyed by value type

-(instancetype)initWithEventString:(NSString*)type
                      andTimestamp:(NSString*)time
                 andRawDescription:(NSString*)description;

+(NSDate*)dateForTimestampString:(NSString*)timestamp;

@end
