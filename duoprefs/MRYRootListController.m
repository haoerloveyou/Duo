#include "MRYHomepageListController.h"
#include "MRYReorderListController.h"

#define PLIST_PATH @"/var/mobile/Library/Preferences/com.muirey03.duo.plist"
#define prefsDict [NSDictionary dictionaryWithContentsOfFile:PLIST_PATH]
#define kWidth [[UIApplication sharedApplication] keyWindow].frame.size.width
#define kHeight [[UIApplication sharedApplication] keyWindow].frame.size.height

@implementation MRYHomepageListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Homepage" target:self];
	}

	return _specifiers;
}

-(void)openTwitter
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/Muirey03"]];
}

-(void)openTwitterChloe
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/nsaanxiety"]];
}
@end

@implementation DuoBannerCell
-(id)initWithSpecifier:(id)arg1
{
	self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
	if (self)
	{
		height = kWidth * 0.355;
		CGRect imgFrame = CGRectMake(0, 30, kWidth, height);
		img = [[UIImageView alloc] initWithFrame:imgFrame];
		[img setImage:[UIImage imageNamed:@"banner" inBundle:[NSBundle bundleForClass:[self class]]]];

		[self addSubview:img];
	}
	return self;
}

-(CGFloat)preferredHeightForWidth:(CGFloat)arg1
{
	return height + 30;
}
@end

@implementation MRYReorderListController
- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Reorder" target:self];
	}

	return _specifiers;
}

-(void)loadView
{
    [super loadView];

    //add respring button to nav bar
    UIBarButtonItem *respringButton = [[UIBarButtonItem alloc]  initWithTitle:@"Respring" style:UIBarButtonItemStylePlain target:self action:@selector(respring)];
    [self.navigationItem setRightBarButtonItem:respringButton];
}

-(void)respring
{
	system("killall -9 SpringBoard");
}
@end

//here we create the table and build the plists
@implementation RearrangeControlsView
- (id)initWithSpecifier:(PSSpecifier *)specifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    if (self)
    {
		[self buildPlists];

        modulesTable = [[UITableView alloc] initWithFrame:CGRectMake(0, -30, kWidth, (includeCells.count + otherCells.count) * 45 + 176) style:UITableViewStyleGrouped];
		modulesTable.editing = YES;

        modulesTable.delegate = self;
        modulesTable.dataSource = self;

        [self addSubview:modulesTable];
    }
	return self;
}

-(CGFloat)preferredHeightForWidth:(CGFloat)arg1
{
    return modulesTable.frame.size.height + modulesTable.frame.origin.y;
}

//this updates the arrays with the installed modules to ensure each module is
//in one array and that there are no modules in either array that are no longer
//installed. It then writes the data from the arrays to the plist
-(void)buildPlists
{
	NSMutableDictionary *data = [NSMutableDictionary dictionaryWithContentsOfFile:PLIST_PATH];
	includeCells = [data objectForKey:@"includeCells"];
	otherCells = [data objectForKey:@"otherCells"];
	if (includeCells == nil)
	{
		includeCells = [[NSMutableArray alloc] init];
	}
	if (otherCells == nil)
	{
		otherCells = [[NSMutableArray alloc] init];
	}

	NSMutableArray* bundles = [[NSMutableArray alloc] init];

	NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/ControlCenter/Bundles" error:Nil];
    NSArray* stockDirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/System/Library/ControlCenter/Bundles" error:Nil];
    dirs = dirs ? [dirs arrayByAddingObjectsFromArray:stockDirs] : [[NSArray alloc] initWithArray:stockDirs];
    for (id dir in dirs)
	{
		NSString* bundle = [((NSString*)dir) substringWithRange:NSMakeRange(0, ((NSString*)dir).length - 7)];
		[bundles addObject:bundle];
		BOOL inPlist = NO;
		for (id module in includeCells)
		{
			if ([bundle isEqualToString:module])
			{
				inPlist = YES;
				break;
			}
		}
		if (!inPlist)
		{
			for (id module in otherCells)
			{
				if ([bundle isEqualToString:module])
				{
					inPlist = YES;
					break;
				}
			}
		}
		if (!inPlist)
		{
			[otherCells addObject:bundle];
		}
	}

	for(int i = 0; i < includeCells.count; i++)
	{
		BOOL exists = NO;
		for(NSString* b in bundles)
		{
			if ([b isEqualToString:includeCells[i]])
			{
				exists = YES;
				break;
			}
		}
		if (!exists)
		{
			[includeCells removeObjectAtIndex:i];
			i--;
		}
	}

	for(int i = 0; i < otherCells.count; i++)
	{
		BOOL exists = NO;
		for(NSString* b in bundles)
		{
			if ([b isEqualToString:otherCells[i]])
			{
				exists = YES;
				break;
			}
		}
		if (!exists)
		{
			[otherCells removeObjectAtIndex:i];
			i--;
		}
	}

	[self updatePlists];
}

