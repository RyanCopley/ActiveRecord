//
//  ActiveRecord.h
//  ActiveRecord
//
//  Created by Ryan Copley on 5/5/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//


@interface ActiveRecord : NSObject{
    NSMutableArray* data;
    NSString* errorText;
    NSString* pkName;
}

@property (nonatomic, retain) NSString* errorText;
@property (nonatomic, retain) NSString* pkName;

+(id) newRecord;
+(id) model;

-(id) findByPk: (NSString*)value;
-(id) findByAttribute: (NSString*) attribute equals:(id) value;

-(NSArray*) findAllByAttribute: (NSString*) attribute equals:(id) value;
-(NSArray*) findAllByAttribute: (NSString*) attribute isIn:(NSArray*) values;

-(BOOL)registerVariable:(NSString*) title;
-(BOOL)registerPrimaryKey:(NSString*) title;

-(BOOL)save;
-(BOOL)deleteRecord;

-(NSString*)recordIdentifier;

@end
