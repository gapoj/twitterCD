//
//  ViewController.m
//  twitterFollowersCD
//
//  Created by Guillermo Apoj on 3/10/15.
//  Copyright (c) 2015 Globant. All rights reserved.
//


#import "MainViewController.h"
#import "FHSTwitterEngine.h"
#import "FollowersViewController.h"

#define consumerkey @"WR0WDIxzUIMqH6lL6vEALqbSw"
#define secretConsumerkey @"vj4Dw3xH0txTAZ7zTrRAUFCRlOGWecHOOKkYGGFDZ134JbKkBJ"


@interface MainViewController () <FHSTwitterEngineAccessTokenDelegate, UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *theTableView;
@property (nonatomic, assign) BOOL isStreaming;


@end

@implementation MainViewController

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor lightGrayColor];

    
    [[FHSTwitterEngine sharedEngine]permanentlySetConsumerKey:consumerkey andSecret:secretConsumerkey];
    [[FHSTwitterEngine sharedEngine]setDelegate:self];
    [[FHSTwitterEngine sharedEngine]loadAccessToken];
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return FHSTwitterEngine.sharedEngine.isAuthorized?3:1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
            [self postTweet];
            break;
      
        case 1:
            [self listResults];
            break;
        case 2:
            [self logout];
            
            break;
        default:
            break;
    }
    
    [_theTableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellID = @"CellID";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellID];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellID];
    }
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Post Tweet";
            cell.detailTextLabel.text = nil;
            break;
        case 1:
            cell.textLabel.text = @"Followers";
            cell.detailTextLabel.text = nil;
            break;
        case 2:
            cell.textLabel.text = @"Logout";
            cell.detailTextLabel.text = FHSTwitterEngine.sharedEngine.authenticatedUsername;
            break;
        default:
            break;
    }
    
    return cell;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:@"Tweet"]) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @autoreleasepool {
                NSString *tweet = [alertView textFieldAtIndex:0].text;
                id returned = [[FHSTwitterEngine sharedEngine]postTweet:tweet];
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                
                NSString *title = nil;
                NSString *message = nil;
                
                if ([returned isKindOfClass:[NSError class]]) {
                    NSError *error = (NSError *)returned;
                    title = [NSString stringWithFormat:@"Error %d",error.code];
                    message = error.localizedDescription;
                } else {
                    NSLog(@"%@",returned);
                    title = @"Tweet Posted";
                    message = tweet;
                }
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @autoreleasepool {
                        UIAlertView *av = [[UIAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [av show];
                    }
                });
            }
        });
    } else {
        if (buttonIndex == 1) {
            NSString *username = [alertView textFieldAtIndex:0].text;
            NSString *password = [alertView textFieldAtIndex:1].text;
            
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @autoreleasepool {
                    // getXAuthAccessTokenForUsername:password: returns an NSError, not id.
                    NSError *returnValue = [[FHSTwitterEngine sharedEngine]getXAuthAccessTokenForUsername:username password:password];
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        @autoreleasepool {
                            NSString *title = returnValue?[NSString stringWithFormat:@"Error %d",returnValue.code]:@"Success";
                            NSString *message = returnValue?returnValue.localizedDescription:@"You have successfully logged in via XAuth";
                            UIAlertView *av = [[UIAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                            [av show];
                            [_theTableView reloadData];
                        }
                    });
                }
            });
        }
    }
}

- (void)storeAccessToken:(NSString *)accessToken {
    [[NSUserDefaults standardUserDefaults]setObject:accessToken forKey:@"SavedAccessHTTPBody"];
}

- (NSString *)loadAccessToken {
    return [[NSUserDefaults standardUserDefaults]objectForKey:@"SavedAccessHTTPBody"];
}

- (IBAction)loginOAuth {
    UIViewController *loginController = [[FHSTwitterEngine sharedEngine]loginControllerWithCompletionHandler:^(BOOL success) {
        NSLog(success?@"L0L success":@"O noes!!! Loggen faylur!!!");
        [_theTableView reloadData];
    }];
    [self presentViewController:loginController animated:YES completion:nil];
}


- (IBAction)loginXAuth {
    UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"xAuth Login" message:@"Enter your Twitter login credentials:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Login", nil];
    [av setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
    [[av textFieldAtIndex:0]setPlaceholder:@"Username"];
    [[av textFieldAtIndex:1]setPlaceholder:@"Password"];
    [av show];
}

- (void)logout {
    [[FHSTwitterEngine sharedEngine]clearAccessToken];
    [_theTableView reloadData];
}



- (void)postTweet {
    UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Tweet" message:@"Write a tweet below. Make sure you're using a testing account." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Tweet", nil];
    [av setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[av textFieldAtIndex:0]setPlaceholder:@"Write a tweet here..."];
    [av show];
}



- (void)listResults {
   
    UIViewController *Main = [self.storyboard instantiateViewControllerWithIdentifier:@"Followers"];
    [self.navigationController pushViewController:Main animated:YES];
}


@end