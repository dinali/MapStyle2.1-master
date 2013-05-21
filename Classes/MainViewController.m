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
//
#import "MainViewController.h"
#import "TOCViewController.h"
#import "LegendViewController.h"
#import "ResultsViewController.h"

@interface MainViewController()

@property (nonatomic, strong) TOCViewController *tocViewController;

@end

@implementation MainViewController

@synthesize mapView=_mapView;
@synthesize infoButton=_infoButton;
@synthesize legendButton = _legendButton;
@synthesize tocViewController = _tocViewController;
@synthesize popOverController = _popOverController;
@synthesize dynamiclayerID = _dynamiclayerID;
@synthesize activityIndicator = _activityIndicator;
@synthesize activityLabel = _activityLabel;
@synthesize notificationLabel = _notificationLabel;

#define kTiledLayerURL @"http://gis2.ers.usda.gov/ArcGIS/rest/services/Background_Cache/MapServer"
#define kDynamicMapServiceURL @"http://gis2.ers.usda.gov/ArcGIS/rest/services/snap_Benefits/MapServer"
#define kMapServiceURL @"http://gis2.ers.usda.gov/ArcGIS/rest/services/Reference2/MapServer" // states


// occurs After viewDidLoad
- (void) viewWillAppear:(BOOL)animated {
    //[[UIApplication sharedApplication].networkActivityIndicatorVisible]=YES;
       
    NSLog(@"viewWillAppear called");
}

- (void) viewDidAppear:(BOOL)animated{
    NSLog(@"viewDidAppear called");
   
}

- (void) viewDidDisappear:(BOOL)animated{
     NSLog(@"viewDidDisappear called");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
   // NSLog(@"viewDidLoad");
    
    _activityIndicator.hidden= NO;
    [_activityIndicator startAnimating];
    
    // this hard codes the length of time to display the indicator, that's not such a good approach because the network time might vary; this is the only place it works to call the displayIndicator
    [self performSelector:@selector(displayIndicator)withObject:nil afterDelay:15.0]; // 10 seconds

    //create the toc view controller, toc view controller changes visibility of the mapView without calling this viewDidLoad method
    self.tocViewController = [[TOCViewController alloc] initWithMapView:self.mapView];
    
    // check to see if there's internet connection
    Boolean wifiBoolean = [self checkForInternet];
    
    if((wifiBoolean = TRUE)){
        NSLog(@"got wifi, check next service");
    }
    else{
        NSLog(@"no wifi available");
    }
    
    // Calls method that adds the layer to the legend each time layer is loaded
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(respondToLayerLoaded:) name:AGSLayerDidLoadNotification object:nil];
    
    NSURL *mapUrl = [NSURL URLWithString:kTiledLayerURL];
	AGSTiledMapServiceLayer *tiledLyr = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mapUrl];
	[self.mapView addMapLayer:tiledLyr withName:@"Base Map"];
    
    NSURL *mapUrl3 = [NSURL URLWithString:kDynamicMapServiceURL]; // ERS SNAP
    
    NSError *error = nil;
    AGSMapServiceInfo *info = [AGSMapServiceInfo mapServiceInfoWithURL:mapUrl3 error:&error];
    
    AGSDynamicMapServiceLayer* layer = [AGSDynamicMapServiceLayer dynamicMapServiceLayerWithMapServiceInfo: info];
    
    // specifies which layer(s) are displayed on the map - this is different from what's displayed in the legend; without this code, nothing is displayed
    
    // modify this if the TOC view controller changes selection
    if(layer.loaded)
    {
        // only show the Xth layer
        layer.visibleLayers= [NSArray arrayWithObjects:[NSNumber numberWithInt:0], nil];
        layer.opacity = .8;
    } 
    
    [self.mapView addMapLayer:layer withName:@"Snap Benefits"];
    
    NSURL *stateMapUrl = [NSURL URLWithString:kMapServiceURL];
    AGSDynamicMapServiceLayer *dynamicLyr = [AGSDynamicMapServiceLayer dynamicMapServiceLayerWithURL:stateMapUrl];
    [self.mapView addMapLayer:dynamicLyr withName:@"States"];
    
    //Zooming to an initial envelope with the specified spatial reference of the map.
	AGSSpatialReference *sr = [AGSSpatialReference webMercatorSpatialReference];
	AGSEnvelope *env = [AGSEnvelope envelopeWithXmin:-14314526
                                                ymin:2616367
                                                xmax:-7186578
                                                ymax:6962565
									spatialReference:sr];
	[self.mapView zoomToEnvelope:env animated:YES];
    
    // ADDED FOR GEOCODING FIND ADDRESS, also need for popup location!
    
    //set the delegate on the mapView so we get notifications for user interaction with the callout for geocoding
    self.mapView.callout.delegate = self;
    
    // TODO: this might not be necessary
    //create the graphics layer that the geocoding result
    //will be stored in and add it to the map
    self.graphicsLayer = [AGSGraphicsLayer graphicsLayer];
    [self.mapView addMapLayer:self.graphicsLayer withName:@"Search Layer"];
    
    // current location marker: user's current location as starting point
    [self.mapView.locationDisplay startDataSource];
    
	// LEGEND: a data source that will hold the legend items
	self.legendDataSource = [[LegendDataSource alloc] init];
	
	//Initialize the legend view controller
	//This will be displayed when user clicks on the info button
    
	self.legendViewController = [[LegendViewController alloc] initWithNibName:@"LegendViewController" bundle:nil];
	self.legendViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
	self.legendViewController.legendDataSource = self.legendDataSource;
    
    // ADDED FOR POPUP BY LOCATION
    _mapView.touchDelegate = self;
    
    //create identify task
	self.identifyTask = [AGSIdentifyTask identifyTaskWithURL:[NSURL URLWithString:kDynamicMapServiceURL]];
	self.identifyTask.delegate = self;
	
	//create identify parameters
	self.identifyParams = [[AGSIdentifyParameters alloc] init];
    
    self.mapView.showMagnifierOnTapAndHold = YES;
    self.mapView.allowMagnifierToPanMap = YES;
   
}

