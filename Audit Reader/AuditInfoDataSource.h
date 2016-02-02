//
//  AuditInfoDataSource.h
//  Audit Reader
//
//  Created by Tim Perfitt on 3/11/10.
//  Copyright 2013 Twocanoes Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AuditEventItem.h"

@interface AuditInfoDataSource : NSObject <NSTableViewDataSource> {

    IBOutlet id dataOutlineView;
}

@property (strong) NSMutableArray *auditEvents;
@property (strong) NSMutableArray *filteredEvents;
@property (strong) NSString *filterString;

-(IBAction)filterWithString:(id)sender;
-(void)deleteAll;
-(void)addAuditEvent:(AuditEventItem*)auditEvent;
@end
