//
//  LocationService.m
//  DownloadAndDisplayLocalHTML
//

#import "LocationService.h"

@interface LocationService()

@property (strong,nonatomic) CLLocationManager *locationManager;

@end

@implementation LocationService

- (void)fakeManager {
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    
    // Will open a confirm dialog to get user's approval
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    else {
        NSLog(@"This shouldn't execute");
        nil;
    }
}

- (NSString*)currentCountry:(CLPlacemark*)placemark {
    NSString* currentCountry = [placemark country];
    NSLog(@"Current country: %@",currentCountry);
    return currentCountry;
}

- (NSString*)currentCountryCode:(CLPlacemark*)placemark {
    NSString* currentCountryCode = [placemark ISOcountryCode];
    NSLog(@"Current country code: %@",currentCountryCode);
    return currentCountryCode;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    //NSLog(@"%@", location);
    // use reverse geocoding to get the current country from the coordinates
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error)
     {
         if (placemarks == nil) {
             return;
         }
         
         [self currentCountry:[placemarks objectAtIndex:0]];
         [self currentCountryCode:[placemarks objectAtIndex:0]];
     }];
    // it is safe to assume that the user's current country won't change during the usage of the app
    // the current country will update upon relaunching the app
    // NSLog(@"Stop updating location");
    [manager stopUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager*)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status) {
        case kCLAuthorizationStatusNotDetermined: {
            NSLog(@"Access rights not determined");
        } break;
        case kCLAuthorizationStatusDenied: {
            NSLog(@"Access to Location Services denied");
        } break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusAuthorizedAlways: {
            // NSLog(@"Start updating location.");
            [manager startUpdatingLocation];
        } break;
        default:
            break;
    }
}

@end
