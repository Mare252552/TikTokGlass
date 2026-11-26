#import "TGSettings.h"
#import "TGCompatibility.h"
NSNotificationName const TGPreferencesChanged = @"TikTokGlass.PreferencesChanged";
@implementation TGSettings
+ (instancetype)shared { static TGSettings *s; static dispatch_once_t once; dispatch_once(&once, ^{ s=[self new]; }); return s; }
- (instancetype)init {
    if ((self=[super init])) {
        _defaults=[[NSUserDefaults alloc] initWithSuiteName:@"dev.tiktokglass.preferences"];
        [_defaults registerDefaults:@{@"enabled":@YES,@"tabBar":@YES,@"navigation":@YES,
          @"buttons":@YES,@"comments":@YES,@"search":@YES,@"menus":@YES,
          @"videoControls":@YES,@"profile":@YES,@"intensity":@0.5,@"debug":@NO,@"barHeight":@62,@"barInset":@18,@"glassOpacity":@1}];
    } return self;
}
- (BOOL)enabled:(NSString *)key { return [self.defaults boolForKey:key]; }
- (void)setEnabled:(BOOL)value key:(NSString *)key {
    [self.defaults setBool:value forKey:key];
    [NSNotificationCenter.defaultCenter postNotificationName:TGPreferencesChanged object:self];
}
- (double)intensity { return [self.defaults doubleForKey:@"intensity"]; }
- (double)barHeight {return fmax(44,fmin(84,[self.defaults doubleForKey:@"barHeight"]));}
- (double)barInset {return fmax(8,fmin(48,[self.defaults doubleForKey:@"barInset"]));}
- (double)glassOpacity {return fmax(0,fmin(1,[self.defaults doubleForKey:@"glassOpacity"]));}
- (void)saveBarValue:(double)value key:(NSString *)key {[self.defaults setDouble:value forKey:key];[NSNotificationCenter.defaultCenter postNotificationName:TGPreferencesChanged object:self];}
- (void)setBarHeight:(double)value {[self saveBarValue:fmax(44,fmin(84,value)) key:@"barHeight"];}
- (void)setBarInset:(double)value {[self saveBarValue:fmax(8,fmin(48,value)) key:@"barInset"];}
- (void)setGlassOpacity:(double)value {[self saveBarValue:fmax(0,fmin(1,value)) key:@"glassOpacity"];}
- (void)setIntensity:(double)value {
    [self.defaults setDouble:fmax(0,fmin(1,value)) forKey:@"intensity"];
    [NSNotificationCenter.defaultCenter postNotificationName:TGPreferencesChanged object:self];
}
@end
@implementation TGSettingsController
- (instancetype)init { return [super initWithStyle:UITableViewStyleInsetGrouped]; }
- (NSArray<NSString *> *)keys { return @[@"enabled",@"tabBar",@"navigation",@"buttons",@"comments",@"search",@"menus",@"videoControls",@"profile",@"debug"]; }
- (NSArray<NSString *> *)titles { return @[@"Enable TikTokGlass",@"Glass Tab Bar",@"Glass Navigation",@"Glass Buttons",@"Glass Comments",@"Glass Search",@"Glass Menus",@"Glass Video Controls",@"Glass Profile",@"Debug Mode"]; }
- (void)viewDidLoad {
    [super viewDidLoad]; self.title=@"TikTokGlass 2.1";
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
}
- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 3; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return section==0 ? self.keys.count : (section==1 ? 4 : 2); }
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section==0) return @"Changes apply live. Only recognized, visible controls are adapted. Triple-tap with three fingers anywhere to reopen settings. With VoiceOver, use the accessible Glass settings button.";
    if (section==1) return @"Height: 44–84 pt. Side inset: 8–48 pt (larger inset = narrower bar). Glass opacity: 0–100%, affects the material, not icons. Settings apply live and persist. Opacity is not a refraction-strength API. Horizontal drag selects supported tabs; Reduce Transparency disables added glass.";
    return [NSString stringWithFormat:@"TikTok %@ · iOS %@\n47.9.0 is the priority target, not a device-verified version. Diagnostics contain class names and counts only; no labels, account data or video content.", [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"unknown", UIDevice.currentDevice.systemVersion];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)path {
    UITableViewCell *cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    if (path.section==0) {
        cell.textLabel.text=self.titles[path.row]; UISwitch *toggle=[UISwitch new]; toggle.tag=path.row;
        toggle.on=[[TGSettings shared] enabled:self.keys[path.row]];
        [toggle addTarget:self action:@selector(changed:) forControlEvents:UIControlEventValueChanged]; cell.accessoryView=toggle;
    } else if (path.section==1) {
        UISlider *slider=[UISlider new];slider.tag=path.row;
        NSArray *names=@[@"Glass Intensity",@"Bar Height",@"Side Inset / Bar Width",@"Glass Opacity"];
        slider.minimumValue=path.row==1?44:(path.row==2?8:0);slider.maximumValue=path.row==1?84:(path.row==2?48:1);
        slider.value=path.row==0?TGSettings.shared.intensity:(path.row==1?TGSettings.shared.barHeight:(path.row==2?TGSettings.shared.barInset:TGSettings.shared.glassOpacity));slider.continuous=YES;
        slider.accessibilityLabel=names[path.row];cell.textLabel.text=names[path.row];cell.textLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        [slider addTarget:self action:@selector(barChanged:) forControlEvents:UIControlEventValueChanged];
        slider.translatesAutoresizingMaskIntoConstraints=NO; [cell.contentView addSubview:slider];
        [NSLayoutConstraint activateConstraints:@[[slider.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:150], [slider.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-20], [slider.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor]]];
    } else {
        cell.textLabel.text=path.row==0 ? @"Show compatibility diagnostics" : @"Export diagnostics";
        cell.selectionStyle=UITableViewCellSelectionStyleDefault; cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    } return cell;
}
- (void)changed:(UISwitch *)sender { [[TGSettings shared] setEnabled:sender.on key:self.keys[sender.tag]]; }
- (void)intensityChanged:(UISlider *)sender { [TGSettings shared].intensity=sender.value; }
- (void)barChanged:(UISlider *)sender {switch(sender.tag){case 0:TGSettings.shared.intensity=sender.value;break;case 1:TGSettings.shared.barHeight=sender.value;break;case 2:TGSettings.shared.barInset=sender.value;break;case 3:TGSettings.shared.glassOpacity=sender.value;break;}}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path {
    [tableView deselectRowAtIndexPath:path animated:YES]; if (path.section!=2) return;
    NSString *report=TGDiagnosticReport();
    if (path.row==0) {
        UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"Compatibility" message:report preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        UIActivityViewController *share=[[UIActivityViewController alloc] initWithActivityItems:@[report] applicationActivities:nil];
        share.popoverPresentationController.sourceView=[tableView cellForRowAtIndexPath:path];
        [self presentViewController:share animated:YES completion:nil];
    }
}
@end
