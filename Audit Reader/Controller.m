//
//  Controller.m
//  Audit Reader
//
//  Created by Timothy Perfitt on 10/24/09.
//  Copyright 2013 Twocanoes Software. All rights reserved.
//

#import "Controller.h"
#import "AuditEventItem.h"
 

@implementation Controller

-(void)awakeFromNib{
    
    isRunning=NO;
    partial=[NSMutableString string];
    [predicateEditor addRow:self];
    
    tokens=[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AuditTokens" ofType:@"plist"]];
    
    [lockView setDelegate:self];
    [lockView setString:"system.privilege.admin"];
    [lockView setAutoupdate:YES];
    [lockView updateStatus:self];
    
}
    

-(void)rulesUpdated:(id)sender{
    
    
    if (predicateEditor) [self startTask];
}

-(void)refreshResultsTable {
    
    if (resultsOutlineView) {
        [resultsOutlineView reloadData];
    }
}

-(void)setupResultsRefreshTimer {
    
    [self tearDownRefreshTimer];
    
    resultsRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                           target:self
                                                         selector:@selector(refreshResultsTable)
                                                         userInfo:nil
                                                          repeats:YES];
}

-(void)tearDownRefreshTimer {
    if (resultsRefreshTimer) {
        [resultsRefreshTimer invalidate];
        resultsRefreshTimer = nil;
    }
}