// check for wifi
-(Boolean) checkForInternet{
    
    __block Boolean responseBoolean = FALSE;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    // should check availability of all 3 services??
    Reachability * reach = [Reachability reachabilityWithHostname:kTiledLayerURL];
    
    //  Reachability * reach = [Reachability reachabilityWithHostname:@"www.api.ers.usda.gov/REST/v1/charts/mostrecent/1/"];
    //  Reachability * reach = [Reachability reachabilityWithHostname:@"www.ers.usda.gov"];
    
    reach.reachableBlock = ^(Reachability * reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            _activityLabel.text = @"internet connection is available";
            responseBoolean = TRUE;
        });
        
    };
    
    reach.unreachableBlock = ^(Reachability * reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            _activityLabel.text = @"internet connection is not available";
            responseBoolean = FALSE;
        });
    };
    
    [reach startNotifier];
    return responseBoolean;
}

-(void)reachabilityChanged:(NSNotification*)note
{
    Reachability * reach = [note object];
    
    if([reach isReachable])
    {
        _notificationLabel.text = @"Notification Says Reachable";
    }
    else
    {
        _notificationLabel.text = @"Notification Says Unreachable";
    }
}
#pragma mark -
#pragma mark UIActivityIndicatorView

// had to be higher in the stack because it's covered as the layers are loaded
-(void) displayIndicator{
    
   // _activityLabel.text = @"please wait, map is loading...";
    [_activityIndicator stopAnimating];
   // _activityIndicator.hidesWhenStopped = YES;
    _activityLabel.hidden = YES;
    NSLog(@"displayIndicator");
}

#pragma mark -
#pragma mark AGSMapViewDelegate

- (void)respondToLayerLoaded:(NSNotification*)notification {
    
	//Add legend for each layer added to the map
	[self.legendDataSource addLegendForLayer:(AGSLayer *)notification.object];
}

// not called
- (void) mapViewDidLoad:(AGSMapView *) mapView {
    NSLog(@"loaded mapView");
    //[_activityIndicator stopAnimating];
}

#pragma mark - show the associated table view depending on which button was clicked

