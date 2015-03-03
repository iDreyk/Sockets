//
//  DataManager.m
//  Sockets
//
//  Created by Ilya Tsarev on 03.03.15.
//  Copyright (c) 2015 Ilya Tsarev. All rights reserved.
//

#import "DataManager.h"
#import <CoreData/CoreData.h>

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

- (NSArray *)fetchRequestForEntityName:(NSString *)entityName andPredicate:(NSPredicate *)predicate{
    NSManagedObjectContext *managedObjectContext = [self managedContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext];
    
    if (predicate) {
        [fetchRequest setPredicate:predicate];
    }
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (!error) {
        return fetchedObjects;
    }
    NSLog(@"ERROR: %@, %@", error, [error userInfo]);
    return nil;
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
    return YES;
}

- (NSArray *)getChatDataForUser:(NSString *)username{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"username LIKE %@", username];
    
    NSArray *fetchedObjects = [self fetchRequestForEntityName:@"ChatData" andPredicate:predicate];
    
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

@end
