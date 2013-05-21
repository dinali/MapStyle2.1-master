// Copyright 2012 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm

// DESCRIPTION: This is for SNAP and all the identical ERS maps.
// FEATURES: switch between layers using a callout, display legend, display location-specific popup with data
// DEVELOPER NOTES: the same code for the callout for the layers works auto-magically with the location-specific popup feature, doesn't requre extra coding; hard coded for just one map - SNAP 2009 Benefits
// TODO: changes in selection of map layer need to be reflected in the PopUp location; sort order of items in TOC
//

#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>
#import "LegendDataSource.h"
#import "LegendViewController.h"
#import "Reachability.h"

@interface MainViewController : UIViewController <AGSMapViewLayerDelegate, AGSLocatorDelegate, AGSCalloutDelegate, AGSMapViewTouchDelegate, AGSIdentifyTaskDelegate> {
    
	AGSMapView *_mapView;
	UIButton* _infoButton;
    
    // find adddress feature and display popup for location
    //UISearchBar *_searchBar;
    AGSGraphicsLayer *_graphicsLayer;
	AGSLocator *_locator;
	AGSCalloutTemplate *_calloutTemplate;
    
    // legend feature
    UIButton* _changeMapButton;
    
	LegendDataSource* _legendDataSource;
	LegendViewController* _legendViewController;
    
    //Only used with iPad - obsolete
	UIPopoverController* _popOverController;
}

@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) IBOutlet UIButton* infoButton; // map layers/subjects
@property (nonatomic, strong) UIPopoverController *popOverController;
@property (weak, nonatomic) IBOutlet AGSMapView *legendButton;

// find address feature
//@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer;
@property (nonatomic, strong) AGSLocator *locator;
@property (nonatomic, strong) AGSCalloutTemplate *calloutTemplate;

// show legend
@property (nonatomic, strong) LegendDataSource *legendDataSource;
@property (nonatomic, strong) LegendViewController *legendViewController;

// location popup
@property (nonatomic, retain) AGSIdentifyTask *identifyTask;
@property (nonatomic, retain) AGSIdentifyParameters *identifyParams;
@property (nonatomic, retain) AGSPoint* mappoint;
@property (nonatomic, retain) AGSGraphic *graphic;

//this is the map level layer info object, acting as the invisible root of the entire tree.
//@property (nonatomic, strong) AGSMapServiceLayerInfo *mapViewLevelLayerInfo;
@property NSInteger *dynamiclayerID;
@property (strong, nonatomic) IBOutlet UILabel *notificationLabel;


// display the activity indicator Map is Loading
@property (strong, nonatomic) IBOutlet UILabel *activityLabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)presentTableOfContents:(id)sender;  // display layers
- (IBAction)presentLegendViewController:(id)sender; // display legend


@end