//this writes the data from the arrays to the plist
-(void)updatePlists
{
	NSMutableDictionary *data = [[NSMutableDictionary alloc] init];

	[data setObject:includeCells forKey:@"includeCells"];
	[data setObject:otherCells forKey:@"otherCells"];
	[data writeToFile:PLIST_PATH atomically:YES];
}

//table view functions:
//we want 2 sections, one for the include cells and one for the others
-(long long)numberOfSectionsInTableView:(id)arg1
{
	return 2;
}

//this returns the number of cells in each section
-(long long)tableView:(id)arg1 numberOfRowsInSection:(long long)arg2
{
	if (arg2 == 0)
	{
    	return includeCells.count;
	}
	else
	{
		return otherCells.count;
	}
}

//this creates the cell and sets its label and image
-(id)tableView:(id)arg1 cellForRowAtIndexPath:(id)arg2
{
    RearrangeControlsCell* cell = [[RearrangeControlsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier: @"myID"];
	NSMutableString* moduleName = [[NSMutableString alloc] init];
	NSMutableString* bundlePath = [[NSMutableString alloc] init];
	if (((NSIndexPath*)arg2).section == 0)
	{
		moduleName = (NSMutableString*)[includeCells objectAtIndex:((NSIndexPath*)arg2).row];
	}
	else
	{
		moduleName = (NSMutableString*)[otherCells objectAtIndex:((NSIndexPath*)arg2).row];
	}

    bundlePath = [NSMutableString stringWithFormat:@"/System/Library/ControlCenter/Bundles/%@.bundle", moduleName];
	NSBundle* moduleBundle = [NSBundle bundleWithPath:bundlePath];
	NSString* displayName = [[NSString alloc] init];
    if ([moduleBundle localizedInfoDictionary])
    {
		displayName = [[moduleBundle localizedInfoDictionary] valueForKey:@"CFBundleDisplayName"] ? [[moduleBundle localizedInfoDictionary] valueForKey:@"CFBundleDisplayName"] : moduleName;
    }
    else
    {
		bundlePath = [NSMutableString stringWithFormat:@"/Library/ControlCenter/Bundles/%@.bundle", moduleName];
		moduleBundle = [NSBundle bundleWithPath:bundlePath];
        displayName = [moduleBundle localizedStringForKey:moduleName value:displayName table:nil];
		if ([moduleName isEqualToString:displayName])
		{
			NSDictionary* infoPlist = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"/Library/ControlCenter/Bundles/%@.bundle/Info.plist", moduleName]];
			displayName = [infoPlist objectForKey:@"CFBundleDisplayName"] ? [infoPlist objectForKey:@"CFBundleDisplayName"] : displayName;
		}
	}

	NSString* bundlePlistPath = [[NSMutableString alloc] init];
	bundlePath = [NSMutableString stringWithFormat:@"/Library/ControlCenter/Bundles/%@.bundle", moduleName];
	UIImage* iconImage = [UIImage imageNamed:@"SettingsIcon" inBundle:[NSBundle bundleWithPath:bundlePath]];
	if (iconImage == nil)
	{
        bundlePath = [NSMutableString stringWithFormat:@"/System/Library/ControlCenter/Bundles/%@.bundle", moduleName];
        iconImage = [UIImage imageNamed:@"SettingsIcon" inBundle:[NSBundle bundleWithPath:bundlePath]];
        if (iconImage == nil)
		{
			bundlePlistPath = [NSString stringWithFormat:@"/System/Library/ControlCenter/Bundles/%@.bundle/Info.plist", moduleName];
			NSString* identifier = [[NSDictionary dictionaryWithContentsOfFile:bundlePlistPath] objectForKey:@"CFBundleIdentifier"];
			NSMutableString* imgPath = [NSMutableString stringWithFormat:@"/Library/Application Support/CCSupport/%@", identifier];
			iconImage = [UIImage imageAtPath:imgPath];
			if (iconImage == nil)
			{
				iconImage = [UIImage imageNamed:@"BlankIcon" inBundle:[NSBundle bundleForClass:[self class]]];
			}
			else
			{
				moduleBundle = [NSBundle bundleWithPath:@"/Library/Application Support/CCSupport"];
				displayName = [moduleBundle localizedStringForKey:moduleName value:displayName table:nil];
			}
        }
	}

	[cell.lbl setText:displayName];
	[cell.iconView setImage:iconImage];

	[modulesTable setContentSize:CGSizeMake(kWidth, kHeight)];

	return cell;
}