-(void)startTask{

    NSString *eventString=nil;
    NSString *effectiveUserIdString=nil;
    NSString *effectiveGroupIdString=nil;
    
    NSDateFormatter *YearMonthDay = [[NSDateFormatter alloc] init];
    [YearMonthDay setDateFormat:@"%Y%m%d"];
    
    NSMutableString *argString=[NSMutableString string];
    NSArray *predicates=[(NSCompoundPredicate *)([predicateEditor predicate]) subpredicates];
    
    NSString *modifier;
    if ([showSuccess state]==YES && [showFailed state]==YES) modifier=@"";
    else if ([showSuccess state]==YES) modifier=@"+";
    else modifier=@"-";
    for (NSComparisonPredicate *curPred in predicates) {
        
        NSString *leftSide=[[curPred leftExpression] keyPath];

        NSString *rightSide=[[curPred rightExpression] constantValue];
        if (!leftSide) continue;
        if ([leftSide isEqualToString:@"Start Date"]) {
            NSDate *startDate=(NSDate *)rightSide;
            [argString appendString:[NSString stringWithFormat:@"-a %@ ",[YearMonthDay stringFromDate:startDate]]];
        }
        else if ([leftSide isEqualToString:@"End Date"]) {
            NSDate *endDate=(NSDate *)rightSide;
            [argString appendString:[NSString stringWithFormat:@"-b %@ ",[YearMonthDay stringFromDate:endDate]]];

        }
        else if ([leftSide isEqualToString:@"Event"]) {
            eventString=rightSide;
            [argString appendString:[NSString stringWithFormat:@"-c %@\"%@\" ",modifier,eventString]];
        }
        else if ([leftSide isEqualToString:@"Date Event Occurred"]) {
            NSDate *onDate=(NSDate *)rightSide;
            [argString appendString:[NSString stringWithFormat:@"-d %@ ",[YearMonthDay stringFromDate:onDate]]];
        }
        else if ([leftSide isEqualToString:@"Effective user ID or name"]) {
            effectiveUserIdString=rightSide; 
            [argString appendString:[NSString stringWithFormat:@"-e \"%@\" ",effectiveUserIdString]];

        }
        else if ([leftSide isEqualToString:@"Effective Group ID or name"]) {
            effectiveGroupIdString=rightSide;
            [argString appendString:[NSString stringWithFormat:@"-f \"%@\" ",effectiveGroupIdString]];

        }
        
    }
    
    NSNotificationCenter *nc=[NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(fileDataReceived:) name:NSFileHandleDataAvailableNotification object:nil];


    NSString *args=[NSString stringWithFormat:@"echo pid $$ end && /usr/sbin/auditreduce %@ /var/audit/*|/usr/sbin/praudit -d \"|\"",argString];
    const char *argsCstring=[args UTF8String];
    const char *pathToTool="/bin/sh";
    AuthorizationFlags flags = kAuthorizationFlagDefaults |
    kAuthorizationFlagInteractionAllowed |
    kAuthorizationFlagPreAuthorize |
    kAuthorizationFlagExtendRights;
    FILE *communicationsPipe=NULL;
    
    char *arguments[3]={"-c",(char *)argsCstring};
    authorization=[[lockView authorization] authorizationRef];
    AuthorizationItem right = {kAuthorizationRightExecute, 0, NULL, 0};
    AuthorizationRights rights = {1, &right};
    
    OSStatus status;
    // Call AuthorizationCopyRights to determine or extend the allowable rights.
    status = AuthorizationCopyRights(authorization, &rights, NULL, flags, NULL);
    if (status != errAuthorizationSuccess) {
        NSLog(@"Copy Rights Unsuccessful: %d", status);
        return;
    }
    
    isRunning=YES;
    AuthorizationExecuteWithPrivileges (
                                        authorization,
                                        pathToTool,
                                        kAuthorizationFlagDefaults,
                                        arguments,
                                        &communicationsPipe);
    

    
    auditTaskFileHandle=[[NSFileHandle alloc] initWithFileDescriptor:fileno(communicationsPipe) closeOnDealloc:YES];
    
    [self setupResultsRefreshTimer];
    
    [auditTaskFileHandle waitForDataInBackgroundAndNotify];
    
    
    NSMutableString *processListing=[NSMutableString string];
    FILE *pidFileRef=popen("/bin/ps axwwopid,command", "r");
    char data[255];
    
    while (fgets(data, 255, pidFileRef)) {
        
        [processListing appendString:[NSString stringWithUTF8String:data]];

    }
    
    NSArray *lines=[processListing componentsSeparatedByString:@"\n"];
    
    for (NSString *curLine in lines) {
        NSArray *commands=[curLine componentsSeparatedByString:@" "];
        
        if (([commands count]>1) && [[commands objectAtIndex:1] hasPrefix:@"/usr/sbin/auditreduce"]) 
            pid=[[commands objectAtIndex:0] intValue];
    }                        

    NSLog(@"pid is %i",pid);
}
-(void)fileDataReceived:(NSNotification *)notification{

    BOOL completed=NO;

    NSFileHandle *fh=auditTaskFileHandle;
    NSData *data=[fh availableData];
    if ([data length]==0) {
        [startStopButton setTitle:@"Search"];
        isRunning=NO;
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleDataAvailableNotification object:nil];
        auditTaskFileHandle = nil;
        return;
    }
    NSArray *currToken;
    NSMutableArray *currentRecordTokens=[NSMutableArray arrayWithCapacity:10];
    NSString *output=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    if (![partial isEqualToString:@""])  {
        output=[partial stringByAppendingString:output];
    }
    [partial setString:@""];
    NSArray *record=[output componentsSeparatedByString:@"\n"];
    
    AuditEventItem *newAuditEventItem = nil;
    NSMutableArray *foundAuditEvents = [NSMutableArray array];

    for (NSString *currString in record) {
        
      // if (![partial isEqualToString:@""]) [partial appendString:@"\n"];
        [partial appendString:currString];
        NSArray *recordArray=[currString componentsSeparatedByString:@"|"];
        NSString *command=[[recordArray objectAtIndex:0] stringByReplacingOccurrencesOfString:@" " withString:@""];
        if ([command isEqualToString:@""]) continue;
        if ([command isEqualToString:@"header"]) {
            
            if (currentRecordTokens) {
                currentRecordTokens=[NSMutableArray arrayWithCapacity:10];
            }
            
            if (newAuditEventItem) {
                [foundAuditEvents addObject:newAuditEventItem];
                newAuditEventItem = nil;
            }

            if ([recordArray count]>5) {
                
                completed=NO;
                
                NSString *dateString = [recordArray objectAtIndex:5];
                NSString *eventName = [recordArray objectAtIndex:3];
                
                newAuditEventItem = [[AuditEventItem alloc] initWithEventString:eventName
                                                                   andTimestamp:dateString
                                                              andRawDescription:nil];
            }

            
        } else if ((currToken=[tokens objectForKey:command])) {
            int i;

            NSMutableArray *attributeArray=[NSMutableArray arrayWithCapacity:[recordArray count]];
            NSDictionary *attributeHeader;

            for (i=1;i<[recordArray count];i++) {
                if (([currToken count]>i) && ([recordArray count]>i)) {
                    NSDictionary *currAttributeDict=[NSDictionary dictionaryWithObjectsAndKeys:[currToken objectAtIndex:i],@"record",
                                                     [recordArray objectAtIndex:i],@"time",nil];
                    [attributeArray addObject:currAttributeDict];
                }

                
            }
            attributeHeader=[NSDictionary dictionaryWithObjectsAndKeys:command,@"record",[currToken objectAtIndex:0],@"time",
                             attributeArray,@"children",nil];
            
            [currentRecordTokens addObject:attributeHeader];
            
            if (newAuditEventItem) {
                [newAuditEventItem.properties addObject:attributeHeader];
            }
            
            if ([command isEqualToString:@"return"] && [attributeArray count]>0) {
                
                if (newAuditEventItem) {
                    NSString *returnStatus = [[attributeArray objectAtIndex:0] valueForKey:@"time"];
                    newAuditEventItem.returnStatus = returnStatus;
                }
                
            }
            else if ([command isEqualToString:@"subject"] && [attributeArray count]>5) {
                
                if (newAuditEventItem) {
                    NSString *processID = [[attributeArray objectAtIndex:5] valueForKey:@"time"];
                    newAuditEventItem.processId = processID;
                }
            }
            else if ([command isEqualToString:@"trailer"]) {
                
                if (newAuditEventItem) {
                    newAuditEventItem.rawDescription = (NSString*)[partial copy];
                }
                [partial setString:@""];
                completed=YES;
            }
        }

            
    }
    
    if (foundAuditEvents.count) {
        for (AuditEventItem *curItem in foundAuditEvents) {
            [datasource addAuditEvent:curItem];
        }
    }
    
    if (newAuditEventItem && completed == YES) {
        [datasource addAuditEvent:newAuditEventItem];
    }

    [fh waitForDataInBackgroundAndNotify];
}
-(IBAction)searchButtonPressed:(id)sender{
    
    if (isRunning==YES) {
        isRunning=NO;
        [self tearDownRefreshTimer];
        [self killChildren];
        [startStopButton setTitle:@"Search"];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleDataAvailableNotification object:nil];
        auditTaskFileHandle = nil;
        return;
    }
    
    [datasource deleteAll];
    [resultsOutlineView reloadData];
    [startStopButton setTitle:@"Stop"];

    if (predicateEditor) [self startTask];
}

