//
//  PDFPagingViewController.m
//  PdfAnnotator
//
//  Created by Raphael Cruzeiro on 7/10/11.
//  Copyright 2011 Raphael Cruzeiro. All rights reserved.
//

#import "PDFPagingViewController.h"
#import "PDFDocument.h"
#import "PDFThumbnailFactory.h"

@implementation PDFPagingViewController

@synthesize delegate;
@synthesize _document;
@synthesize thumbFactory;
@synthesize collapseButton;
@synthesize scrollView;
@synthesize pagePlaceholder;
@synthesize loading;

- (id)initWithDocument:(PDFDocument *)document AndObserver:(id<PDFPagingViewProtocol>)observer
{
    if((self = [super init])){
        self.delegate = observer;
        expanded = false;
        self._document = document;
        currentX = 0;
        self.thumbFactory = [[[PDFThumbnailFactory alloc] initWithDocument:self._document] autorelease];
        pagePlaceholder = [[UIImage imageNamed:@"pagePlaceholder.png"] autorelease];
        loading = [[UIImage imageNamed:@"progressIndicator_roller.gif"] autorelease];
    }
    
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    for(UIButton *btn in scrollView.subviews) {
        if([btn isKindOfClass:[UIButton class]]){
            [btn setImage:loading forState:UIControlStateNormal];
        }
    }
    
    [self loadThumbs];
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    expandedFrame = CGRectMake(0, 754, 768, 270);
    collapsedFrame = CGRectMake(0, 962, 768, 270);
    
    self.view.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
    UIView *gradient = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 768, 270)] autorelease];
    [gradient setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"gradient.png"]]];
    [gradient setAlpha:0.5f];
    [self.view addSubview:gradient];
    
    // self.view.alpha = 0.2;
    self.view.frame = collapsedFrame;
    
    collapseButton = [UIButton buttonWithType:UIButtonTypeInfoDark];

    [collapseButton setImage:[UIImage imageNamed:@"arrowDown.png"] forState:UIControlStateNormal];
    [collapseButton addTarget:self action:@selector(toggle) forControlEvents:UIControlEventTouchDown];
    
    [collapseButton setFrame:CGRectMake(25, 7, 30, 30)];
    [collapseButton setBackgroundColor:[UIColor colorWithRed:173 green:176 blue:183 alpha:0]];
    [self.view addSubview:collapseButton];
    
    CGFloat startingX = 10;
    
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 50, 768, 170)];
    scrollView.delegate = self;
    scrollView.contentSize = CGSizeMake([self._document pageCount] * 130, 170);
    
    for(NSInteger i = 1 ; i <= [self._document pageCount] && i; i++) {
        
        if(i > 10) {
            UIButton * thumbButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [thumbButton setBackgroundColor:[UIColor colorWithPatternImage:pagePlaceholder]];
            [thumbButton setImage:loading forState:UIControlStateNormal];
            [thumbButton setTag:i];
            
            [thumbButton addTarget:self action:@selector(pageItemClicked:) forControlEvents:UIControlEventTouchDown];
            
            [thumbButton setFrame:CGRectMake(startingX, 0, 120, 160)];
            
            [scrollView addSubview:thumbButton];
            
            startingX += 130;
            
            continue;
        }
        
        UIImage * thumb = [thumbFactory generateThumbnailForPage:i withSize:(CGSize){116, 156}];
        
        UIButton * thumbButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [thumbButton setBackgroundColor:[UIColor colorWithPatternImage:pagePlaceholder]];
        [thumbButton setImage:thumb forState:UIControlStateNormal];
        [thumbButton setTag:i];
        
        [thumbButton addTarget:self action:@selector(pageItemClicked:) forControlEvents:UIControlEventTouchDown];
        
        [thumbButton setFrame:CGRectMake(startingX, 0, 120, 160)];
        
        NSLog(@"%@", thumbButton);
        
        [scrollView addSubview:thumbButton];
        
        startingX += thumb.size.width + 10;
    }
    
    [self.view addSubview:scrollView];
    
    [self expand];
}

- (void)expand
{
    [UIView animateWithDuration:0.5 
                     delay:0 
                     options:UIViewAnimationCurveEaseOut 
                     animations:^{
                         self.view.frame = expandedFrame;
                     } 
                     completion:^(BOOL finished) {
                         expanded = true;
                     }
     ];
}

- (void)collapse
{
    [UIView animateWithDuration:0.5 
                     delay:0
                     options:UIViewAnimationCurveEaseOut 
                     animations:^{
                         self.view.frame = collapsedFrame;
                     } 
                     completion:^(BOOL finished) {
                         expanded = false;
                     }
     ];
}

- (void) toggle
{
    if(expanded) {
        [collapseButton setImage:[UIImage imageNamed:@"arrowUp.png"] forState:UIControlStateNormal];
        [self collapse];
    }
    else {
        [collapseButton setImage:[UIImage imageNamed:@"arrowDown.png"] forState:UIControlStateNormal];
        [self expand];
    }
}

- (void)pageItemClicked:(id)sender
{
    NSLog(@"Clicked %d", [((UIButton*)sender) tag]);
    [delegate pageSelected:[((UIButton*)sender) tag]];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)_scrollView willDecelerate:(BOOL)decelerate
{
        if(!decelerate)
            [self loadThumbs];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadThumbs];
}

- (void)loadThumbs
{
    CGFloat x = [scrollView contentOffset].x;
    
    NSInteger startingPage = x / 130;
    
    if(startingPage < 1) startingPage = 1;
    
    NSInteger endPage = startingPage +  7;

    for(NSInteger currentPage = startingPage ; currentPage <= endPage && (currentPage - 1) < [scrollView.subviews count] ;) {
        UIButton *currentButton = [scrollView.subviews objectAtIndex:currentPage - 1];
        
        // Since we're interating on the subviews we HAVE to check the class of the subview to ensure we're dealing with a button
        if([currentButton isKindOfClass:[UIButton class]]) {
            
            UIImage * thumb = [thumbFactory generateThumbnailForPage:currentPage withSize:(CGSize){116, 156}];
            
            [currentButton setImage:thumb forState:UIControlStateNormal];
            
            currentPage++;
        }
        
    }

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.

    for(UIButton *btn in scrollView.subviews) {
        if([btn isKindOfClass:[UIButton class]]) {
            [btn release];
        }
    }
    
    [scrollView release];
    [collapseButton release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)dealloc
{
    NSLog(@"%s", "Cleaning paging view...");
    
    [super dealloc];
}
@end