// sample code used a popOverController for the iPad, but it got confusing when both the legend and TOC are available.
- (IBAction)presentTableOfContents:(id)sender
{
    //If iPad, show legend in the PopOver, else transition to the separate view controller
	/*if([[AGSDevice currentDevice] isIPad]) {
        if(!self.popOverController) {
            self.popOverController = [[UIPopoverController alloc] initWithContentViewController:self.tocViewController];
            self.tocViewController.popOverController = self.popOverController;
            self.popOverController.popoverContentSize = CGSizeMake(320, 500);
            self.popOverController.passthroughViews = [NSArray arrayWithObject:self.view];
        }        
		[self.popOverController presentPopoverFromRect:self.infoButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES ];		
	}
    else {
		[self presentModalViewController:self.tocViewController animated:YES];
	} 
     */
    [self presentModalViewController:self.tocViewController animated:YES];
}

- (IBAction) presentLegendViewController: (id) sender{
	//If iPad, show legend in the PopOver, else transition to the separate view controller
	/*if([[AGSDevice currentDevice] isIPad]){
        if(!self.popOverController) {
            self.popOverController = [[UIPopoverController alloc] initWithContentViewController:self.legendViewController];
            self.legendViewController.popOverController = self.popOverController;
            self.popOverController.popoverContentSize = CGSizeMake(320, 500);
            self.popOverController.passthroughViews = [NSArray arrayWithObject:self.view];
        }
		[self.popOverController presentPopoverFromRect:self.legendButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES ];
        }
    */
    /*
        else {
		[self presentModalViewController:self.legendViewController animated:YES];
	}
    */
    [self presentModalViewController:self.legendViewController animated:YES];
}

#pragma mark -
#pragma mark AGSCalloutDelegate -- DISPLAYS THE box with related information for the location

- (void) didClickAccessoryButtonForCallout:(AGSCallout *) callout
{
    AGSGraphic* graphic = (AGSGraphic*) callout.representedObject;
    //The user clicked the callout button, so display the complete set of results
    ResultsViewController *resultsVC = [[ResultsViewController alloc] initWithNibName:@"ResultsViewController" bundle:nil];
    
    // this is the set to Exclude from the display in the popup
       
    NSMutableDictionary * tempDictionary = [graphic allAttributes].mutableCopy;
    [tempDictionary removeObjectForKey:@"OBJECTID"];
    [tempDictionary removeObjectForKey:@"Shape"];
    [tempDictionary removeObjectForKey:@"Shape_Area"];
    [tempDictionary removeObjectForKey:@"Shape_Length"];
    
    //set our attributes/results into the results VC
    resultsVC.results = tempDictionary;
    
    //display the results vc modally
    [self presentModalViewController:resultsVC animated:YES];
}


#pragma mark -
#pragma mark AGSLocatorDelegate

- (void)locator:(AGSLocator *)locator operation:(NSOperation *)op didFindLocationsForAddress:(NSArray *)candidates
{
    //check and see if we didn't get any results
	if (candidates == nil || [candidates count] == 0)
	{
        //show alert if we didn't get results
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Results"
                                                        message:@"No Results Found By Locator"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        
        [alert show];
	}
	else
	{
        //use these to calculate extent of results
        double xmin = DBL_MAX;
        double ymin = DBL_MAX;
        double xmax = -DBL_MAX;
        double ymax = -DBL_MAX;
		
		//create the callout template, used when the user displays the callout
		self.calloutTemplate = [[AGSCalloutTemplate alloc]init];
        
        //loop through all candidates/results and add to graphics layer
		for (int i=0; i<[candidates count]; i++)
		{
			AGSAddressCandidate *addressCandidate = (AGSAddressCandidate *)[candidates objectAtIndex:i];
            
            //get the location from the candidate
            AGSPoint *pt = addressCandidate.location;
            
            //accumulate the min/max
            if (pt.x  < xmin)
                xmin = pt.x;
            
            if (pt.x > xmax)
                xmax = pt.x;
            
            if (pt.y < ymin)
                ymin = pt.y;
            
            if (pt.y > ymax)
                ymax = pt.y;
            
			//create a marker symbol to use in our graphic
            AGSPictureMarkerSymbol *marker = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImageNamed:@"BluePushpin.png"];
            marker.offset = CGPointMake(9,16);
            marker.leaderPoint = CGPointMake(-9, 11);
            
            //set the text and detail text based on 'Name' and 'Descr' fields in the attributes
            self.calloutTemplate.titleTemplate = @"${Name}";
            self.calloutTemplate.detailTemplate = @"${Descr}";
			
            //create the graphic
			AGSGraphic *graphic = [[AGSGraphic alloc] initWithGeometry: pt
																symbol:marker
															attributes:[addressCandidate.attributes mutableCopy]
                                                  infoTemplateDelegate:self.calloutTemplate];
            
            
            //add the graphic to the graphics layer
			[self.graphicsLayer addGraphic:graphic];
            
            if ([candidates count] == 1)
            {
                //we have one result, center at that point
                [self.mapView centerAtPoint:pt animated:NO];
                
				// set the width of the callout
				self.mapView.callout.width = 250;
                
                //show the callout
                [self.mapView.callout showCalloutAtPoint:(AGSPoint*)graphic.geometry forGraphic:graphic animated:YES];
            }
			
			//release the graphic bb
		}
        
        //if we have more than one result, zoom to the extent of all results
        int nCount = [candidates count];
        if (nCount > 1)
        {
            AGSMutableEnvelope *extent = [AGSMutableEnvelope envelopeWithXmin:xmin ymin:ymin xmax:xmax ymax:ymax spatialReference:self.mapView.spatialReference];
            [extent expandByFactor:1.5];
			[self.mapView zoomToEnvelope:extent animated:YES];
        }
	}
    
}