-(void)killChildren{
    const char *args=[[NSString stringWithFormat:@"%i",pid] UTF8String];
    const char *pathToTool="/bin/kill";
    AuthorizationFlags flags = kAuthorizationFlagDefaults |
    kAuthorizationFlagInteractionAllowed |
    kAuthorizationFlagPreAuthorize |
    kAuthorizationFlagExtendRights;
    
    char *arguments[2]={(char *)args};
    authorization=[[lockView authorization] authorizationRef];

    AuthorizationItem right = {kAuthorizationRightExecute, 0, NULL, 0};
    AuthorizationRights rights = {1, &right};
    
    OSStatus status;
    // Call AuthorizationCopyRights to determine or extend the allowable rights.
    status = AuthorizationCopyRights(authorization, &rights, NULL, flags, NULL);
    if (status != errAuthorizationSuccess) {
        NSLog(@"Copy Rights Unsuccessful: %d", (int)status);
        return;
    }
    
    isRunning=NO;
    
    NSLog(@"killing children");
    AuthorizationExecuteWithPrivileges (
                                        authorization,
                                        pathToTool,
                                        kAuthorizationFlagDefaults,
                                        arguments,
                                        NULL);
    isRunning=NO;
    NSLog(@"done");
    
    
}
- (void)outlineView:(NSOutlineView *)outlineView sortDescriptorsDidChange:(NSArray *)oldDescriptors{
    NSLog(@"  outlineView"); 
}

-(void)setAuthorizationRef:(AuthorizationRef)ref{
    
    authorization=ref;
    

    
}
- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors{
    NSLog(@"  tableView"); 

}

- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view{
    
    
    [self setAuthorizationRef:[[lockView authorization] authorizationRef]];
}
@end
