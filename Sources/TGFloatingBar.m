#import "TGFloatingBar.h"
#import "TGSettings.h"
@interface TGFloatingBar () <UIGestureRecognizerDelegate,UITabBarDelegate>
@property(nonatomic,weak) UIView *host;
@property(nonatomic,strong) NSArray<UIView *> *buttons;
@property(nonatomic,strong) NSArray<NSValue *> *frames;
@property(nonatomic,strong) NSArray *colors;
@property(nonatomic,strong) NSMutableArray<UIView *> *backgrounds;
@property(nonatomic,strong) UIVisualEffectView *container;
@property(nonatomic,strong) UIVisualEffectView *body;
@property(nonatomic,strong) UIVisualEffectView *lens;
@property(nonatomic,strong) NSMutableArray<UIGestureRecognizer *> *gestures;
@property(nonatomic,strong) UIColor *background;
@property(nonatomic) CGRect originalFrame;
@property(nonatomic) BOOL clipped;
@property(nonatomic) NSInteger selected;
@property(nonatomic,strong) UITabBar *nativeBar;
@property(nonatomic,strong) NSArray<NSNumber *> *hiddenStates;
@property(nonatomic) BOOL dragging;
@end
@implementation TGFloatingBar
- (instancetype)initWithHost:(UIView *)host buttons:(NSArray<UIView *> *)buttons {
    if((self=[super init])) {
        _host=host;_buttons=[buttons copy];_originalFrame=host.frame;_background=host.backgroundColor;_clipped=host.clipsToBounds;_selected=0;
        NSMutableArray *frames=[NSMutableArray new],*colors=[NSMutableArray new];_backgrounds=[NSMutableArray new];_gestures=[NSMutableArray new];
        for(UIView *button in buttons) {
            [frames addObject:[NSValue valueWithCGRect:button.frame]];[colors addObject:button.backgroundColor ?: NSNull.null];
            if([button isKindOfClass:UIControl.class]) [(UIControl *)button addTarget:self action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
            else {UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];tap.cancelsTouchesInView=NO;tap.delegate=self;[button addGestureRecognizer:tap];[_gestures addObject:tap];}
        }_frames=frames;_colors=colors;
        // Only broad decorative direct leaves; never hide text, badges or controls.
        for(UIView *v in [host.subviews copy]) if(![buttons containsObject:v] && !v.hidden && v.subviews.count==0 && (v.class==UIView.class || [v isKindOfClass:UIImageView.class]) && v.bounds.size.width>host.bounds.size.width*0.8 && v.bounds.size.height>30) {[_backgrounds addObject:v];v.hidden=YES;}
        UIGlassContainerEffect *group=[UIGlassContainerEffect new];group.spacing=4;
        _container=[[UIVisualEffectView alloc] initWithEffect:group];_container.accessibilityIdentifier=@"TikTokGlass.FloatingContainer";_container.userInteractionEnabled=NO;_container.accessibilityElementsHidden=YES;
        _body=[[UIVisualEffectView alloc] initWithEffect:[UIGlassEffect effectWithStyle:UIGlassEffectStyleClear]];
        UIGlassEffect *selection=[UIGlassEffect effectWithStyle:UIGlassEffectStyleRegular];selection.interactive=YES;
        _lens=[[UIVisualEffectView alloc] initWithEffect:selection];_lens.accessibilityIdentifier=@"TikTokGlass.ActiveGlass";
        [_container.contentView addSubview:_body];[_container.contentView addSubview:_lens];[host insertSubview:_container atIndex:0];
        NSMutableArray *items=[NSMutableArray new],*hidden=[NSMutableArray new];BOOL native=YES;
        for(NSUInteger i=0;i<buttons.count;i++) {
            UIView *button=buttons[i];[hidden addObject:@(button.hidden)];UIImage *image=nil;NSString *title=nil;
            if([button isKindOfClass:UIButton.class]) {image=((UIButton *)button).currentImage;title=((UIButton *)button).currentTitle;}
            for(UIView *child in button.subviews) {if(!image && [child isKindOfClass:UIImageView.class]) image=((UIImageView *)child).image;if(!title && [child isKindOfClass:UILabel.class]) title=((UILabel *)child).text;}
            BOOL actionable=NO;
            if([button isKindOfClass:UIControl.class]) for(id target in [(UIControl *)button allTargets]) if(target!=self && ([(UIControl *)button actionsForTarget:target forControlEvent:UIControlEventTouchUpInside].count || [(UIControl *)button actionsForTarget:target forControlEvent:UIControlEventPrimaryActionTriggered].count)) actionable=YES;
            if(!actionable || !image) native=NO;
            UITabBarItem *item=[[UITabBarItem alloc] initWithTitle:title image:image tag:i];
            if([button isKindOfClass:UIButton.class]) item.selectedImage=[(UIButton *)button imageForState:UIControlStateSelected] ?: image;
            item.accessibilityLabel=button.accessibilityLabel ?: title;[items addObject:item];
        }_hiddenStates=hidden;
        if(native) {
            _nativeBar=[[UITabBar alloc] initWithFrame:host.bounds];_nativeBar.accessibilityIdentifier=@"TikTokGlass.NativeTabBar";
            _nativeBar.delegate=self;_nativeBar.items=items;_nativeBar.itemPositioning=UITabBarItemPositioningFill;
            // Keep UIKit's default iOS 26 material and selection lens. Do not replace its private subviews or gestures.
            [host addSubview:_nativeBar];_container.hidden=YES;for(UIView *button in buttons) button.hidden=YES;
        } else {
            UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)];pan.delegate=self;[host addGestureRecognizer:pan];[_gestures addObject:pan];
        }
    }return self;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b {return YES;}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gesture {if([gesture isKindOfClass:UIPanGestureRecognizer.class]) {CGPoint v=[(UIPanGestureRecognizer *)gesture velocityInView:self.host];return fabs(v.x)>fabs(v.y);}return YES;}
