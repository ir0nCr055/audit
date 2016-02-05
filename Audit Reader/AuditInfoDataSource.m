//
//  AuditInfoDataSource.m
//  Audit Reader
//
//  Created by Tim Perfitt on 3/11/10.
//  Copyright 2013 Twocanoes Software, Inc. All rights reserved.
//

#import "AuditInfoDataSource.h"

#define kAuditEventResultsTextCellIdentifier    (@"AuditEventTextCell")


@implementation AuditInfoDataSource
-(void)awakeFromNib{
    self.auditEvents = [NSMutableArray array];
    self.filteredEvents = [NSMutableArray array];
    self.filterString = nil;
}

-(NSMutableArray*)source {
    
    return (self.filterString && self.filterString.length) ? self.filteredEvents : self.auditEvents;
    
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView{
    @synchronized(self) {
        
        NSInteger count = 0;
        
        [self refreshFilteredEvents];
        
        NSArray *source = (NSArray*)[self source];
        
        if (source) {
            count = source.count;
        }
        
        return count;
    }
}

-(id)tableView:(NSTableView*)aTableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
    
    @synchronized(self) {
        NSString *columnId = tableColumn.identifier;
        
        NSArray *source = (NSArray*)[self source];
        
        NSTextField *returnObject = [aTableView makeViewWithIdentifier:kAuditEventResultsTextCellIdentifier
                                                                 owner:self];
        
        if (returnObject == nil) {
            returnObject = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, aTableView.frame.size.width, 0)];
            returnObject.drawsBackground = NO;
            returnObject.identifier = kAuditEventResultsTextCellIdentifier;
        }
        
        if (source && source.count && (source.count - 1 >= row)) {
            
            AuditEventItem *theItem = [source objectAtIndex:row];
            
            if ([@"event" isEqualToString:columnId]) {
                returnObject.stringValue = (theItem.event ? theItem.event : @"");
            }
            else if ([@"processId" isEqualToString:columnId]) {
                returnObject.stringValue = (theItem.processId ? theItem.processId : @"");
            }
            else if ([@"time" isEqualToString:columnId]) {
                returnObject.stringValue = (theItem.timeDescription ? theItem.timeDescription : @"");
            }
            else if ([@"description" isEqualToString:columnId]) {
                returnObject.stringValue = (theItem.rawDescription ? theItem.rawDescription : @"");
            }
            else if ([@"status" isEqualToString:columnId]) {
                returnObject.stringValue = (theItem.returnStatus ? theItem.returnStatus : @"");
            }
            else if ([@"process" isEqualToString:columnId]) {
                returnObject.stringValue = (theItem.processName ? theItem.processName : @"");
            }
        }
        return returnObject;
    }
}

-(CGFloat)tableView:(NSTableView*)aTableView heightOfRow:(NSInteger)row {
    @synchronized(self) {
        CGFloat descriptionHeight = 17.0;
        AuditEventItem *theEvent = [[self source] objectAtIndex:row];
        if (theEvent) {
            NSString *theEventDescription = theEvent.rawDescription;
            if (theEventDescription) {
                descriptionHeight = (double)([theEventDescription componentsSeparatedByString:@"\n"].count) * 17.0;
            }
        }
        return descriptionHeight;
    }
}

-(void)deleteAll{
    @synchronized(self) {
        [self.auditEvents removeAllObjects];
        [self.filteredEvents removeAllObjects];
    }
}
- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors{
    NSLog(@"  tableView"); 
    
}

-(void)refreshFilteredEvents {
    
    NSString *theFilterString = self.filterString;
    
    if (theFilterString && theFilterString.length) {
        
        NSPredicate *filterStringPredicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            AuditEventItem *curItem = (AuditEventItem*)evaluatedObject;
            NSString *processName = curItem.processName;
            
            BOOL matchFound = NO;
            
            if (curItem.event && [curItem.event rangeOfString:theFilterString options:NSCaseInsensitiveSearch].location != NSNotFound) {
                matchFound = YES;
            }
            else if (curItem.processId && [curItem.processId rangeOfString:theFilterString options:NSCaseInsensitiveSearch].location != NSNotFound) {
                matchFound = YES;
            }
            else if (curItem.rawDescription && [curItem.rawDescription rangeOfString:theFilterString options:NSCaseInsensitiveSearch].location != NSNotFound) {
                matchFound = YES;
            }
            else if (curItem.timeDescription && [curItem.timeDescription rangeOfString:theFilterString options:NSCaseInsensitiveSearch].location != NSNotFound) {
                matchFound = YES;
            }
            else if (curItem.returnStatus && [curItem.returnStatus rangeOfString:theFilterString options:NSCaseInsensitiveSearch].location != NSNotFound) {
                matchFound = YES;
            }
            else if (processName && [processName rangeOfString:theFilterString options:NSCaseInsensitiveSearch].location != NSNotFound) {
                matchFound = YES;
            }
            
            return matchFound;
            
        }];
        
        
        [self.filteredEvents setArray:[self.auditEvents filteredArrayUsingPredicate:filterStringPredicate]];
        
    }
    
}

-(IBAction)filterWithString:(id)sender{

    @synchronized(self) {
        NSLog(@"filter");
        NSString *newFilterString = [sender stringValue];
        self.filterString = newFilterString;
        
        [self refreshFilteredEvents];
        
        [dataOutlineView reloadData];
    }
}

-(void)compare:(id)sender{
    
    
    NSLog(@"compare");
}


-(void)addAuditEvent:(AuditEventItem*)auditEvent {
    @synchronized(self) {
        if (auditEvent) {
            [self.auditEvents addObject:auditEvent];
        }
    }
}

@end
