//
//  LocationService.h
//  DownloadAndDisplayLocalHTML
//

#import <Foundation/Foundation.h>
@import CoreLocation;

@interface LocationService : NSObject <CLLocationManagerDelegate>

- (void)fakeManager;

- (NSString*)currentCountry:(CLPlacemark*)placemark;
- (NSString*)currentCountryCode:(CLPlacemark*)placemark;

@end