//each cell will be 45 high
-(double)tableView:(id)arg1 heightForRowAtIndexPath:(id)arg2
{
	return 45;
}

//each header will be 38 high
-(double)tableView:(id)arg1 heightForHeaderInSection:(long long)arg2
{
	return 38;
}

//create an empty UITableViewHeaderFooterView for each header
-(id)tableView:(id)arg1 viewForHeaderInSection:(long long)arg2
{
	UITableViewHeaderFooterView* v = [[UITableViewHeaderFooterView alloc] initWithFrame:CGRectMake(0, 0, kWidth, 38)];
	return v;
}

//set the text for each header
-(void)tableView:(id)arg1 willDisplayHeaderView:(id)arg2 forSection:(long long)arg3
{
	UITableViewHeaderFooterView* headerView = (UITableViewHeaderFooterView*)arg2;
	NSBundle* prefsBundle = [NSBundle bundleForClass:[self class]];
	NSString* headerText;
	if (arg3 == 0)
	{
		headerText = [prefsBundle localizedStringForKey:@"INCLUDE" value:@"INCLUDE" table:nil];
	}
	else
	{
		headerText = [prefsBundle localizedStringForKey:@"MORE_MODULES" value:@"MORE MODULES" table:nil];
	}
	[headerView.textLabel setText:headerText];
}

//allow editing of every cell
-(BOOL)tableView:(id)arg1 canEditRowAtIndexPath:(id)arg2
{
	return YES;
}

//allow movement of cells in the include section
-(BOOL)tableView:(id)arg1 canMoveRowAtIndexPath:(id)arg2
{
	return ((NSIndexPath*)arg2).section == 0;
}

//don't let the user move cells from the include section into the other section, that would fuck shit up
-(NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
	if (sourceIndexPath.section != proposedDestinationIndexPath.section)
	{
		NSInteger row = 0;
		if (sourceIndexPath.section < proposedDestinationIndexPath.section)
		{
			row = [tableView numberOfRowsInSection:sourceIndexPath.section] - 1;
		}
		return [NSIndexPath indexPathForRow:row inSection:sourceIndexPath.section];
	}

	return proposedDestinationIndexPath;
}

//insert the row at its new position and update the plists
-(void)tableView:(id)arg1 moveRowAtIndexPath:(id)arg2 toIndexPath:(id)arg3
{
	NSIndexPath* source = (NSIndexPath*)arg2;
	NSIndexPath* destination = (NSIndexPath*)arg3;

	id content = [includeCells objectAtIndex:source.row];
	[includeCells removeObjectAtIndex:source.row];
	[includeCells insertObject:content atIndex:destination.row];

	[self updatePlists];
}

