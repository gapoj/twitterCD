@import UIKit;

typedef void(^OTSDatabaseManagerStackSetupCompletionHandler)(BOOL suceeded, NSError *error);
typedef void(^OTSDatabaseManagerSaveCompletionHandler)(BOOL suceeded, NSError *error);

@interface OTSPersistance : NSObject

@property (strong, nonatomic, readonly) NSManagedObjectContext *mainThreadManagedObjectContext;

- (void)setupCoreDataStackWithCompletionHandler:(OTSDatabaseManagerStackSetupCompletionHandler)handler;
- (void)saveDataWithCompletionHandler:(OTSDatabaseManagerSaveCompletionHandler)handler;
- (NSManagedObjectContext*)privateContext;

@end
