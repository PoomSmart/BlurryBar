#import <UIKit/UIKit.h>

@interface SBIconBlurryBackgroundView : UIView
- (id)initWithFrame:(CGRect)frame;
@end

%hook UIStatusBarBackgroundView

- (id)initWithFrame:(CGRect)frame style:(id)style backgroundColor:(UIColor *)color
{
	self = %orig;
	if (self) {
		SBIconBlurryBackgroundView *blurView = [[%c(SBIconBlurryBackgroundView) alloc] initWithFrame:frame];
		blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self addSubview:blurView];
		[blurView release];
	}
	return self;
}

%end
