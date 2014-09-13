//
//  HiTodayViewController.m
//  Hidrate
//
//  Created by Matthew Lewis on 9/13/14.
//  Copyright (c) 2014 Hidrate. All rights reserved.
//

#import "HiTodayViewController.h"
#import "PTDBeanManager.h"
#import "HiAppDelegate.h"
#import "Day.h"

@interface HiTodayViewController ()<PTDBeanManagerDelegate, PTDBeanDelegate>
@property (strong, nonatomic) PTDBeanManager *beanManager;
@property (strong, nonatomic) PTDBean *connectedBean;
@property (weak, nonatomic) IBOutlet UIView *waterView;
@end

@implementation HiTodayViewController

const int LOW_WATER_PX = 383;
const int HIGH_WATER_DIFF_PX = 284;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)beanManagerDidUpdateState:(PTDBeanManager *)beanManager
{
    if (self.beanManager.state == BeanManagerState_PoweredOn) {
        // if we're on, scan for advertisting beans
        NSError *error;
        [self.beanManager startScanningForBeans_error:&error];
        if (error) {
            DDLogError(@"Error in beanManagerDidUpdateState: %@", error);
        }
    } else if (self.beanManager.state == BeanManagerState_PoweredOff) {
        // do something else
    }
}

// bean discovered
- (void)BeanManager:(PTDBeanManager *)beanManager didDiscoverBean:(PTDBean *)bean error:(NSError *)error
{
    if (error) {
        return;
    }
    if (self.connectedBean == nil) {
        NSError *error;
        [self.beanManager connectToBean:bean error:&error];
        if (error) {
            DDLogError(@"Error in didDiscoverBean: %@", error);
        }
        self.connectedBean = bean;
    }
}

- (void)BeanManager:(PTDBeanManager *)beanManager didDisconnectBean:(PTDBean *)bean error:(NSError *)error
{
    [self.connectedBean setLedColor:nil];
}

// bean connected
- (void)BeanManager:(PTDBeanManager *)beanManager didConnectToBean:(PTDBean *)bean error:(NSError *)error
{
    if (error) {
        return;
    }
    // do stuff with your bean
    // Send twice due to bug
    [self.connectedBean sendSerialString:@"DATA PLZ"];
    [self.connectedBean sendSerialString:@"DATA PLZ"];
}

- (void)bean:(PTDBean *)bean serialDataReceived:(NSData *)data
{
    NSString *stringData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    DDLogVerbose(@"Received data: %@", stringData);
}

- (void)viewDidLoad
{
    [[self navigationItem] setHidesBackButton:YES];

    self.beanManager = [[PTDBeanManager alloc] initWithDelegate:self];
    
    NSManagedObjectContext *context = ((HiAppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;
    NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"Day"];
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[NSDate date]];
    
    int day = (int)[components day];
    int month = (int)[components month];
    int year = (int)[components year];

    fr.predicate = [NSPredicate predicateWithFormat:@"day=%ul AND month=%ul AND year=%ul", day, month, year];
    
    NSArray *results = [context executeFetchRequest:fr error:NULL];
    if(results.count == 0){
        Day *d = [NSEntityDescription insertNewObjectForEntityForName:@"Day" inManagedObjectContext:context];
        d.day = day;
        d.year = year;
        d.month = month;
        [context save:NULL];
    }
}

- (void)setWaterPercentConsumed:(int)percent
{
    [[self waterPercentLabel] setText:[NSString stringWithFormat:@"%d%%", percent]];
    int waves_pos = LOW_WATER_PX - ((HIGH_WATER_DIFF_PX * percent) / 100);
    [[self wavesImage] setFrame:CGRectMake(26, waves_pos, 261, 302)];
}

- (IBAction)debugSliderChanged:(UISlider *)sender
{
    [self setWaterPercentConsumed:[sender value]];
}

- (IBAction)unwindToToday:(UIStoryboardSegue *)segue
{
}

@end
