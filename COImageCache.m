//
//  COImageCache.m
//  GCCOTests
//
//  Created by Stefan Koflers Mac on 18.06.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "COImageCache.h"


@implementation COImageCache

static sqlite3_stmt *addStmt = nil;
static sqlite3_stmt *detailStmt = nil;

+ (COImageCache *)sharedCache {
    static dispatch_once_t pred;
    static COImageCache *__sharedManager = nil;
    
    dispatch_once(&pred, ^{
        __sharedManager = [[COImageCache alloc] init];
    });
    
    return __sharedManager;
}

- (id)init {
    self = [super init];
    if (self) {
        [self openDatabase];
    }
    return self;
}


#pragma mark - Database

- (BOOL)openDatabase {
	if (![[NSFileManager defaultManager] fileExistsAtPath:[self readDatabaseFilename]])
	{
		NSError *error;
		NSString *dbResourcePath = [[NSBundle mainBundle] pathForResource:@"images" ofType:@"db"];
		[[NSFileManager defaultManager] copyItemAtPath:dbResourcePath toPath:[self readDatabaseFilename] error:&error];
		// Check for errors...
	}
	
	if (sqlite3_open([[self readDatabaseFilename] UTF8String], &database) 
        == SQLITE_OK)
		return true;
	else 
		return false;
}

/*
 * This funktion checks to see if the given URL is in the database
 */
- (BOOL)databaseContainsURL:(NSString *)link {
	BOOL found = NO;
	
	const char *sql = "select url from images where url=?";
	sqlite3_stmt *statement;
	int error;
	
	error = sqlite3_prepare_v2(database, sql, -1, &statement, NULL);
	if (error == SQLITE_OK) {
		error = sqlite3_bind_text (statement, 1, [link UTF8String], -1, SQLITE_TRANSIENT);
		if (error == SQLITE_OK && sqlite3_step(statement) == SQLITE_ROW) {
			found = YES;
		}
	}
	if (error != SQLITE_OK)
		NSLog (@"An error occurred: %s", sqlite3_errmsg(database));
	error = sqlite3_finalize(statement);	
	if (error != SQLITE_OK)
		NSLog (@"An error occurred: %s", sqlite3_errmsg(database));
	
	return found;
}

- (void)saveImage:(UIImage*)image fromURL:(NSString*)url {
    if ([self databaseContainsURL:url]) {
        return;
    }
    
    if (addStmt == nil) {
        const char *sql = "insert into images(url, image) Values(?, ?)";
        if(sqlite3_prepare_v2(database, sql, -1, &addStmt, NULL) != SQLITE_OK)
            NSLog(@"Error while creating add statement. '%s'", sqlite3_errmsg(database));
    }
    
    sqlite3_bind_text(addStmt, 1, [url UTF8String], -1, SQLITE_TRANSIENT);
    
    NSData *imgData = UIImagePNGRepresentation(image);
    
    int returnValue = -1;
    if(imgData != nil)
        returnValue = sqlite3_bind_blob(addStmt, 2, [imgData bytes], [imgData length], NULL);
    else
        returnValue = sqlite3_bind_blob(addStmt, 2, nil, -1, NULL);
    
    if(returnValue != SQLITE_OK)
        NSLog(@"Not OK!!!");
    
    if(SQLITE_DONE != sqlite3_step(addStmt))
        NSLog(@"Error while updating. '%s'", sqlite3_errmsg(database));
    
    sqlite3_reset(addStmt);
}

- (UIImage*)getImageWithURL:(NSString*)url {
    NSDate *d = [NSDate date];

    UIImage* ret;
    
    if(detailStmt == nil) {
        const char *sql = "Select image from images Where url = ?";
        if(sqlite3_prepare_v2(database, sql, -1, &detailStmt, NULL) != SQLITE_OK)
            NSAssert1(0, @"Error while creating detail view statement. '%s'", sqlite3_errmsg(database));
    }
    
    sqlite3_bind_text(detailStmt, 1, [url UTF8String], -1, SQLITE_TRANSIENT);
    
    if(SQLITE_DONE != sqlite3_step(detailStmt)) {
        NSData *data = [[NSData alloc] initWithBytes:sqlite3_column_blob(detailStmt, 0) length:sqlite3_column_bytes(detailStmt, 0)];
        
        if(data == nil)
            NSLog(@"No image found.");
        else
            ret = [UIImage imageWithData:data];
    }
    else
        NSLog(@"Error when trying to get image '%s'", sqlite3_errmsg(database));
    
    //Reset the detail statement.
    sqlite3_reset(detailStmt); 
    
    NSLog(@"%f", -[d timeIntervalSinceNow]);
    
    return ret;
}

#pragma mark - Paths


- (NSString*)readDatabaseFilename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return [documentsDirectory stringByAppendingPathComponent:@"images.db"];
}

@end
