//
//  COImageCache.h
//  GCCOTests
//
//  Created by Stefan Koflers Mac on 18.06.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface COImageCache : NSObject {
    @protected
        sqlite3 * database; 
}

+ (COImageCache *)sharedCache;

- (NSString*)readDatabaseFilename;
- (BOOL)openDatabase;
- (BOOL)databaseContainsURL:(NSString *)link;
- (void)saveImage:(UIImage*)image fromURL:(NSString*)url;
- (UIImage*)getImageWithURL:(NSString*)url;

@end
