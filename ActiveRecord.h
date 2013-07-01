//
//  ActiveRecord.h
//  ActiveRecord
//
//  Created by Ryan Copley on 5/5/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//


#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "FMDatabasePool.h"
#import "FMDatabaseQueue.h"

@interface ActiveRecord : NSObject{
    NSMutableArray* data;
    NSString* errorText;
    NSString* pkName;
    NSNumber* isNewRecord;
    
}

@property (nonatomic, retain) NSNumber* isNewRecord;
@property (nonatomic, retain) NSString* errorText;
@property (nonatomic, retain) NSString* pkName;

+(id)model;
-(id)recordByStringPK:(NSString*)pk;
-(id)recordByIntPK:(int)pk;
-(id)recordByPK:(NSNumber*)pk;
-(id)recordByAttribute:(NSString*)attribute value:(NSString*)value;
-(id)recordsByAttribute:(NSString*)attribute value:(NSString*)value;
-(NSArray*)allRecords;

-(BOOL)registerVariable:(NSString*) title;
-(BOOL)registerPrimaryKey:(NSString*) title;

-(BOOL)save;
-(BOOL)deleteRecord;
-(NSString*)sanitize:(NSString*)string;

-(NSString*)recordIdentifier;
-(void)createSchema;
-(FMDatabaseQueue*) getDB;

@end