- (void)activate:(NSUInteger)index {
    if(index>=self.buttons.count) return;UIView *view=self.buttons[index];
    if([view isKindOfClass:UIControl.class]) {UIControl *control=(id)view;BOOL primary=NO;for(id target in control.allTargets) if(target!=self && [control actionsForTarget:target forControlEvent:UIControlEventPrimaryActionTriggered].count) primary=YES;
        [control sendActionsForControlEvents:primary?UIControlEventPrimaryActionTriggered:UIControlEventTouchUpInside];}
}
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    NSInteger old=self.selected;[self activate:item.tag];
    self.selected=(self.buttons.count==5 && item.tag==2)?old:item.tag;[self update];
}
- (void)panned:(UIPanGestureRecognizer *)pan {
    CGFloat slot=self.host.bounds.size.width/self.buttons.count;CGPoint p=[pan locationInView:self.host];
    if(pan.state==UIGestureRecognizerStateBegan || pan.state==UIGestureRecognizerStateChanged) {
        self.dragging=YES;self.lens.center=CGPointMake(fmax(slot/2,fmin(self.host.bounds.size.width-slot/2,p.x)),31);
    } else {
        self.dragging=NO;
        if(pan.state==UIGestureRecognizerStateEnded) {NSUInteger index=MIN(self.buttons.count-1,(NSUInteger)fmax(0,floor(p.x/slot)));if([self.buttons[index] isKindOfClass:UIControl.class]) [self activate:index];}
        [self update];
    }
}
- (void)tapped:(id)sender {
    UIView *button=[sender isKindOfClass:UIGestureRecognizer.class]?[(UIGestureRecognizer *)sender view]:sender;
    NSUInteger index=[self.buttons indexOfObject:button];
    // Create is an action, not a persistent page selection.
    if(index!=NSNotFound && !(self.buttons.count==5 && index==2)) {self.selected=index;[self update];}
}
- (void)update {
    UIView *host=self.host;if(!host) return;
    UIWindow *window=host.window;
    if(window && host.superview) {
        CGFloat bottom=window.bounds.size.height-window.safeAreaInsets.bottom-10;
        CGRect floating=CGRectMake(18,bottom-62,window.bounds.size.width-36,62);
        host.frame=[window convertRect:floating toView:host.superview];
    }
    host.backgroundColor=UIColor.clearColor;host.clipsToBounds=NO;
    self.container.frame=host.bounds;self.body.frame=host.bounds;
    self.nativeBar.frame=host.bounds;self.nativeBar.layer.cornerRadius=31;self.nativeBar.clipsToBounds=YES;
    self.body.layer.cornerRadius=31;self.body.clipsToBounds=YES;
    CGFloat slot=host.bounds.size.width/self.buttons.count;
    for(NSUInteger i=0;i<self.buttons.count;i++) {
        UIView *button=self.buttons[i];button.backgroundColor=UIColor.clearColor;
        button.frame=CGRectMake(slot*i,0,slot,62);
        if(!self.dragging && (([button isKindOfClass:UIControl.class] && [(UIControl *)button isSelected]) || (button.accessibilityTraits&UIAccessibilityTraitSelected))) self.selected=i;
    }
    if(self.nativeBar) {self.nativeBar.selectedItem=self.nativeBar.items[self.selected];for(UIView *button in self.buttons) button.hidden=YES;return;}
    if(self.dragging) return;
    CGRect target=CGRectMake(slot*self.selected+3,4,slot-6,54);
    self.lens.layer.cornerRadius=27;self.lens.clipsToBounds=YES;
    if(CGRectEqualToRect(target,self.lens.frame)) return;
    if(UIAccessibilityIsReduceMotionEnabled() || CGRectIsEmpty(self.lens.frame)) self.lens.frame=target;
    else [UIView animateWithDuration:0.38 delay:0 usingSpringWithDamping:0.86 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction animations:^{self.lens.frame=target;} completion:nil];
}
- (void)restore {
    [self.nativeBar removeFromSuperview];[self.container removeFromSuperview];self.host.frame=self.originalFrame;self.host.backgroundColor=self.background;self.host.clipsToBounds=self.clipped;
    for(NSUInteger i=0;i<self.buttons.count;i++) {UIView *button=self.buttons[i];button.hidden=self.hiddenStates[i].boolValue;button.frame=self.frames[i].CGRectValue;button.backgroundColor=self.colors[i]==NSNull.null?nil:self.colors[i];if([button isKindOfClass:UIControl.class]) [(UIControl *)button removeTarget:self action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];}
    for(UIGestureRecognizer *gesture in self.gestures) [gesture.view removeGestureRecognizer:gesture];
    for(UIView *v in self.backgrounds) v.hidden=NO;
}
@end
