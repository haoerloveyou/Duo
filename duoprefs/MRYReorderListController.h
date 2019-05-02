#import <Preferences/PSListController.h>

@interface UIImage (Duo)
+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle;
+ (UIImage *)imageAtPath:(id)arg1;
@end

@interface MRYReorderListController : PSListController
-(void)loadView;
-(void)respring;
@end

@interface RearrangeControlsView : UITableViewCell <UITableViewDelegate, UITableViewDataSource>
{
    UITableView* modulesTable;
    NSMutableArray* includeCells;
    NSMutableArray* otherCells;
}
-(id)initWithSpecifier:(id)arg1;
-(CGFloat)preferredHeightForWidth:(CGFloat)arg1;
-(void)buildPlists;
-(void)updatePlists;

-(long long)numberOfSectionsInTableView:(id)arg1;
-(long long)tableView:(id)arg1 numberOfRowsInSection:(long long)arg2;
-(id)tableView:(id)arg1 cellForRowAtIndexPath:(id)arg2;
-(double)tableView:(id)arg1 heightForRowAtIndexPath:(id)arg2;
-(double)tableView:(id)arg1 heightForHeaderInSection:(long long)arg2;
-(BOOL)tableView:(id)arg1 canEditRowAtIndexPath:(id)arg2;
-(BOOL)tableView:(id)arg1 canMoveRowAtIndexPath:(id)arg2;
-(NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath;
-(void)tableView:(id)arg1 moveRowAtIndexPath:(id)arg2 toIndexPath:(id)arg3;
-(void)tableView:(id)arg1 commitEditingStyle:(long long)arg2 forRowAtIndexPath:(id)arg3;
-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath;
-(void)tableView:(id)arg1 willDisplayHeaderView:(id)arg2 forSection:(long long)arg3;
-(id)tableView:(id)arg1 viewForHeaderInSection:(long long)arg2;
@end

@interface RearrangeControlsCell : UITableViewCell
@property (retain,nonatomic) UILabel* lbl;
@property (retain,nonatomic) UIImageView* iconView;
-(id)initWithStyle:(long long)arg1 reuseIdentifier:(id)arg2;
@end

@interface InfoView : UITableViewCell
{
    UILabel* lbl;
}
-(id)initWithSpecifier:(id)arg1;
-(CGFloat)preferredHeightForWidth:(CGFloat)arg1;
-(void)setBackgroundColor:(UIColor*)arg1;
@end
