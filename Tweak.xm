#define PLIST_PATH @"/var/mobile/Library/Preferences/com.muirey03.duo.plist"
#define prefsDict [NSDictionary dictionaryWithContentsOfFile:PLIST_PATH]
#define kHeight [[UIApplication sharedApplication] keyWindow].frame.size.height
#define SETTINGS_PLIST_PATH @"/var/mobile/Library/Preferences/com.muirey03.duoprefs.plist"
#define settingsDict [NSDictionary dictionaryWithContentsOfFile:SETTINGS_PLIST_PATH]
#define isPortrait scrollView.frame.size.width < scrollView.frame.size.height
#define isIPX (kHeight >= 812)

@interface UIView (Duo)
-(id)allSubviews;
@end

@interface CCUIModuleCollectionView : UIScrollView
-(void)_addSubview:(id)arg1 positioned:(long long)arg2 relativeTo:(id)arg3;
@end

@interface CCUIScrollView : UIScrollView
@end

@interface CCUIContentModuleContainerView : UIView
@property (nonatomic) CGRect desiredFrame;
@property (retain, nonatomic) NSString* moduleName;

-(NSString *)moduleIdentifier;
-(void)moveToSecondPage;
@end

@interface CCUIModularControlCenterOverlayViewController : UIViewController
-(void)rotationChanged:(NSNotification *)sender;
@end

static CCUIScrollView* scrollView;
static CGFloat pageHeight;
static CGFloat pageWidth;
static CCUIModuleCollectionView* ccView;
static id madHaxx;
static NSMutableArray* modules = [[NSMutableArray alloc] init];

static int lastX = 0;
static int lastY = 0;

static NSMutableArray* coveredPoints =  [[NSMutableArray alloc] init];
static CGFloat lowestY = 0;
static CGFloat gapSize = 0;
static CGFloat topGap = -1;
static CGFloat pocketHeight = 0;

static NSDictionary *preferences;

