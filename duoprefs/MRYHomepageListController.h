#import <Preferences/PSListController.h>

@interface MRYHomepageListController : PSListController
-(void)openTwitter;
-(void)openTwitterChloe;
@end

@interface DuoBannerCell : UITableViewCell
{
    CGFloat height;
    UIImageView* img;
}

-(id)initWithSpecifier:(id)arg1;
-(CGFloat)preferredHeightForWidth:(CGFloat)arg1;
@end
