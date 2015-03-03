//
//  DataManager.m
//  Sockets
//
//  Created by Ilya Tsarev on 03.03.15.
//  Copyright (c) 2015 Ilya Tsarev. All rights reserved.
//

#import "DataManager.h"
#import <CoreData/CoreData.h>

@interface DataManager ()

@property (nonatomic) NSInteger pageOffset;
@property (nonatomic) NSInteger pageSize;
@property (nonatomic) NSInteger dataRead;
@property (nonatomic) NSInteger dataCount;

@end

@implementation DataManager

+ (DataManager *)sharedInstance{
    static DataManager *sharedInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once( &predicate, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark - CoreData methods

- (NSManagedObjectContext *) managedContext
{
    static NSManagedObjectContext* managedContext = nil;
    
    if (managedContext == nil){
        id delegate = [[UIApplication sharedApplication] delegate];
        managedContext = [delegate managedObjectContext];
    }
    
    return managedContext;
}

- (NSManagedObject *)managedObjectForEntityWithName:(NSString *)entityName{
    NSManagedObjectContext *managedObjectContext = [self managedContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext];
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:managedObjectContext];
    
    return newManagedObject;
}

- (NSArray *)fetchRequestForEntityName:(NSString *)entityName withPredicate:(NSPredicate *)predicate andOffset:(NSInteger)offset{
    NSManagedObjectContext *managedObjectContext = [self managedContext];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext];
    
    if (predicate) {
        [fetchRequest setPredicate:predicate];
    }
    [fetchRequest setEntity:entity];
    
    [self calculatePositionForPaging:offset forRequest:fetchRequest];
    
    NSError *error;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (!error) {
        return fetchedObjects;
    }
    NSLog(@"ERROR: %@, %@", error, [error userInfo]);
    return nil;
}

#pragma mark - Paging

- (void)calculatePositionForPaging:(NSInteger)offset forRequest:(NSFetchRequest *)request{
    NSInteger resultOffset = offset - _pageSize;
    if (resultOffset < 0) {
        request.fetchLimit = offset;
        request.fetchOffset = 0;
        _dataRead += offset;
    } else {
        request.fetchLimit = _pageSize;
        request.fetchOffset = resultOffset;
        _dataRead += _pageSize;
    }
}

- (NSInteger)countForEntityWithName:(NSString *)entityName{
    NSManagedObjectContext *managedObjectContext = [self managedContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSUInteger count = [managedObjectContext countForFetchRequest:fetchRequest error:&error];
    return count;
}

- (NSInteger)calculateCountForUser:(NSString *)username{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"username LIKE %@", username];

    NSManagedObjectContext *managedObjectContext = [self managedContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ChatData" inManagedObjectContext:managedObjectContext];
    
    if (predicate) {
        [fetchRequest setPredicate:predicate];
    }
    
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSUInteger count = [managedObjectContext countForFetchRequest:fetchRequest error:&error];

    return count;
}

- (void)setPagingDataUsingUsername:(NSString *)username{
    _dataCount = [self calculateCountForUser:username];
    _pageOffset = _dataCount;
    _pageSize = 10;
    _dataRead = 0;
}

- (void)updatePagingData{
    _dataRead += 1;
    _dataCount += 1;
}

- (BOOL)moreDataAvailable{
    if (_dataRead == _dataCount) {
        return NO;
    }
    _pageOffset -= _pageSize;
    return YES;
}

#pragma mark - Methods

- (NSArray *)getChatDataForUser:(NSString *)username withOffset:(NSInteger)offset{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"username LIKE %@", username];
    
    NSArray *fetchedObjects = [self fetchRequestForEntityName:@"ChatData" withPredicate:predicate andOffset:offset];
    
    if (fetchedObjects == nil) {
        return nil;
    }
    
    NSMutableArray *dataArray = [NSMutableArray array];
    
    for (NSManagedObject *info in fetchedObjects) {
        [dataArray addObject:@{@"message" : [info valueForKey:@"message"],
                               @"date"    : [info valueForKey:@"date"]}];
    }
    return dataArray;
}

#pragma mark - Public methods

- (BOOL)saveChatDataForUser:(NSString *)username message:(NSString *)message date:(NSDate *)date{
    NSManagedObjectContext *managedObjectContext = [self managedContext];
    NSManagedObject *newManagedObject = [self managedObjectForEntityWithName:@"ChatData"];
    
    [newManagedObject setValue:date forKey:@"date"];
    [newManagedObject setValue:message forKey:@"message"];
    [newManagedObject setValue:username forKey:@"username"];
    
    NSError *error = nil;
    if(![managedObjectContext save:&error]){
        NSLog(@"Unresolved error: %@, %@", error, [error userInfo]);
        abort();
        return NO;
    }
    [self updatePagingData];
    return YES;
}

- (NSArray *)getChatDataForUser:(NSString *)username{
    [self setPagingDataUsingUsername:username];
    return [self getChatDataForUser:username withOffset:_pageOffset];
}

- (NSArray *)getMoreChatDataForUser:(NSString *)username{
    if ([self moreDataAvailable] == NO) {
        return nil;
    }
    return [self getChatDataForUser:username withOffset:_pageOffset];
}

@end
