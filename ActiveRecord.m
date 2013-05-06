//
//  ActiveRecord.m
//  ActiveRecord
//
//  Created by Ryan Copley on 5/5/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "ActiveRecord.h"

@implementation ActiveRecord
@synthesize errorText, pkName;

-(id)init{
    self = [super init];
    if (self){
        data = [[NSMutableArray alloc] init];
        [ActiveRecord checkFolder];
    }
    return self;
}

+(id) newRecord{
    return [[[self class] alloc] init];
}

+(id) model{
    return [[[self class] alloc] init];
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



-(id)findByPk: (NSString*)value{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *archiveName = [NSString stringWithFormat:@"%@/ActiveRecords/%@-%@.json(%@)", documentsDirectory, [self recordIdentifier], value, pkName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:archiveName]){
        errorText = @"Model for primary key not found";
        return nil;
    }
    
    NSData* d = [NSData dataWithContentsOfFile:archiveName];
    
    NSDictionary* tmp = [NSJSONSerialization JSONObjectWithData:d options:NSJSONReadingAllowFragments error:nil];

    [self loadFromDictionary:tmp];
    
    return self;
}


-(id)findByAttribute: (NSString*) attribute equals:(id) value{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *archivePath = [NSString stringWithFormat:@"%@/ActiveRecords/", documentsDirectory];
    
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:archivePath error:nil];
    
    NSMutableArray* potentialFiles = [[NSMutableArray alloc] init];
    
    for (NSString *tString in dirContents) {
        if ([[tString substringToIndex: [self recordIdentifier].length ] isEqualToString: [self recordIdentifier]]){
            [potentialFiles addObject:[NSString stringWithFormat:@"%@%@",archivePath,tString]];
        }
    }
    
    for (NSString* filePath in potentialFiles) {
        
        NSData* d = [NSData dataWithContentsOfFile: filePath];
        NSDictionary* tmp = [NSJSONSerialization JSONObjectWithData:d options:NSJSONReadingAllowFragments error:nil];
        [self loadFromDictionary:tmp];
        [self debug];
        
        id comparison = [self performSelector: NSSelectorFromString(attribute)];
        
        if ([comparison isEqual:value]){
            return self;
        }
    }
    
    return nil;
}


#pragma mark Untested Function: -[ActiveRecord findAllByAttributes: isIn:];
-(NSArray*) findAllByAttribute: (NSString*) attribute isIn:(NSArray*) values{
    
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *archivePath = [NSString stringWithFormat:@"%@/ActiveRecords/", documentsDirectory];
    
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:archivePath error:nil];
    
    NSMutableArray* potentialFiles = [[NSMutableArray alloc] init];
    
    for (NSString *tString in dirContents) {
        if ([[tString substringToIndex: [self recordIdentifier].length ] isEqualToString: [self recordIdentifier]]){
            [potentialFiles addObject:[NSString stringWithFormat:@"%@%@",archivePath,tString]];
        }
    }
    
    NSMutableArray* tmpReturn = [[NSMutableArray alloc] init];
    
    for (NSString* filePath in potentialFiles) {
        
        NSData* d = [NSData dataWithContentsOfFile: filePath];
        NSDictionary* tmp = [NSJSONSerialization JSONObjectWithData:d options:NSJSONReadingAllowFragments error:nil];
        id tmpObj = [[[self class] alloc] init];
        
        [tmpObj loadFromDictionary:tmp];
        
        id comparison = [tmpObj performSelector: NSSelectorFromString(attribute)];
        
        NSUInteger isIn = [values indexOfObject:comparison];
        
        if (isIn != NSNotFound){
            [tmpReturn addObject:tmpObj];
        }
        
    }
    
    return tmpReturn;


}

-(NSArray*) findAllByAttribute: (NSString*) attribute equals:(id) value{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *archivePath = [NSString stringWithFormat:@"%@/ActiveRecords/", documentsDirectory];
    
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:archivePath error:nil];
    
    NSMutableArray* potentialFiles = [[NSMutableArray alloc] init];
    
    for (NSString *tString in dirContents) {
        if ([[tString substringToIndex: [self recordIdentifier].length ] isEqualToString: [self recordIdentifier]]){
            [potentialFiles addObject:[NSString stringWithFormat:@"%@%@",archivePath,tString]];
        }
    }
    
    NSMutableArray* tmpReturn = [[NSMutableArray alloc] init];
    
    for (NSString* filePath in potentialFiles) {
        
        NSData* d = [NSData dataWithContentsOfFile: filePath];
        NSDictionary* tmp = [NSJSONSerialization JSONObjectWithData:d options:NSJSONReadingAllowFragments error:nil];
        id tmpObj = [[[self class] alloc] init];
        
        [tmpObj loadFromDictionary:tmp];
        
        id comparison = [tmpObj performSelector: NSSelectorFromString(attribute)];
        
        if ([comparison isEqual:value]){
            [tmpReturn addObject:tmpObj];
        }
    }
    
    return tmpReturn;
}