static BOOL PreferencesValue(NSString* key, BOOL fallback)
{
    return [preferences objectForKey:key] ? [[preferences objectForKey:key] boolValue] : fallback;
}

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    preferences = nil;
    CFStringRef appID = CFSTR("com.muirey03.duoprefs");
    CFArrayRef keyList = CFPreferencesCopyKeyList(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if (!keyList) {
        NSLog(@"There's been an error getting the key list!");
        return;
    }
    preferences = (__bridge NSDictionary *)CFPreferencesCopyMultiple(keyList, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if (!preferences) {
        NSLog(@"There's been an error getting the preferences dictionary!");
    }
    CFRelease(keyList);
}

%ctor
{
    preferences = [[NSDictionary alloc] initWithContentsOfFile:SETTINGS_PLIST_PATH];

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)PreferencesChangedCallback, CFSTR("com.muirey03.duoprefs-prefsreload"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}

%hook CCUIHeaderPocketView
-(void)setFrame:(CGRect)arg1
{
    pocketHeight = arg1.size.height;
    %orig;
}
%end

//create the view controller to handle the changing of pageDots
%hook CCUIModularControlCenterOverlayViewController
-(void)viewDidLoad
{
    %orig;

    if (PreferencesValue(@"TweakEnabled", YES))
    {
        //find the gap that the modules are from the top of the collection
        if(isPortrait)
        {
            for (id v in [self.view allSubviews])
            {
                if (![v isMemberOfClass:[objc_getClass("CCUIContentModuleContainerView") class]])
                {
                    continue;
                }

                if (((CCUIContentModuleContainerView*)v).frame.size.height >= pageHeight)
                {
                    continue;
                }

                CGFloat highest = ((CCUIContentModuleContainerView*)v).frame.origin.y;
                if (topGap < 0 || highest < topGap)
                {
                    topGap = highest;
                }
            }
        }

        //move madHaxx down so it doesn't mess up the blur at the top
        if (madHaxx)
        {
            [madHaxx setFrame:CGRectMake(0, topGap, pageWidth * 2, pageHeight)];
        }

        //move each module to the second page
        NSArray* includeCells = [prefsDict objectForKey:@"includeCells"];
        for (id s in includeCells)
        {
            NSString* bundlePlistPath = [NSString stringWithFormat:@"/Library/ControlCenter/Bundles/%@.bundle/Info.plist", s];
            if (![NSDictionary dictionaryWithContentsOfFile:bundlePlistPath])
            {
                bundlePlistPath = [NSString stringWithFormat:@"/System/Library/ControlCenter/Bundles/%@.bundle/Info.plist", s];
            }
            NSString* includeID = [[NSDictionary dictionaryWithContentsOfFile:bundlePlistPath] objectForKey:@"CFBundleIdentifier"];

            for (id m in modules)
            {
                NSString* mID = [(CCUIContentModuleContainerView*)m moduleIdentifier];

                if ([includeID isEqualToString:mID] && isPortrait)
                {
                    [(CCUIContentModuleContainerView*)m moveToSecondPage];
                    [(CCUIContentModuleContainerView*)m setDesiredFrame:((CCUIContentModuleContainerView*)m).frame];
                    break;
                }
            }
        }

        //find lowest module
        if(isPortrait)
        {
            for (id v in [self.view allSubviews])
            {
                if (![v isMemberOfClass:[objc_getClass("CCUIContentModuleContainerView") class]])
                {
                    continue;
                }

                if (((CCUIContentModuleContainerView*)v).frame.size.height >= pageHeight)
                {
                    continue;
                }

                CGFloat y = ((CCUIContentModuleContainerView*)v).frame.size.height + ((CCUIContentModuleContainerView*)v).frame.origin.y;
                if (y > lowestY)
                {
                    lowestY = y;
                }
            }
        }
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    %orig;

    if (PreferencesValue(@"TweakEnabled", YES))
    {
        //reset the current page
        if (!PreferencesValue(@"OpenOnPreviousPage", NO))
        {
            [ccView setPagingEnabled:NO];
            ccView.contentOffset = CGPointMake(0,0);
            [ccView setPagingEnabled:YES];
        }

        //reset the modules on the second page's frames when the cc is shown
        for (CCUIContentModuleContainerView* m in modules)
        {
            [m setFrame:[m desiredFrame]];
        }
    }
}
%end

//allow the cc to scroll
%hook CCUIScrollView
-(void)layoutSubviews
{
    %orig;

    if (PreferencesValue(@"TweakEnabled", YES))
    {
        //allow the collection to scroll
        [ccView setContentSize:CGSizeMake(scrollView.frame.size.width * 2, ccView.frame.size.height)];
        [ccView setShowsHorizontalScrollIndicator:NO];
        [ccView setShowsVerticalScrollIndicator:NO];
        [ccView setPagingEnabled:YES];
        [ccView setBounces:NO];
        [madHaxx setFrame:CGRectMake(0, topGap, pageWidth * 2, pageHeight)];
        if (gapSize != 0 && isPortrait)
        {
            //set the scroll view's content size, stripping that annoying white space
            CGFloat yF = [self.subviews[0] convertRect:self.frame toView:self].origin.y;
            [self setContentSize:CGSizeMake(pageWidth, lowestY + (2 * gapSize) + yF)];
        }

        scrollView = self;
    }
}
%end

//get the height and a pointer to the scroll view
%hook CCUIModuleCollectionView
-(void)layoutSubviews
{
    %orig;

    //store the page height and width and a pointer to the collection view
    if (PreferencesValue(@"TweakEnabled", YES))
    {
        pageHeight = self.frame.size.height;
        pageWidth = self.frame.size.width;
        ccView = self;
        if (isPortrait)
        {
            self.frame = self.frame;
        }
    }
}

//force the cc's contentSize to include the second page
-(void)setContentSize:(CGSize)arg1
{
    if(isPortrait && PreferencesValue(@"TweakEnabled", YES))
    {
        pageWidth = ccView.frame.size.width;

        if (arg1.width == pageWidth * 2)
        {
            %orig;
        }
    }
    else
    {
        %orig;
    }
}

//strip white space from bottom of cc
-(void)setFrame:(CGRect)arg1
{
    if(arg1.size.width < arg1.size.height && PreferencesValue(@"TweakEnabled", YES) && !isIPX)
    {
        CGFloat h = lowestY + (2 * gapSize);
        CGRect worldF = [self convertRect:self.superview.frame toView:nil];

        if (worldF.origin.y + h < kHeight - pocketHeight && lowestY != 0)
        {
            //modules do not go under page
            //find the total y frame:
            CGFloat yF = kHeight - h - worldF.origin.y;

            //position the view at the bottom of the screen
            arg1 = CGRectMake(0, yF, arg1.size.width, h);

            //set the content size so that it doesn't scroll incorrectly
            [self setContentSize:CGSizeMake(self.contentSize.width, arg1.size.height)];
        }
    }
    %orig;
}
%end

%hook CCUIContentModuleContainerView

%property (retain, nonatomic) CGRect desiredFrame;
%property (retain, nonatomic) NSString* moduleName;

//ensure all the modules have their frames set correctly
-(void)setFrame:(CGRect)arg1
{
    if (PreferencesValue(@"TweakEnabled", YES) && [self desiredFrame].size.width != 0 && isPortrait && self != madHaxx)
    {
        arg1 = [self desiredFrame];
    }
    if (arg1.size.width > 0)
    {
        %orig;
    }
}

-(void)layoutSubviews
{
    %orig;

    if (PreferencesValue(@"TweakEnabled", YES))
    {
        //create our madHaxx view
        if (!madHaxx && ccView)
        {
            madHaxx = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]];
            for (int i = 0; i < [((UIView*)madHaxx) subviews].count; i++)
            {
                [[((UIView*)madHaxx) subviews][i] removeFromSuperview];
            }
            ((UIView*)madHaxx).frame = CGRectMake(0, topGap, pageWidth * 2, pageHeight);
            [ccView _addSubview:madHaxx positioned:0 relativeTo:[self superview]];
        }

        //set each module's name
        if (![self moduleName])
        {
            NSString* myID = [self moduleIdentifier];
            NSArray* includeCells = [prefsDict objectForKey:@"includeCells"];
            for (id s in includeCells)
            {
                NSString* bundlePlistPath = [NSString stringWithFormat:@"/Library/ControlCenter/Bundles/%@.bundle/Info.plist", s];
                if (![NSDictionary dictionaryWithContentsOfFile:bundlePlistPath])
                {
                    bundlePlistPath = [NSString stringWithFormat:@"/System/Library/ControlCenter/Bundles/%@.bundle/Info.plist", s];
                }
                NSString* module = [[NSDictionary dictionaryWithContentsOfFile:bundlePlistPath] objectForKey:@"CFBundleIdentifier"];

                if ([module isEqualToString:myID])
                {
                    [modules addObject:self];
                    [self setModuleName:s];
                    break;
                }
            }
        }
    }
}

