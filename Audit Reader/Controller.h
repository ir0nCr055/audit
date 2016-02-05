//
//  Controller.h
//  Audit Reader
//
//  Created by Timothy Perfitt on 10/24/09.
//  Copyright 2013 Twocanoes Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <Security/Security.h>
#import "AuditInfoDataSource.h"
#import <SecurityInterface/SFAuthorizationView.h>

@interface Controller : NSObject {

    NSDictionary *tokens;
    IBOutlet NSPredicateEditor *predicateEditor;
    NSTask *task;
    IBOutlet NSButton *showSuccess, *showFailed;
    NSMutableString *partial;
    IBOutlet AuditInfoDataSource *datasource;
    IBOutlet NSSearchField *searchField;
    AuthorizationRef authorization;
    IBOutlet SFAuthorizationView *lockView;

    IBOutlet NSButton *startStopButton;
    IBOutlet NSWindow *mainWindow;
    int pid;
    BOOL isRunning;
    int filteringPID;
    
    //Timer to refresh results table
    NSTimer *resultsRefreshTimer;
    
    //Filehandle to Audit Event Pipe
    NSFileHandle *auditTaskFileHandle;
    
}
@property (weak) IBOutlet NSTableView *resultsTableView;

-(void)startTask;
-(void)killChildren;
-(IBAction)searchButtonPressed:(id)sender;

-(void)refreshResultsTable;
@end