-(void) loadFromDictionary:(NSDictionary*)dict{
    //Abusing selectors to reload data
    for (NSString* varName in data) {
        NSDictionary* tmpData = [dict objectForKey: varName];
        
        
        NSString* setConversion = [NSString stringWithFormat:@"set%@%@:", [[varName substringToIndex:1] uppercaseString],[varName substringFromIndex:1]];
        @try {
            /*if ([value isKindOfClass:[ActiveRecord class]]){
             NSLog(@"Loading from dictionray of a primary key");
             NSString* primaryKey = [dict objectForKey:varName];
             ActiveRecord* model = [[classType newRecord] findByPk: primaryKey];
             [self performSelector:NSSelectorFromString(setConversion) withObject: model];
             }else{
             */
            
            if ([tmpData objectForKey:@"isRelation"] == [NSNumber numberWithInt:0]){
                [self performSelector:NSSelectorFromString(setConversion) withObject: [tmpData objectForKey:@"value"]];
            }else{
                
                Class objClass = NSClassFromString([tmpData objectForKey:@"type"]);
                id obj = [[objClass alloc] init];
                [obj findByPk:[tmpData objectForKey:@"value"]];
                
                [self performSelector:NSSelectorFromString(setConversion) withObject: obj];
            }
            
            
        }
        
        @catch (NSException* e){
            NSLog(@"Error thrown! This object is not properly synthesized. Unable to set: %@", varName);
        }
        
        
    }
    NSLog(@"Final: %@",self);
}



-(BOOL)save{
    NSMutableDictionary* save = [[NSMutableDictionary alloc] init];
    
    for (NSString* varName in data) {
        @try{
            id value = [self performSelector: NSSelectorFromString(varName)];
            
            
            NSMutableDictionary* saveDict = [[NSMutableDictionary alloc] init];
            [saveDict setObject:value forKey:@"value"];
            [saveDict setObject:NSStringFromClass([value class]) forKey:@"type"];
            [saveDict setObject:[NSNumber numberWithInt:0] forKey:@"isRelation"];
            
            
            if ([value isKindOfClass:[ActiveRecord class]]){
                value = [value performSelector: NSSelectorFromString([value pkName] )];
                [saveDict setObject:value forKey:@"value"];
                [saveDict setObject:[NSNumber numberWithInt:1] forKey:@"isRelation"];
            }
            
            [save setObject:saveDict forKey:varName];
            
            
            
        }
        @catch (NSException* e){
            NSLog(@"Error thrown! This object is not properly synthesized. Unable to get property: %@",varName);
        }
        
    }
    
    
    NSString *jsonString;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:save options:NSJSONWritingPrettyPrinted error:&error];
    
    //Free memory up
    save = nil;
    
    if (! jsonData) {
        errorText = [NSString stringWithFormat:@"Got an error saving model: %@",error ];
        return NO;
        
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    NSString* primaryKey = [self performSelector: NSSelectorFromString(pkName)];
    
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *archiveName = [NSString stringWithFormat:@"%@/ActiveRecords/%@-%@.json(%@)", documentsDirectory, [self recordIdentifier], primaryKey, pkName];
    
    [jsonString writeToFile:archiveName atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if ([[NSFileManager defaultManager] isWritableFileAtPath:archiveName]) {
        errorText = @"File not writable.";
        return YES;
    }else {
        return NO;
    }
}

-(BOOL)deleteRecord{
    NSString* primaryKey = [self performSelector: NSSelectorFromString(pkName)];
    
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *archiveName = [NSString stringWithFormat:@"%@/ActiveRecords/%@-%@.json(%@)", documentsDirectory, [self recordIdentifier], primaryKey, pkName];
    
    [[NSFileManager defaultManager] removeItemAtPath:archiveName error:nil];
    return YES;
}

-(NSString*)recordIdentifier{
    return NSStringFromClass([self class]);
}

+(void) checkFolder{
    
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString* dataPath = [NSString stringWithFormat:@"%@/ActiveRecords/", documentsDirectory];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
    }
}


-(NSString*)description{
    return [NSString stringWithFormat:@"%@<%p> Properties %@", NSStringFromClass([self class]), self, data];
}

#pragma mark Debug method to output entire object to console.
-(void)debug{
    NSLog(@"-------------------------------------");
    for (NSString* varName in data) {
        
        id comparison = [self performSelector: NSSelectorFromString(varName)];
        NSLog(@"%@ = %@",varName,comparison);
    }
    
    NSLog(@"++++++++++++++++++++++++++++++++++++++++");
}
@end
