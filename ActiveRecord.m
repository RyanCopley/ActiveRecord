//
//  ActiveRecord.m
//  ActiveRecord
//
//  Created by Ryan Copley on 5/5/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "ActiveRecord.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "FMDatabasePool.h"
#import "FMDatabaseQueue.h"


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

@implementation ActiveRecord
@synthesize errorText, pkName, isNewRecord;

static FMDatabase *db;
static FMDatabaseQueue *queue;
static NSMutableArray* schemas;

#pragma mark Active Record functions
-(id)init{
    self = [super init];
    if (self){
        [self setIsNewRecord:[NSNumber numberWithBool:YES]];
        
        data = [[NSMutableArray alloc] init];
        [ActiveRecord checkFolder];
        if (!db){
            schemas = [[NSMutableArray alloc] init];
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString* dbPath =  [NSString stringWithFormat:@"%@/AppDocs/db.sqlite",documentsDirectory];
            queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];

            db = [FMDatabase databaseWithPath:dbPath];
            if (![db open]) {
                NSLog(@"Failed to open database: %@",[self recordIdentifier]);
            }else{
                NSLog(@"Opened database: %@",[self recordIdentifier]);
            }
        }
        
    }
    return self;
}

+(id) model{ return [[[self class] alloc] init];}

-(void)createSchema{
    
    
    if ([schemas indexOfObject:[self recordIdentifier]] == NSNotFound) {
        [schemas addObject:[self recordIdentifier]];
        NSMutableString* columnData = [[NSMutableString alloc] init];
        [columnData appendFormat:@"%@ INTEGER PRIMARY KEY", pkName];
        for (NSString* keys in data){
            [columnData appendFormat:@", %@ TEXT", keys];
        }
        
        NSString* query = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@)", [self recordIdentifier], columnData];
        if (![db executeUpdate: query]){
            if ([db lastErrorCode] != 0){
                NSLog(@"(0xd34d4) Error %d: %@ %@", [db lastErrorCode], [db lastErrorMessage], query);
            }
        }
        
    }
}

-(BOOL)registerVariable:(NSString*) title{
    if (pkName == nil){
        pkName = title; //Assume if not set. Better safe than sorry.
    }
    
    [data addObject:title];
    return YES;
}

-(BOOL)registerPrimaryKey:(NSString*) title{
    pkName = title;
    return YES;
}

#pragma mark GET requests
-(id)recordByIntPK:(int)pk{
    return [self recordByPK:[NSNumber numberWithInt:pk]];
}

-(id)recordByPK:(NSNumber*)pk{
    
    NSString* query = [NSString stringWithFormat:@"SELECT * FROM %@  WHERE `%@`='%@' LIMIT 1", [self recordIdentifier], pkName, [self sanitize: [NSString stringWithFormat:@"%@",pk]] ];
    
    FMResultSet *s = [db executeQuery: query];
    if (![s next]){
        return nil;
    }
    
    id AR = [[[self class] alloc] init];
    [AR setIsNewRecord:[NSNumber numberWithBool:NO]];
    
    for (int i=0; i < [s columnCount]; i++){
        NSString* varName = [s columnNameForIndex: i];
        id value = [NSString stringWithFormat:@"%s",[s UTF8StringForColumnIndex:i]];
        NSString* setConversion = [NSString stringWithFormat:@"set%@%@:", [[varName substringToIndex:1] uppercaseString],[varName substringFromIndex:1]];
        @try {
            [AR performSelector: NSSelectorFromString(setConversion) withObject: value];
        }
        @catch (NSException* e){
            NSLog(@"[Email to ampachex@ryancopley.com please] Error thrown! This object is not properly synthesized. Unable to set: %@", varName);
        }
    }
    
    return AR;
}

-(id)recordsByAttribute:(NSString*)attribute value:(NSString*)value{
    
    NSString* query = [NSString stringWithFormat:@"SELECT * FROM %@  WHERE `%@`='%@'", [self recordIdentifier], [self sanitize: attribute], [self sanitize: value] ];
    FMResultSet *s = [db executeQuery: query];
    if (![s next]){
        return nil;
    }
    
    id AR = [[[self class] alloc] init];
    [AR setIsNewRecord:[NSNumber numberWithBool:NO]];
    
    for (int i=0; i < [s columnCount]; i++){
        NSString* varName = [s columnNameForIndex: i];
        id value = [NSString stringWithFormat:@"%s",[s UTF8StringForColumnIndex:i]];
        NSString* setConversion = [NSString stringWithFormat:@"set%@%@:", [[varName substringToIndex:1] uppercaseString],[varName substringFromIndex:1]];
        @try {
            [AR performSelector: NSSelectorFromString(setConversion) withObject: value];
        }
        @catch (NSException* e){
            NSLog(@"[Email to ampachex@ryancopley.com please] Error thrown! This object is not properly synthesized. Unable to set: %@", varName);
        }
    }
    
    return AR;
}