//move this module to the second page
%new
-(void)moveToSecondPage
{
    if (self.frame.origin.x < pageWidth)
    {
        NSInteger mWidthI = 1;
    	NSInteger mHeightI = 1;
    	CGFloat mWidthF = self.frame.size.width;
    	CGFloat mHeightF = self.frame.size.height;
        CGFloat oneMWidth;

    	NSString* bundlePlistPath = [NSString stringWithFormat:@"/Library/ControlCenter/Bundles/%@.bundle/Info.plist", [self moduleName]];
    	if (![NSDictionary dictionaryWithContentsOfFile:bundlePlistPath])
    	{
    		bundlePlistPath = [NSString stringWithFormat:@"/System/Library/ControlCenter/Bundles/%@.bundle/Info.plist", [self moduleName]];
    	}
    	if ([[NSDictionary dictionaryWithContentsOfFile:bundlePlistPath] objectForKey:@"CCSModuleSize"])
    	{
    		mWidthI = [[[[[NSDictionary dictionaryWithContentsOfFile:bundlePlistPath] objectForKey:@"CCSModuleSize"] objectForKey:@"Portrait"] objectForKey:@"Width"] integerValue];
    		mHeightI = [[[[[NSDictionary dictionaryWithContentsOfFile:bundlePlistPath] objectForKey:@"CCSModuleSize"] objectForKey:@"Portrait"] objectForKey:@"Height"] integerValue];
    	}
    	else
    	{
    		mWidthI = ceil(4 / (pageWidth / mWidthF));
            mHeightI = mHeightF < mWidthF ? ceil((mHeightF / mWidthF) * mWidthI) : floor((mHeightF / mWidthF) * mWidthI);
    	}

    	CGFloat leftF;
    	CGFloat topF;

    	BOOL colliding = NO;
    	do
    	{
    		colliding = NO;
    		for (int i = 0; i < mWidthI; i++)
    		{
    			for (int b = 0; b < mHeightI; b++)
    			{
    				CGPoint p = CGPointMake(i + lastX, b + lastY);

    				if ([coveredPoints containsObject:[NSValue valueWithCGPoint:p]])
    				{
    					colliding = YES;
    				}
    			}
    		}

    		if (colliding)
    		{
    			lastX++;

    			if (lastX > 3)
    			{
    				lastX = 0;
    				lastY++;
    			}
    		}
    	}
    	while (colliding);

    	switch (mWidthI)
    	{
    		case 1:
    			gapSize = (pageWidth - (4 * mWidthF)) / 7;
    			oneMWidth = (mWidthF - ((mWidthI - 1) * gapSize)) / mWidthI;
    			leftF = (gapSize * 2) + (lastX * oneMWidth) + (gapSize * lastX);
    			topF = ((oneMWidth + gapSize) * lastY) + topGap;
    			break;

    		case 2:
    			gapSize = (pageWidth - (2 * mWidthF)) / 5;
    			oneMWidth = (mWidthF - ((mWidthI - 1) * gapSize)) / mWidthI;
    			leftF = (gapSize * 2) + (lastX * oneMWidth) + (gapSize * lastX);
    			topF = (oneMWidth + gapSize) * lastY + topGap;
    			break;

    		case 3:
    			gapSize = self.frame.origin.x < pageWidth - (self.frame.origin.x + mWidthF) ? self.frame.origin.x / 2 : (pageWidth - (self.frame.origin.x + mWidthF)) / 2;
    			oneMWidth = (mWidthF - ((mWidthI - 1) * gapSize)) / mWidthI;
    			leftF = (gapSize * 2) + (lastX * oneMWidth) + (gapSize * lastX);
    			topF = (oneMWidth + gapSize) * lastY + topGap;
    			break;

    		case 4:
    			gapSize = (pageWidth - mWidthF) / 4;
    			oneMWidth = (mWidthF - ((mWidthI - 1) * gapSize)) / mWidthI;
    			leftF = (gapSize * 2) + (lastX * oneMWidth) + (gapSize * lastX);
    			topF = (oneMWidth + gapSize) * lastY + topGap;
    			break;
    	}

    	[self setDesiredFrame:CGRectMake(pageWidth + leftF, topF, mWidthF, mHeightF)];
    	self.frame = [self desiredFrame];

    	for (int i = 0; i < mWidthI; i++)
    	{
    		for (int b = 0; b < mHeightI; b++)
    		{
    			CGPoint p = CGPointMake(i + lastX, b + lastY);
    			[coveredPoints addObject:[NSValue valueWithCGPoint:p]];
    		}
    	}

    	lastX += mWidthI;
    	if (lastX > 3)
    	{
    		lastX = 0;
    		lastY++;
    	}
    }
}
%end
