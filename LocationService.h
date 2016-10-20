//
//  LocationService.h
//  DownloadAndDisplayLocalHTML
//
//  Created by admin on 5/22/16.
//  Copyright © 2016 BrighterBrain. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreLocation;

@interface LocationService : NSObject <CLLocationManagerDelegate>

- (void)fakeManager;

- (NSString*)currentCountry:(CLPlacemark*)placemark;
- (NSString*)currentCountryCode:(CLPlacemark*)placemark;

@end