-(NSArray*)allRecords{
    NSMutableArray* returnObjs = [[NSMutableArray alloc] init];
    FMResultSet *s = [db executeQuery:[NSString stringWithFormat: @"SELECT * FROM %@", [self sanitize: [self recordIdentifier] ]]];
     
    while ([s next]) {
        if (1){ //Just to keep code aligned with other versions.
            id AR = [[[self class] alloc] init];
            [AR setIsNewRecord:NO];
            
            for (int i=0; i < [s columnCount]; i++){
                NSString* varName = [s columnNameForIndex: i];
                
                
                if ([varName isEqualToString:@"tag"] == 0){
                    id value = [NSString stringWithFormat:@"%s",[s UTF8StringForColumnIndex:i]];
                    NSString* setConversion = [NSString stringWithFormat:@"set%@%@:", [[varName substringToIndex:1] uppercaseString],[varName substringFromIndex:1]];
                    @try {
                        [AR performSelector: NSSelectorFromString(setConversion) withObject: value];
                    }
                    @catch (NSException* e){
                        NSLog(@"[Email to ampachex@ryancopley.com please] Error thrown! This object is not properly synthesized. Unable to set: %@", varName);
                    }
                }
            }
            
            [returnObjs addObject: AR];
        }
    }
    return returnObjs;
}

//TODO: Revolving PK values
-(BOOL)save{
    
    NSMutableString* columnNames = [[NSMutableString alloc] init];
    NSMutableString* columnData = [[NSMutableString alloc] init];
    
    __block NSMutableString* updateData = [[NSMutableString alloc] init];
    
    [columnNames appendFormat:@"`%@`",pkName];
    [columnData appendFormat:@"'%@'", [self sanitize: [self performSelector: NSSelectorFromString(pkName)]]];
        for (NSString* varName in data) {
        @try{
            id value = [self performSelector: NSSelectorFromString(varName)];
            
            if (value == nil){
                value = @"";
            }
            [columnNames appendFormat:@",`%@`", varName];
            [columnData appendFormat:@",\"%@\"",[self sanitize: [self performSelector: NSSelectorFromString(varName)]]];
            
            [updateData appendFormat:@"`%@`='%@',",varName, [self sanitize: [self performSelector: NSSelectorFromString(varName)]]];
            
        }
        @catch (NSException* e){
            NSLog(@"[Email to ampachex@ryancopley.com please] Error thrown! This object is not properly synthesized. Unable to get property: %@",varName);
        }
    }
    
    updateData = [[updateData substringToIndex: [updateData length]-1] mutableCopy];
    
    NSString* query;
    if ([[self isNewRecord] isEqualToNumber: [NSNumber numberWithInt:1]]){
        query = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", [self recordIdentifier], columnNames, columnData];
    }else{
        query = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@='%@'", [self recordIdentifier], updateData, pkName, [self performSelector: NSSelectorFromString(pkName)]];
    }
    
    [self setIsNewRecord:[NSNumber numberWithBool:NO]];

    dispatch_async(dispatch_get_main_queue(), ^{
        [queue inDatabase:^(FMDatabase *db) {
            if (![db executeUpdate: query]){
                if ([db lastErrorCode] != 0){
                    NSLog(@"(0xd34d) Error %d: %@ %@", [db lastErrorCode], [db lastErrorMessage], query);
                }
            }
        }];
        
    });
    

    
    return NO;
    
}



#pragma mark Delete functions

-(BOOL)deleteRecord{
    NSString* primaryKey = [self performSelector: NSSelectorFromString(pkName)];
    NSString* query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@='%@'",[self recordIdentifier],pkName,primaryKey];
    return [db executeUpdate:query];
}

#pragma mark Misc


-(NSString*)recordIdentifier{
    return [NSStringFromClass([self class]) lowercaseString];
}

+(void) checkFolder{
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString* dataPath = [NSString stringWithFormat:@"%@/AppDocs/", documentsDirectory];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
    }
}


-(NSString*)description{
    NSMutableString* d = [@"\n" mutableCopy];
    
    
    for (NSString* varName in data) {
        @try{
            id value = [self performSelector: NSSelectorFromString(varName)];
            [d appendFormat:@"\t`%@` = `%@`,\n",varName, value];
            
        }
        @catch (NSException* e){
            NSLog(@"[Email to ampachex@ryancopley.com please] Error thrown! This object is not properly synthesized. Unable to get property: %@",varName);
        }
    }
    
    return [NSString stringWithFormat:@"%@<%p> Properties %@", NSStringFromClass([self class]), self, d];
}


-(NSString*)sanitize:(NSString*)string{
    string = [NSString stringWithFormat:@"%@",string];
    string = [string stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""];
    return string;
}

@end

#pragma clang diagnostic pop