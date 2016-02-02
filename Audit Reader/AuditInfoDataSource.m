//
//  AuditInfoDataSource.m
//  Audit Reader
//
//  Created by Tim Perfitt on 3/11/10.
//  Copyright 2013 Twocanoes Software, Inc. All rights reserved.
//

#import "AuditInfoDataSource.h"


@implementation AuditInfoDataSource
-(void)awakeFromNib{
    self.auditEvents = [NSMutableArray array];
    self.filteredEvents = [NSMutableArray array];
}

-(NSMutableArray*)source {
    
    return (self.filterString && self.filterString.length) ? self.filteredEvents : self.auditEvents;
    
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView{
    @synchronized(self) {
        
        [self refreshFilteredEvents];
        
        return [self source].count;
    }
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex{
    @synchronized(self) {
        NSString *columnId = aTableColumn.identifier;
        
        AuditEventItem *theItem = [[self source] objectAtIndex:rowIndex];
        
        NSString *returnObject = nil;
        
        if ([@"event" isEqualToString:columnId]) {
            returnObject = theItem.event;
        }
        else if ([@"processId" isEqualToString:columnId]) {
            returnObject = theItem.processId;
        }
        else if ([@"time" isEqualToString:columnId]) {
            returnObject = theItem.timestamp.description;
        }
        else if ([@"description" isEqualToString:columnId]) {
            returnObject = theItem.rawDescription;
        }
        else if ([@"status" isEqualToString:columnId]) {
            returnObject = theItem.returnStatus;
        }
        return returnObject;

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
            
            BOOL matchFound = NO;
            
            if (curItem.event && [curItem.event rangeOfString:theFilterString].location != NSNotFound) {
                matchFound = YES;
            }
            else if (curItem.processId && [curItem.processId rangeOfString:theFilterString].location != NSNotFound) {
                matchFound = YES;
            }
            else if (curItem.rawDescription && [curItem.rawDescription rangeOfString:theFilterString].location != NSNotFound) {
                matchFound = YES;
            }
            else if (curItem.timestamp && [curItem.timestamp.description rangeOfString:theFilterString].location != NSNotFound) {
                matchFound = YES;
            }
            else if (curItem.returnStatus && [curItem.returnStatus rangeOfString:theFilterString].location != NSNotFound) {
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
