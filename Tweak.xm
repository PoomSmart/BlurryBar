#import <UIKit/UIKit.h>

#define isiOS7 (kCFCoreFoundationVersionNumber >= 847.20)
#define isiOS70 (isiOS7 && kCFCoreFoundationVersionNumber < 847.23)
#define isiOS71 (kCFCoreFoundationVersionNumber >= 847.23)

@interface SBWallpaperEffectView : UIView
- (id)initWithWallpaperVariant:(int)variant;
- (void)setStyle:(int)style;
@end

@interface NSDistributedNotificationCenter : NSNotificationCenter
@end

static NSArray* _stylesFor70 = @[@9,
                               @16,@7,@6,@17,@10,@14,
                               @8,@11,
                               @12,@5,@3];

static NSArray* _stylesFor71 = @[@14,
                               @22,@9,@11,@23,@16,@20,
                               @12,@17,
                               @19,@3,@4];
                               
#define STYLEFOR70 [_stylesFor70[_styleIndex] intValue]
#define STYLEFOR71 [_stylesFor71[_styleIndex] intValue]

static NSInteger _styleIndex = 2;
static BOOL tweakEnabled = YES;

static void loadSettings()
{
	Boolean enabledExist;
	Boolean enabledValue = CFPreferencesGetAppBooleanValue(CFSTR("SBBlurryStatusBarEnabled"), CFSTR("com.apple.springboard"), &enabledExist);
	tweakEnabled = !enabledExist ? YES : enabledValue;
	
	Boolean keyExist;
	NSInteger index = CFPreferencesGetAppIntegerValue(CFSTR("SBBlurryStatusBarStyle"), CFSTR("com.apple.springboard"), &keyExist);
	_styleIndex = !keyExist ? 2 : index;
	if (_styleIndex < 0 || _styleIndex > 11)
		_styleIndex = 2;
}

%hook UIStatusBarBackgroundView

- (id)initWithFrame:(CGRect)frame style:(id)style backgroundColor:(UIColor *)color
{
	self = %orig;
	if (self) {
		SBWallpaperEffectView *blurView = [[%c(SBWallpaperEffectView) alloc] initWithWallpaperVariant:1];
		blurView.frame = frame;
		blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		loadSettings();
		[blurView setStyle:tweakEnabled ? (isiOS70 ? STYLEFOR70 : STYLEFOR71) : 0];
		[self addSubview:blurView];
		[blurView release];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(updateBlurStyle) name:@"com.ps.blurrybar.update" object:nil];
	}
	return self;
}

- (void)dealloc
{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	%orig;
}

%new
- (void)updateBlurStyle
{
	loadSettings();
	for (id view in [self subviews]) {
		if ([NSStringFromClass([view class]) isEqualToString:@"SBWallpaperEffectView"])
			[((SBWallpaperEffectView *)view) setStyle:tweakEnabled ? (isiOS70 ? STYLEFOR70 : STYLEFOR71) : 0];
	}
}

%end

static void update(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	loadSettings();
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.ps.blurrybar.update" object:nil];
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application
{
	%orig;
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, update, CFSTR("com.ps.blurrybar.prefs"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}

%end