#pragma mark - AGSCalloutDelegate methods

- (void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphicsDict {
    
    //store for later use
    self.mappoint = mappoint;
    
	//the layer we want is layer ‘5’ (from the map service doc)
	self.identifyParams.layerIds = [NSArray arrayWithObjects:[NSNumber numberWithInt:1], nil];
	self.identifyParams.tolerance = 3;
	self.identifyParams.geometry = self.mappoint;
	self.identifyParams.size = self.mapView.bounds.size;
	self.identifyParams.mapEnvelope = self.mapView.visibleArea.envelope;
	self.identifyParams.returnGeometry = YES;
	self.identifyParams.layerOption = AGSIdentifyParametersLayerOptionAll;
	self.identifyParams.spatialReference = self.mapView.spatialReference;
    
	//execute the task
	[self.identifyTask executeWithParameters:self.identifyParams];
}


#pragma mark - AGSIdentifyTaskDelegate methods
//results are returned
- (void)identifyTask:(AGSIdentifyTask *)identifyTask operation:(NSOperation *)op didExecuteWithIdentifyResults:(NSArray *)results {
    
    //clear previous results
    [self.graphicsLayer removeAllGraphics];
    
    if ([results count] > 0) {
        
        //add new results
        AGSSymbol* symbol = [AGSSimpleFillSymbol simpleFillSymbol];
        symbol.color = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.5];
        
        NSString *title = nil;
        NSUInteger layerID = 0;
        
        @try {
            
            // for each result, set the symbol and add it to the graphics layer
            for (AGSIdentifyResult* result in results) {
                result.feature.symbol = symbol;
                [self.graphicsLayer addGraphic:result.feature];
                _graphic = result.feature;
                title = result.layerName;
                layerID = result.layerId; // can this be a filter? not used
            }
            
            self.mapView.callout.title = title; // this is just the title
            self.mapView.callout.detail = @"Click for details";
            
            // Show callout for graphic
            [self.mapView.callout showCalloutAtPoint:self.mappoint forGraphic:_graphic animated:YES];
        }
        @catch (NSException * e) {
            NSLog(@"Exception: %@", e);
        }
        @finally {
            NSLog(@"finally");
        }
    }
}

//if there's an error with the query display it to the user
- (void)identifyTask:(AGSIdentifyTask *)identifyTask operation:(NSOperation *)op didFailWithError:(NSError *)error {
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
													message:[error localizedDescription]
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}

- (void)locator:(AGSLocator *)locator operation:(NSOperation *)op didFailLocationsForAddress:(NSError *)error
{
    //The location operation failed, display the error
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Locator Failed"
                                                    message:[NSString stringWithFormat:@"Error: %@", error.description]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    
    [alert show];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {

    [self setLegendButton:nil];
    [self setActivityLabel:nil];
    [self setActivityIndicator:nil];
    [self setNotificationLabel:nil];
    [super viewDidUnload];
	self.mapView = nil;
	self.infoButton = nil;
    self.tocViewController = nil;
    if([[AGSDevice currentDevice] isIPad])
        self.popOverController = nil;
}



@end