//handle the deletion/addition of cells
-(void)tableView:(id)arg1 commitEditingStyle:(long long)arg2 forRowAtIndexPath:(id)arg3
{
	if ((UITableViewCellEditingStyle)arg2 == UITableViewCellEditingStyleDelete)
	{
		[otherCells addObject:[includeCells objectAtIndex:((NSIndexPath*)arg3).row]];
		[includeCells removeObjectAtIndex:((NSIndexPath*)arg3).row];
		[modulesTable reloadData];
	}
	else if ((UITableViewCellEditingStyle)arg2 == UITableViewCellEditingStyleInsert)
	{
		NSString* s = [otherCells objectAtIndex:((NSIndexPath*)arg3).row];
		NSString* bundlePlistPath = [NSString stringWithFormat:@"/Library/ControlCenter/Bundles/%@.bundle/Info.plist", s];
        if (![NSDictionary dictionaryWithContentsOfFile:bundlePlistPath])
        {
            bundlePlistPath = [NSString stringWithFormat:@"/System/Library/ControlCenter/Bundles/%@.bundle/Info.plist", s];
        }
        NSString* mID = [[NSDictionary dictionaryWithContentsOfFile:bundlePlistPath] objectForKey:@"CFBundleIdentifier"];

		[includeCells addObject:[otherCells objectAtIndex:((NSIndexPath*)arg3).row]];
		[otherCells removeObjectAtIndex:((NSIndexPath*)arg3).row];
		[modulesTable reloadData];

		NSString* configPath = @"/var/mobile/Library/ControlCenter/ModuleConfiguration_CCSupport.plist";
		NSMutableDictionary* configDict = [NSMutableDictionary dictionaryWithContentsOfFile:configPath];
		if (!configDict)
		{
			configPath = @"/var/mobile/Library/ControlCenter/ModuleConfiguration.plist";
			configDict = [NSMutableDictionary dictionaryWithContentsOfFile:configPath];
		}

		NSMutableArray* modules = [configDict objectForKey:@"module-identifiers"];
		if ([modules containsObject:mID])
		{
			[modules removeObject:mID];
		}
		[modules addObject:mID];

		[configDict setObject:modules forKey:@"module-identifiers"];
		[configDict writeToFile:configPath atomically:YES];
	}

	[self updatePlists];
}

//set the editing styles
-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0)
	{
		return UITableViewCellEditingStyleDelete;
	}
	else
	{
		return UITableViewCellEditingStyleInsert;
	}
}
@end

//init with a masked icon and a label
@implementation RearrangeControlsCell
-(id)initWithStyle:(long long)arg1 reuseIdentifier:(id)arg2
{
	self = [super initWithStyle:arg1 reuseIdentifier:arg2];
	if (self)
	{
		_iconView = [[UIImageView alloc] initWithFrame:CGRectMake(11, 8, 29, 29)];
		[_iconView.layer setCornerRadius:10];
		[_iconView.layer setMasksToBounds:YES];
		[[self contentView] addSubview:_iconView];

		_lbl = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, kWidth - 100, 45)];
		[_lbl setTextColor:[UIColor blackColor]];
		[[self contentView] addSubview:_lbl];
	}
	return self;
}
@end

@implementation InfoView
- (id)initWithSpecifier:(PSSpecifier *)specifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    if (self)
    {
		lbl = [[UILabel alloc] initWithFrame:CGRectMake(30, 0, kWidth - 60, 90)];
		NSBundle* prefsBundle = [NSBundle bundleForClass:[self class]];
		NSString* infoText = [prefsBundle localizedStringForKey:@"INFO" value:@"Add and organise modules to appear in the second page of the Control Center." table:nil];
		[lbl setText:infoText];
		lbl.textAlignment = NSTextAlignmentCenter;
		lbl.lineBreakMode = UILineBreakModeWordWrap;
		lbl.numberOfLines = 0;
		[[self contentView] addSubview:lbl];
	}
	return self;
}

-(CGFloat)preferredHeightForWidth:(CGFloat)arg1
{
	return lbl.frame.size.height;
}

-(void)setBackgroundColor:(UIColor*)arg1
{
	[super setBackgroundColor:nil];
}
@end
