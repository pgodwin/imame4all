/*
 * This file is part of iMAME4all.
 *
 * Copyright (C) 2010 David Valdeita (Seleuco)
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 * In addition, as a special exception, Seleuco
 * gives permission to link the code of this program with
 * the MAME library (or with modified versions of MAME that use the
 * same license as MAME), and distribute linked combinations including
 * the two.  You must obey the GNU General Public License in all
 * respects for all of the code used other than MAME.  If you modify
 * this file, you may extend this exception to your version of the
 * file, but you are not obligated to do so.  If you do not wish to
 * do so, delete this exception statement from your version.
 */

//http://code.google.com/p/metasyntactic/source/browse/trunk/MetasyntacticShared/Classes/ImageUtilities.m?r=4217

#include "minimal.h"
#import "Helper.h"
#import "ScreenView.h"
#import "EmulatorController.h"
#import "HelpController.h"
#import "OptionsController.h"
#import "DonateController.h"
#import "FilterController.h"
#import <pthread.h>


#define IPHONE_MENU_NONE           0

#define IPHONE_MENU_EXIT                4
#define IPHONE_MENU_HELP                5
#define IPHONE_MENU_FILTER              6
#define IPHONE_MENU_OPTIONS             7
#define IPHONE_MENU_DONATE              9
#define IPHONE_MENU_DOWNLOAD           11
#define IPHONE_MENU_WIIMOTE            12

#define MyCGRectContainsPoint(rect, point)						\
	(((point.x >= rect.origin.x) &&								\
		(point.y >= rect.origin.y) &&							\
		(point.x <= rect.origin.x + rect.size.width) &&			\
		(point.y <= rect.origin.y + rect.size.height)) ? 1 : 0)  
		

extern unsigned long gp2x_pad_status;
extern int num_of_joys;

extern CGRect drects[100];
extern int ndrects;
//extern btUsed;
unsigned long btUsed = 0;
unsigned long iCadeUsed = 0;

extern CGRect rEmulatorFrame;
static CGRect rPortraitViewFrame;
static CGRect rPortraitViewFrameNotFull;

static CGRect rPortraitImageBackFrame;
static CGRect rPortraitImageOverlayFrame;

static CGRect rLandscapeViewFrame;
static CGRect rLandscapeViewFrameFull;
static CGRect rLandscapeViewFrameNotFull;
static CGRect rLandscapeImageOverlayFrame;
static CGRect rLandscapeImageBackFrame;

static CGRect rLoopImageMask;
static CGRect rShowKeyboard;

extern CGRect rExternal;
CGRect rView;

static CGRect rStickWindow;
extern CGRect rStickArea;
extern int iOS_stick_radio; 

extern int nativeTVOUT;
extern int overscanTVOUT;

int iphone_menu = IPHONE_MENU_NONE;

int iphone_controller_opacity = 50;
int iphone_is_landscape = 0;
int iphone_smooth_land = 0;
int iphone_smooth_port = 0;
int iphone_keep_aspect_ratio_land = 0;
int iphone_keep_aspect_ratio_port = 0;

extern int isIpad;
int safe_render_path = 1;
int enable_dview = 0;

int tv_filter_land = 0;
int tv_filter_port = 0;

int scanline_filter_land = 0;
int scanline_filter_port = 0;
     
/////
int global_fps = 0;
int global_showinfo = 1;
int global_sound = 0;
int iOS_animated_DPad = 0;
int iOS_4buttonsLand = 0;
int iOS_full_screen_land = 1;
int iOS_full_screen_port = 1;
int emulated_width = 320;
int emulated_height = 240;

extern int iOS_landscape_buttons;
int iOS_hide_LR=0;
int iOS_BplusX=0;
int iOS_landscape_buttons=2;
int iOS_skin = 1;
int iOS_skin_data = 1;
int iOS_wiiDeadZoneValue = 2;
int iOS_touchDeadZone = 1;

#define TOUCH_INPUT_DIGITAL 0
#define TOUCH_INPUT_ANALOG 1

int iOS_inputTouchType = 1;
int iOS_analogDeadZoneValue = 2;
int iOS_iCadeLayout = 1;
extern int iOS_waysStick;

int global_manufacturer=0;
int global_category=0;
int global_filter=1;
int global_clones=1;
int global_year=0;

int menu_exit_option = 0;

int game_list_num = 0;


#define STICK4WAY (iOS_waysStick == 4 && iOS_inGame)
#define STICK2WAY (iOS_waysStick == 2 && iOS_inGame)
        
enum { DPAD_NONE=0,DPAD_UP=1,DPAD_DOWN=2,DPAD_LEFT=3,DPAD_RIGHT=4,DPAD_UP_LEFT=5,DPAD_UP_RIGHT=6,DPAD_DOWN_LEFT=7,DPAD_DOWN_RIGHT=8};    

enum { BTN_B=0,BTN_X=1,BTN_A=2,BTN_Y=3,BTN_SELECT=4,BTN_START=5,BTN_L1=6,BTN_R1=7,BTN_L2=8,BTN_R2=9};

enum { BUTTON_PRESS=0,BUTTON_NO_PRESS=1};

//states
static int dpad_state;
static int old_dpad_state;

static int btnStates[NUM_BUTTONS];
static int old_btnStates[NUM_BUTTONS];

extern pthread_t main_tid;

extern int iphone_main (int argc, char **argv);
extern int iOS_inGame;
extern int iOS_exitGame;
extern int iOS_exitPause;

int actionPending=0;
int wantExit = 0;
int warnIcade = 1;

//SHARED y GLOBALES!
pthread_t	main_tid;

int __emulation_paused = 0;
int __emulation_run=0;

static EmulatorController *sharedInstance = nil;

extern void reset_video(void);	

void iphone_Reset_Views()
{

   if(sharedInstance==nil) return;
    
   //[sharedInstance changeUI];  
   [sharedInstance performSelectorOnMainThread:@selector(changeUI) withObject:nil waitUntilDone:NO];  
}

void* app_Thread_Start(void* args)
{

	__emulation_run = 1;
	
	mimain(0,NULL);

	return NULL;
}

@implementation EmulatorController

@synthesize externalView;

- (void)startEmulation{
    
    sharedInstance = self;
	     		
    //[self buildPortrait];
    				
    pthread_create(&main_tid, NULL, app_Thread_Start, NULL);
		
	struct sched_param param;
 
    //param.sched_priority = 63;
    param.sched_priority = 46;  
    //param.sched_priority = 100;
     
           
    if(pthread_setschedparam(main_tid, /*SCHED_RR*/ SCHED_OTHER, &param) != 0)    
             fprintf(stderr, "Error setting pthread priority\n");
    	
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{/*
                [[[UIAlertView alloc] initWithTitle:nil
                            message:@"action"
                            delegate:self cancelButtonTitle:nil
                            otherButtonTitles:@"Yes",@"No",nil] show];
   */                         
	// the user clicked one of the OK/Cancel buttons

	
	if(buttonIndex == 999)
    {
        return;
    }
    
    if(buttonIndex == 0 && menu_exit_option)
    {
   //        __emulation_paused = 0;
       iphone_menu = IPHONE_MENU_EXIT;
       iOS_exitGame = 0;
       wantExit = 1;	            
       UIAlertView* exitAlertView=[[UIAlertView alloc] initWithTitle:nil
                                                              message:@"are you sure you want to exit the game?"
                                                             delegate:self cancelButtonTitle:nil
                                                    otherButtonTitles:@"Yes",@"No",nil];                                                        
       [exitAlertView show];
       [exitAlertView release];           
       
    }        
    else if(buttonIndex == 0 + menu_exit_option)
    {
       iphone_menu = IPHONE_MENU_HELP;
       
       HelpController *addController =[HelpController alloc];
                               
       [self presentModalViewController:addController animated:YES];

       [addController release];
    }
    else if(buttonIndex == 1 + menu_exit_option)
    {
       iphone_menu = IPHONE_MENU_FILTER;  
        
       FilterController *addController=[FilterController alloc];

       //SQ: iOS seems to forget its real parent window and assumes the nav controller.
       //save this UIView for the filter controller later
       addController.savedparent = self;
        
       //SQ: We want a navigation controller creating for the filter options
       //The other options don't use the nav controller.
       UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:addController] autorelease];
       [navController setModalPresentationStyle: UIModalPresentationFormSheet];

       [self presentModalViewController:navController animated:YES];     
        
       [addController release];
    }
    else if(buttonIndex == 2 + menu_exit_option)
    {
       iphone_menu = IPHONE_MENU_OPTIONS;
       
       OptionsController *addController =[OptionsController alloc];
                               
       [self presentModalViewController:addController animated:YES];

       [addController release];
    }

    else if(buttonIndex == 3 + menu_exit_option)    
    {
       iphone_menu = IPHONE_MENU_DONATE;
       
       [self  resignFirstResponder];
       
       DonateController *addController =[DonateController alloc];
                               
       [self presentModalViewController:addController animated:YES];

       [addController release];
    }
 
    else if(buttonIndex == 4 + menu_exit_option)    
    {
       iphone_menu = IPHONE_MENU_WIIMOTE;
       
       [Helper startwiimote:self]; 
    }	    
    else   	    
    {
       [self endMenu];
    }
  	      
    [menu release];
    menu = nil;
                          
}

- (void)runMenu
{
    if(iphone_menu != IPHONE_MENU_NONE)
       return;

    if(menu!=nil)
    {

       [menu dismissWithClickedButtonIndex:999 animated:YES];
       [menu release];
       menu = nil;
    } 

    actionPending=1;
        
    //if(__emulation_paused)return;
    //btUsed = num_of_joys!=0;
  
    app_MuteSound();
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    __emulation_paused = 1;
  
    //UIActionSheet *alert;
    
    menu_exit_option  = iCadeUsed && iOS_inGame; 
    
    if(!menu_exit_option)
    {
		menu = [[UIActionSheet alloc] initWithTitle:
			   @"Choose an option from the menu. Press cancel to go back." delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil 
			   otherButtonTitles:@"Help",@"Filter",@"Options",@"Donate",@"WiiMote",@"Cancel", nil];    
    }
    else
    {
	    menu = [[UIActionSheet alloc] initWithTitle:
			   @"Choose an option from the menu. Press cancel to go back." delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil 
			   otherButtonTitles:@"Exit Game",@"Help",@"Filter",@"Options",@"Donate",@"WiiMote",@"Cancel", nil];
    }
	   
	/*   
	if(isIpad)
	  //[alert showInView:imageBack];
	  [alert showInView:self.view];
	else
	*/
	  [menu showInView:self.view];
	       
	//[menu release];
   
    [pool release]; 
     
}

- (void)endMenu{
	  app_DemuteSound();
	
	  int old = btUsed;
	  btUsed = num_of_joys!=0;
	    
	  if(((!iphone_is_landscape && iOS_full_screen_port) || (iphone_is_landscape && iOS_full_screen_land)) && btUsed && old!=btUsed)
	  {
	      //[self performSelectorOnMainThread:@selector(changeUI) withObject:nil waitUntilDone:YES];
	      [self changeUI]; 
	  }
	  if(((!iphone_is_landscape && iOS_full_screen_port) || (iphone_is_landscape && iOS_full_screen_land)) && !btUsed && old!=btUsed)
	  { 
	      //[self performSelectorOnMainThread:@selector(changeUI) withObject:nil waitUntilDone:YES];
	      [self changeUI];
	  }
	    
	  actionPending=0;
	  iOS_exitPause = 1;
      __emulation_paused = 0;
      iphone_menu = IPHONE_MENU_NONE; 
}

-(void)done:(id)sender {
    
    [self dismissModalViewControllerAnimated:YES];

	Options *op = [[Options alloc] init];
    FilterOptions *op2 = [[FilterOptions alloc] init];
		   
    if(iphone_smooth_port != [op smoothedPort] 
        || iphone_smooth_land != [op smoothedLand] 
        || safe_render_path != [op safeRenderPath]
        || iphone_keep_aspect_ratio_land != [op keepAspectRatioLand]
        || iphone_keep_aspect_ratio_port != [op keepAspectRatioPort]        
        || tv_filter_land != [op tvFilterLand]
        || tv_filter_port != [op tvFilterPort]
        || scanline_filter_land != [op scanlineFilterLand]
        || scanline_filter_port != [op scanlineFilterPort]      
        || global_fps != [op showFPS]
        || global_showinfo != [op showINFO]
        || iOS_animated_DPad  != [op animatedButtons]
        || iOS_4buttonsLand  != [op fourButtonsLand]
        || iOS_full_screen_land  != [op fullLand]
        || iOS_full_screen_port  != [op fullPort]
        || iOS_skin_data != ([op skin]+1)
        || iOS_wiiDeadZoneValue != [op wiiDeadZoneValue]
        || iOS_touchDeadZone != [op touchDeadZone]
        || nativeTVOUT != [op tvoutNative]
        || overscanTVOUT != [op overscanValue]
        || iOS_inputTouchType != [op inputTouchType]
        || iOS_analogDeadZoneValue != [op analogDeadZoneValue]
        || iOS_iCadeLayout != [op iCadeLayout]
        || global_manufacturer != [op2 flt_manufacturer]
        || global_category != [op2 flt_category]
        || global_filter != [op2 flt_filter]
        || global_clones != [op2 flt_clones]
        || global_year != [op2 flt_year]
        || [op buttonReload]
        )
    {
        iphone_keep_aspect_ratio_land = [op keepAspectRatioLand];
        iphone_keep_aspect_ratio_port = [op keepAspectRatioPort];
        iphone_smooth_land = [op smoothedLand];
        iphone_smooth_port = [op smoothedPort];
        safe_render_path = [op safeRenderPath];
         
        tv_filter_land = [op tvFilterLand];
        tv_filter_port = [op tvFilterPort];
        
        scanline_filter_land = [op scanlineFilterLand];
        scanline_filter_port = [op scanlineFilterPort];
        
       global_fps = [op showFPS];
       global_showinfo = [op showINFO];
       iOS_animated_DPad  = [op animatedButtons];
       iOS_4buttonsLand  = [op fourButtonsLand];
       iOS_full_screen_land  = [op fullLand];
       iOS_full_screen_port  = [op fullPort];
       
       iOS_skin = [op skin]+1;
       iOS_skin_data = iOS_skin;
       if(iOS_skin == 2 && isIpad)
          iOS_skin = 3;
        
       iOS_wiiDeadZoneValue = [op wiiDeadZoneValue];
       iOS_touchDeadZone = [op touchDeadZone];
       
       if (nativeTVOUT != [op tvoutNative])
       {
           nativeTVOUT = [op tvoutNative];
           UIAlertView *warnAlert = [[UIAlertView alloc] initWithTitle:@"Pending restart Application!" 
															  
 
           message:[NSString stringWithFormat: @"You need to restar iMAME4all for the changes to take effect"]
														 
															 delegate:self 
													cancelButtonTitle:@"Dismiss" 
													otherButtonTitles: nil];
	
	       [warnAlert show];
	       [warnAlert release];
       }
        
       if(overscanTVOUT != [op overscanValue])
       {
           overscanTVOUT = [op overscanValue];
           UIAlertView *warnAlert = [[UIAlertView alloc] initWithTitle:@"Pending unplug/plug TVOUT!" 
 
           message:[NSString stringWithFormat: @"You need to unplug/plug TVOUT for the changes to take effect"]
										delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles: nil];
	
	       [warnAlert show];
	       [warnAlert release];
       }
       
       iOS_inputTouchType = [op inputTouchType];
       iOS_analogDeadZoneValue = [op analogDeadZoneValue];
       iOS_iCadeLayout = [op iCadeLayout];
        
       global_manufacturer = [op2 flt_manufacturer];
       global_category = [op2 flt_category];
       global_filter = [op2 flt_filter];
       global_clones = [op2 flt_clones];
       global_year = [op2 flt_year];
              
       [self performSelectorOnMainThread:@selector(changeUI) withObject:nil waitUntilDone:YES];
       //[self changeUI];
              
       /*      
       [screenView removeFromSuperview];
       [screenView release];
       
       if(imageBack!=nil)
       {
          [imageBack removeFromSuperview];
          [imageBack release];
          imageBack = nil;
       }
     
       //si tiene overlay
       if(imageOverlay!=nil)
       {
         [imageOverlay removeFromSuperview];
         [imageOverlay release];
         imageOverlay = nil;
       }
 
       if(iphone_is_landscape)
         [self buildLandscape];       
       else
         [self buildPortrait];
       */    
    }
    
    global_sound = [op SoundKHZ]+1+([op SoundSTEREO]*4);
    
    if([op buttonReload]) {
        game_list_num = 0;
        op.buttonReload = FALSE;
        [op saveOptions];
        
    }
        
    [op2 release];
    [op release];
    
    [self endMenu];
    
    //[myPool release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  iOS_exitPause = 1;
  __emulation_paused = 0;
  if(iphone_menu == IPHONE_MENU_EXIT)
  {
     [self endMenu];
  }
 
  if(buttonIndex == 0 && wantExit )
  {
     iOS_exitGame = 1;
  }
  actionPending=0;
  wantExit = 0;
}

- (void)handle_MENU
{
    if(btnStates[BTN_L2] == BUTTON_PRESS && iOS_inGame && !actionPending)
    {				  				
        actionPending=1;
        iOS_exitGame = 0;
        wantExit = 1;	
        usleep(100000);	            
        __emulation_paused = 1;
        UIAlertView* exitAlertView=[[UIAlertView alloc] initWithTitle:nil
                                                                  message:@"are you sure you want to exit the game?"
                                                                 delegate:self cancelButtonTitle:nil
                                                        otherButtonTitles:@"Yes",@"No",nil];
        [exitAlertView show];
        [exitAlertView release];
    } 
    
    if(btnStates[BTN_R2] == BUTTON_PRESS && !actionPending)
    {
         [self runMenu];
    }					
}	

- (void)loadView {

	struct CGRect rect = [[UIScreen mainScreen] bounds];
	rect.origin.x = rect.origin.y = 0.0f;
	UIView *view= [[UIView alloc] initWithFrame:rect];
	self.view = view;
	[view release];
     self.view.backgroundColor = [UIColor blackColor];	
    externalView = nil;    
}

-(void)viewDidLoad{	

   nameImgButton_NotPress[BTN_B] = @"button_NotPress_B.png";
   nameImgButton_NotPress[BTN_X] = @"button_NotPress_X.png";
   nameImgButton_NotPress[BTN_A] = @"button_NotPress_A.png";
   nameImgButton_NotPress[BTN_Y] = @"button_NotPress_Y.png";
   nameImgButton_NotPress[BTN_START] = @"button_NotPress_start.png";
   nameImgButton_NotPress[BTN_SELECT] = @"button_NotPress_select.png";
   nameImgButton_NotPress[BTN_L1] = @"button_NotPress_R_L1.png";
   nameImgButton_NotPress[BTN_R1] = @"button_NotPress_R_R1.png";
   nameImgButton_NotPress[BTN_L2] = @"button_NotPress_R_L2.png";
   nameImgButton_NotPress[BTN_R2] = @"button_NotPress_R_R2.png";
   
   nameImgButton_Press[BTN_B] = @"button_Press_B.png";
   nameImgButton_Press[BTN_X] = @"button_Press_X.png";
   nameImgButton_Press[BTN_A] = @"button_Press_A.png";
   nameImgButton_Press[BTN_Y] = @"button_Press_Y.png";
   nameImgButton_Press[BTN_START] = @"button_Press_start.png";
   nameImgButton_Press[BTN_SELECT] = @"button_Press_select.png";
   nameImgButton_Press[BTN_L1] = @"button_Press_R_L1.png";
   nameImgButton_Press[BTN_R1] = @"button_Press_R_R1.png";
   nameImgButton_Press[BTN_L2] = @"button_Press_R_L2.png";
   nameImgButton_Press[BTN_R2] = @"button_Press_R_R2.png";
         
   nameImgDPad[DPAD_NONE]=@"DPad_NotPressed.png";
   nameImgDPad[DPAD_UP]= @"DPad_U.png";
   nameImgDPad[DPAD_DOWN]= @"DPad_D.png";
   nameImgDPad[DPAD_LEFT]= @"DPad_L.png";
   nameImgDPad[DPAD_RIGHT]= @"DPad_R.png";
   nameImgDPad[DPAD_UP_LEFT]= @"DPad_UL.png";
   nameImgDPad[DPAD_UP_RIGHT]= @"DPad_UR.png";
   nameImgDPad[DPAD_DOWN_LEFT]= @"DPad_DL.png";
   nameImgDPad[DPAD_DOWN_RIGHT]= @"DPad_DR.png";
      
   dpadView=nil;
   analogStickView = nil;
      
   int i;
   for(i=0; i<NUM_BUTTONS;i++)
      buttonViews[i]=nil;
      
   screenView=nil;
   imageBack=nil;   			
   dview = nil;
   
   menu = nil;

   
   [ self getConf];

	//[self.view addSubview:self.imageBack];
 	
	//[ self getControllerCoords:0 ];
	
	//self.navigationItem.hidesBackButton = YES;
	
	
    self.view.opaque = YES;
	self.view.clearsContextBeforeDrawing = NO; //Performance?
	
	self.view.userInteractionEnabled = YES;
	
	self.view.multipleTouchEnabled = YES;
	self.view.exclusiveTouch = NO;
	
    //self.view.multipleTouchEnabled = NO; investigar porque se queda
	//self.view.contentMode = UIViewContentModeTopLeft;
	
	//[[self.view layer] setMagnificationFilter:kCAFilterNearest];
	//[[self.view layer] setMinificationFilter:kCAFilterNearest];

	//kito
	[NSThread setThreadPriority:1.0];
	
	iphone_menu = IPHONE_MENU_NONE;
		
	//self.view.frame = [[UIScreen mainScreen] bounds];//rMainViewFrame;
		
	Options *op = [[Options alloc] init];
	        
    iphone_keep_aspect_ratio_land = [op keepAspectRatioLand];
    iphone_keep_aspect_ratio_port = [op keepAspectRatioPort];
    iphone_smooth_land = [op smoothedLand];
    iphone_smooth_port = [op smoothedPort];
    safe_render_path = [op safeRenderPath];
                    
    tv_filter_land = [op tvFilterLand];
    tv_filter_port = [op tvFilterPort];
        
    scanline_filter_land = [op scanlineFilterLand];
    scanline_filter_port = [op scanlineFilterPort];
    
    global_fps = [op showFPS];
    global_showinfo = [op showINFO];
    global_sound = [op SoundKHZ]+1+([op SoundSTEREO]*4); 
    iOS_animated_DPad  = [op animatedButtons];
    iOS_4buttonsLand  = [op fourButtonsLand];
    iOS_full_screen_land  = [op fullLand];
    iOS_full_screen_port  = [op fullPort];
    
    iOS_skin = [op skin]+1;
    iOS_skin_data = iOS_skin;
    if(iOS_skin == 2 && isIpad)
        iOS_skin = 3;
          
    iOS_wiiDeadZoneValue = [op wiiDeadZoneValue];
    iOS_touchDeadZone = [op touchDeadZone];
    
    nativeTVOUT = [op tvoutNative];
    overscanTVOUT = [op overscanValue];
    
    iOS_inputTouchType = [op inputTouchType];
    iOS_analogDeadZoneValue = [op analogDeadZoneValue];
    iOS_iCadeLayout = [op iCadeLayout];
            
    [op release];
     
    FilterOptions *op2 = [[FilterOptions alloc] init];
    global_manufacturer = [op2 flt_manufacturer];
    global_category = [op2 flt_category];
    global_filter = [op2 flt_filter];
    global_clones = [op2 flt_clones];
    global_year = [op2 flt_year];
    [op2 release];
    
    //
    // we want to get keyboard input *only* from an external keyboard (no SW keyboards) the iCade is a bluetooth keyboard
    //
    // here is the plan, if a SW keyboard pops up resign.
    //
    // if a keyboard shows up later and someone starts using it, then try to grab FR status again
    //
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resignFirstResponder) name:@"UIKeyboardDidShowNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becomeFirstResponder) name:@"UIKeyboardEmptyDelegateNotification" object:nil];

    [self changeUI];
    
    if(0)
    {
		   UIAlertView *loadAlert = [[UIAlertView alloc] initWithTitle:nil 
	   																										
		           message:[NSString stringWithFormat: @"\n\n\nLoading.\nPlease Wait..."]
															 
																 delegate: nil 
														cancelButtonTitle: nil 
														otherButtonTitles: nil];
			   			      
		   [loadAlert show];
	       [loadAlert release];
	 }      
}
- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIKeyboardDidShowNotification" object:nil]; 
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIKeyboardEmptyDelegateNotification" object:nil]; 
 
    [super viewDidUnload];
}

-(void)autoDimiss:(id)sender {

     UIAlertView *alert = (UIAlertView *)sender;
     [alert dismissWithClickedButtonIndex:0 animated:YES];
     [alert release];

}


-(BOOL)becomeFirstResponder {
    static int first = 1;
    //NSLog(@"becomeFirstResponder");
    if(warnIcade){
       
          	if(!iCadeUsed)
          	{
	          	UIAlertView *warnAlert; 
	          	
	          	if(first)
	          	{
		          	first=0;
		          	warnAlert = [[UIAlertView alloc] initWithTitle:@"Connection!" 
																	  
		 
		            message:[NSString stringWithFormat: @"Have I detected an iCade? Due to the limitations of the HW not all games are suited, use WiiClassic Pro instead if you get slowdowns or control lag. Remember, that you can select portrait fullscreen mode in options!. GERMAN users, set the soft keyboard to 'english (us)' before using the iCade"]
																 
																	 delegate:self 
															cancelButtonTitle:@"Dismiss" 
															otherButtonTitles: nil];																
			       [warnAlert show];
			       [warnAlert release];
		       }
		       else
		       {
		           
		           warnAlert = [[UIAlertView alloc] initWithTitle:nil 
	   																										
		           message:[NSString stringWithFormat: @"\n\n\niCade connection?.\nPlease Wait..."]
															 
																 delegate: nil 
														cancelButtonTitle: nil 
														otherButtonTitles: nil];
			   
			      [self performSelector:@selector(autoDimiss:) withObject:warnAlert afterDelay:2.5f];
		          [warnAlert show];
		       }
	       }
	       iCadeUsed = 1;
	       [self changeUI];
	       
    }
    return [super becomeFirstResponder];
}

-(BOOL)resignFirstResponder {
   //NSLog(@"resignFirstResponder");
   if(warnIcade)
   {           	
           	if(iCadeUsed)
           	{
	           	UIAlertView *warnAlert = [[UIAlertView alloc] initWithTitle:nil 
	   																										
		        message:[NSString stringWithFormat: @"\n\n\niCade disconnection?.\nPlease Wait..."]
															 
																 delegate: nil 
														cancelButtonTitle: nil 
														otherButtonTitles: nil];
			   
			   [self performSelector:@selector(autoDimiss:) withObject:warnAlert afterDelay:2.5f];
		       [warnAlert show];
	       }
	       iCadeUsed = 0;
	       [self changeUI];	       
   }
   return [super resignFirstResponder];
}



- (void)drawRect:(CGRect)rect
{
            
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	//return (interfaceOrientation ==  UIDeviceOrientationLandscapeLeft || interfaceOrientation ==  UIDeviceOrientationLandscapeRight);
	//return NO;
	return YES;
	//return actionPending ? NO : YES;
}


-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
   
    //show_controls = 1;   
 
    [self changeUI];
    if(menu!=nil)
    {         
         [self runMenu];
    }        
}

- (void)changeUI{
   NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
  int prev_emulation_paused = __emulation_paused;
   
  __emulation_paused = 1;
  
  [self getConf];
  
  //reset_video(); 
  
  //if(!safe_render_path)
      usleep(150000);//ensure some frames displayed
  
  //[self removeDPadView];
        
  [screenView removeFromSuperview];
  [screenView release];

  if(imageBack!=nil)
  {
     [imageBack removeFromSuperview];
     [imageBack release];
     imageBack = nil;
  }
   
  //si tiene overlay
   if(imageOverlay!=nil)
   {
     [imageOverlay removeFromSuperview];
     [imageOverlay release];
     imageOverlay = nil;
   }
   
   if((self.interfaceOrientation ==  UIDeviceOrientationLandscapeLeft) || (self.interfaceOrientation == UIDeviceOrientationLandscapeRight)){
	   [self buildLandscape];	        	
   } else	if((self.interfaceOrientation == UIDeviceOrientationPortrait) || (self.interfaceOrientation == UIDeviceOrientationPortraitUpsideDown)){	
       [self buildPortrait];
   }

   //self.view.backgroundColor = [UIColor blackColor];
   [self.view setNeedsDisplay];
   	
   iOS_exitPause = 1;
	
   if(prev_emulation_paused!=1)
	   __emulation_paused = 0;
		
   [pool release];
}

- (void)removeDPadView{
   
   int i;
   
   if(dpadView!=nil)
   {
      [dpadView removeFromSuperview];
      [dpadView release];
      dpadView=nil;
   }
   
   if(analogStickView!=nil)
   {
      [analogStickView removeFromSuperview];
      [analogStickView release];
      analogStickView=nil;   
   }
   
   for(i=0; i<NUM_BUTTONS;i++)
   {
      if(buttonViews[i]!=nil)
      {
         [buttonViews[i] removeFromSuperview];
         [buttonViews[i] release];     
         buttonViews[i] = nil; 
      }
   }
      
}

- (void)buildDPadView {

   int i;
   
   
   [self removeDPadView];
    
   btUsed = num_of_joys!=0; 
   
   if((btUsed || iCadeUsed) && ((!iphone_is_landscape && iOS_full_screen_port) || (iphone_is_landscape && iOS_full_screen_land)))
     return;
   
   NSString *name;    
   
   if(iOS_inputTouchType == TOUCH_INPUT_DIGITAL)
   {
	   name = [NSString stringWithFormat:@"./SKIN_%d/%@",iOS_skin,nameImgDPad[DPAD_NONE]];
	   dpadView = [ [ UIImageView alloc ] initWithImage:[UIImage imageNamed:name]];
	   dpadView.frame = rDPad_image;
	   if( (!iphone_is_landscape && iOS_full_screen_port) || (iphone_is_landscape && iOS_full_screen_land))
	         [dpadView setAlpha:((float)iphone_controller_opacity / 100.0f)];  
	   [self.view addSubview: dpadView];
	   dpad_state = old_dpad_state = DPAD_NONE;
   }
   else
   {   
       //analogStickView
	   analogStickView = [[AnalogStickView alloc] initWithFrame:rStickWindow];	  
	   [self.view addSubview:analogStickView];  
	   [analogStickView setNeedsDisplay];
   }
   
   for(i=0; i<NUM_BUTTONS;i++)
   {

      if(iphone_is_landscape || (!iphone_is_landscape && iOS_full_screen_port))
      {
          if(i==BTN_Y && iOS_landscape_buttons < 4)continue;
          if(i==BTN_A && iOS_landscape_buttons < 3)continue;
          if(i==BTN_X && iOS_landscape_buttons < 2)continue;
          if(i==BTN_B && iOS_landscape_buttons < 1)continue;  
                            
          if(i==BTN_L1 && iOS_hide_LR)continue;
          if(i==BTN_R1 && iOS_hide_LR)continue;
      }
   
      //if((i==BTN_Y || i==BTN_A) && !iOS_4buttonsLand && iphone_is_landscape)
         //continue;
      name = [NSString stringWithFormat:@"./SKIN_%d/%@",iOS_skin,nameImgButton_NotPress[i]];   
      buttonViews[i] = [ [ UIImageView alloc ] initWithImage:[UIImage imageNamed:name]];
      buttonViews[i].frame = rButton_image[i];
      if((iphone_is_landscape && (iOS_full_screen_land /*|| i==BTN_Y || i==BTN_A*/)) || (!iphone_is_landscape && iOS_full_screen_port))      
         [buttonViews[i] setAlpha:((float)iphone_controller_opacity / 100.0f)];   
      [self.view addSubview: buttonViews[i]];
      btnStates[i] = old_btnStates[i] = BUTTON_NO_PRESS; 
   }
       
}

- (void)buildPortraitImageBack {
  /*
   [UIView beginAnimations:@"foo2" context:nil];
   [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
   [UIView setAnimationDuration:0.50];
   */
   if(!iOS_full_screen_port)
   {
	   if(isIpad)
	     imageBack = [ [ UIImageView alloc ] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"./SKIN_%d/back_portrait_iPad.png",iOS_skin]]];
	   else
	     imageBack = [ [ UIImageView alloc ] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"./SKIN_%d/back_portrait_iPhone.png",iOS_skin]]];
	   
	   imageBack.frame = rPortraitImageBackFrame; // Set the frame in which the UIImage should be drawn in.
	   
	   imageBack.userInteractionEnabled = NO;
	   imageBack.multipleTouchEnabled = NO;
	   imageBack.clearsContextBeforeDrawing = NO;
	   //[imageBack setOpaque:YES];
	
	   [self.view addSubview: imageBack]; // Draw the image in self.view.
   }
   //[UIView commitAnimations];
   
}

- (void)buildPortraitImageOverlay {
   
   if((safe_render_path || scanline_filter_port || tv_filter_port) && externalView==nil)
   {
                                                                                                                                                       
       CGRect r = iOS_full_screen_port ? rView : rPortraitImageOverlayFrame;
       
       UIGraphicsBeginImageContext(r.size);  
       
       //[image1 drawInRect: rPortraitImageOverlayFrame];
       
       CGContextRef uiContext = UIGraphicsGetCurrentContext();
             
       CGContextTranslateCTM(uiContext, 0, r.size.height);
	
       CGContextScaleCTM(uiContext, 1.0, -1.0);

       if(scanline_filter_port)
       {       
            
          UIImage *image2 = [UIImage imageNamed:[NSString stringWithFormat: @"scanline-1.png"]];
                        
          CGImageRef tile = CGImageRetain(image2.CGImage);
                   
          CGContextSetAlpha(uiContext,((float)22 / 100.0f));   
              
          CGContextDrawTiledImage(uiContext, CGRectMake(0, 0, image2.size.width, image2.size.height), tile);
       
          CGImageRelease(tile);       
       }

       if(tv_filter_port)
       {              
          
          UIImage *image3 = [UIImage imageNamed:[NSString stringWithFormat: @"crt-1.png"]];              
          
          CGImageRef tile = CGImageRetain(image3.CGImage);
              
          CGContextSetAlpha(uiContext,((float)19 / 100.0f));     
          
          CGContextDrawTiledImage(uiContext, CGRectMake(0, 0, image3.size.width, image3.size.height), tile);
       
          CGImageRelease(tile);       
       }
     
       if(isIpad /*&& externalView==nil*/ && (!iOS_full_screen_port /*|| 1*/))
       {
          UIImage *image1;
          if(isIpad)          
            image1 = [UIImage imageNamed:[NSString stringWithFormat:@"border-iPad.png"]];
          else
            image1 = [UIImage imageNamed:[NSString stringWithFormat:@"border-iPhone.png"]];
         
          CGImageRef img = CGImageRetain(image1.CGImage);
       
          CGContextSetAlpha(uiContext,((float)100 / 100.0f));  
   
          CGContextDrawImage(uiContext,rPortraitImageOverlayFrame , img);
   
          CGImageRelease(img);  
       }
             
       UIImage *finishedImage = UIGraphicsGetImageFromCurrentImageContext();
                                                            
       UIGraphicsEndImageContext();
       
       imageOverlay = [ [ UIImageView alloc ] initWithImage: finishedImage];
         
       imageOverlay.frame = r;
       
       //if(externalView==nil)
       //{             		    			
           [self.view addSubview: imageOverlay];
       //}  
       //else
       //{   
           //screenView.frame = rExternal;
       //    [externalView addSubview: imageOverlay];
       //} 
                                    
   }  

  //DPAD---   
  [self buildDPadView];   
  /////
   
  /////////////////
  if(enable_dview)
  {
	  if(dview!=nil)
	  {
	    [dview removeFromSuperview];
	    [dview release];
	  }  	 
	
	  dview = [[DView alloc] initWithFrame:self.view.bounds];
	  
	  [self.view addSubview:dview];   
	
	  [self filldrectsController];
	  
	  [dview setNeedsDisplay];
  }
  ////////////////
}

- (void)buildPortrait {

   iphone_is_landscape = 0;
   [ self getControllerCoords:0 ];
   
   [self buildPortraitImageBack];
   
   CGRect r;
   
   if(externalView!=nil)   
   {
        r = rExternal;
   }
   else if(!iOS_full_screen_port)
   {
	    r = rPortraitViewFrameNotFull;	
   }		  
   else
   {
        r = rPortraitViewFrame;
   }
   
    if(iphone_keep_aspect_ratio_port)
    {

       int tmp_height = r.size.height;// > emulated_width ?
       int tmp_width = ((((tmp_height * emulated_width) / emulated_height)+7)&~7);
       		       
       if(tmp_width > r.size.width) //y no crop
       {
          tmp_width = r.size.width;
          tmp_height = ((((tmp_width * emulated_height) / emulated_width)+7)&~7);
       }   
       
       r.origin.x = r.origin.x + ((r.size.width - tmp_width) / 2);      
       
       if(!iOS_full_screen_port || btUsed || iCadeUsed)
       {
          r.origin.y = r.origin.y + ((r.size.height - tmp_height) / 2);
       }
       else
       {
          int tmp = r.size.height - (r.size.height/5);
          if(tmp_height < tmp)                                
             r.origin.y = r.origin.y + ((tmp - tmp_height) / 2);
       }
       
       if(tmp_width==320 && !safe_render_path)
       {
          tmp_width = 319;
       }
       
       r.size.width = tmp_width;
       r.size.height = tmp_height;
   
   }  
   
   rView = r;
       
   screenView = [ [ScreenView alloc] initWithFrame: rView];
                  
   if(externalView==nil)
   {             		    			
      [self.view addSubview: screenView];
   }  
   else
   {   
      [externalView addSubview: screenView];
   }  
      
   [self buildPortraitImageOverlay];
     
}

- (void)buildLandscapeImageBack {
  /*
   [UIView beginAnimations:@"foo2" context:nil];
   [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
   [UIView setAnimationDuration:0.50];
   */

   if(!iOS_full_screen_land)
   {
	   if(isIpad)
	     imageBack = [ [ UIImageView alloc ] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"./SKIN_%d/back_landscape_iPad.png",iOS_skin]]];
	   else
	     imageBack = [ [ UIImageView alloc ] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"./SKIN_%d/back_landscape_iPhone.png",iOS_skin]]];
	   
	   imageBack.frame = rLandscapeImageBackFrame; // Set the frame in which the UIImage should be drawn in.
	   
	   imageBack.userInteractionEnabled = NO;
	   imageBack.multipleTouchEnabled = NO;
	   imageBack.clearsContextBeforeDrawing = NO;
	   //[imageBack setOpaque:YES];
	
	   [self.view addSubview: imageBack]; // Draw the image in self.view.
   }
   //[UIView commitAnimations];
   
}

- (void)buildLandscapeImageOverlay{
/*
   [UIView beginAnimations:@"foo2" context:nil];
   [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
   [UIView setAnimationDuration:0.50];
*/
    
   if((scanline_filter_land || tv_filter_land) &&  externalView==nil)
   {                                                                                                                                              
	   CGRect r;
       /*
       if(!iphone_keep_aspect_ratio && !isIpad && iOS_full_screen_land)
		  r = rLandscapeViewFrameFull;	  
       else 
       */
       if(iOS_full_screen_land)
          r = rView;//rLandscapeViewFrame;
       else
          r = rLandscapeImageOverlayFrame;
	
	   UIGraphicsBeginImageContext(r.size);
	
	   CGContextRef uiContext = UIGraphicsGetCurrentContext();  
	   
	   CGContextTranslateCTM(uiContext, 0, r.size.height);
		
	   CGContextScaleCTM(uiContext, 1.0, -1.0);
	   
	   if(scanline_filter_land)
	   {       	       
	      UIImage *image2;
	      
	      if(isIpad)
	        image2 =  [UIImage imageNamed:[NSString stringWithFormat: @"scanline-2.png"]];
	      else
	        image2 =  [UIImage imageNamed:[NSString stringWithFormat: @"scanline-1.png"]];
	                        
	      CGImageRef tile = CGImageRetain(image2.CGImage);
	      
	      if(isIpad)             
	         CGContextSetAlpha(uiContext,((float)10 / 100.0f));
	      else
	         CGContextSetAlpha(uiContext,((float)22 / 100.0f));
	              
	      CGContextDrawTiledImage(uiContext, CGRectMake(0, 0, image2.size.width, image2.size.height), tile);
	       
	      CGImageRelease(tile);       
	    }
	
	    if(tv_filter_land)
	    {              
	       UIImage *image3 = [UIImage imageNamed:[NSString stringWithFormat: @"crt-1.png"]];              
	          
	       CGImageRef tile = CGImageRetain(image3.CGImage);
	              
	       CGContextSetAlpha(uiContext,((float)20 / 100.0f));     
	          
	       CGContextDrawTiledImage(uiContext, CGRectMake(0, 0, image3.size.width, image3.size.height), tile);
	       
	       CGImageRelease(tile);       
	    }

	       
	    UIImage *finishedImage = UIGraphicsGetImageFromCurrentImageContext();
	                  
	    UIGraphicsEndImageContext();
	    
	    imageOverlay = [ [ UIImageView alloc ] initWithImage: finishedImage];
	    
	    imageOverlay.frame = r; // Set the frame in which the UIImage should be drawn in.
      
        imageOverlay.userInteractionEnabled = NO;
        imageOverlay.multipleTouchEnabled = NO;
        imageOverlay.clearsContextBeforeDrawing = NO;
   
        //[imageBack setOpaque:YES];
         
         //if(externalView==nil)
		 //{             		    			
		      [self.view addSubview: imageOverlay];
		 //}  
		 //else
		 //{   
		 //     [externalView addSubview: imageOverlay];
		 //}  
         //[UIView commitAnimations];	    
    }
   
    //DPAD---   
    [self buildDPadView];   
    /////
  
   //////////////////
   if(enable_dview)
   {
	  if(dview!=nil)
	  {
        [dview removeFromSuperview];
        [dview release];
      }	 	  
	  
	  dview = [[DView alloc] initWithFrame:self.view.bounds];
		 	  
	  [self filldrectsController];
	  
	  [self.view addSubview:dview];   
	  [dview setNeedsDisplay];
	  
	 
  }
  /////////////////	
}

- (void)buildLandscape{
	
   iphone_is_landscape = 1;
      
   [self getControllerCoords:1 ];
   
   [self buildLandscapeImageBack];
        
   CGRect r;
   
   if(externalView!=nil)
   {
        r = rExternal;
   }
   else if(!iOS_full_screen_land)
   {
        r = rLandscapeViewFrameNotFull;
   }     
   else
   {
        r = rLandscapeViewFrameFull;
   }     
   
   if(iphone_keep_aspect_ratio_land)
   {
       //printf("%d %d\n",emulated_width,emulated_height);

       int tmp_width = r.size.width;// > emulated_width ?
       int tmp_height = ((((tmp_width * emulated_height) / emulated_width)+7)&~7);
       
       //printf("%d %d\n",tmp_width,tmp_height);
       
       if(tmp_height > r.size.height) //y no crop
       {
          tmp_height = r.size.height;
          tmp_width = ((((tmp_height * emulated_width) / emulated_height)+7)&~7);
       }   
       
       //printf("%d %d\n",tmp_width,tmp_height);
                
       r.origin.x = r.origin.x +(((int)r.size.width - tmp_width) / 2);             
       r.origin.y = r.origin.y +(((int)r.size.height - tmp_height) / 2);
       r.size.width = tmp_width;
       r.size.height = tmp_height;
   }
   
   rView = r;
   
   screenView = [ [ScreenView alloc] initWithFrame: rView];
          
   if(externalView==nil)
   {             		    			      
      [self.view addSubview: screenView];
   }  
   else
   {               
      [externalView addSubview: screenView];
   }   
           
   [self buildLandscapeImageOverlay];
	
}

////////////////


- (void)handle_DPAD{

    if(!iOS_animated_DPad /*|| !show_controls*/)return;

    if(dpad_state!=old_dpad_state)
    {
        
       //printf("cambia depad %d %d\n",old_dpad_state,dpad_state);
       NSString *imgName; 
       imgName = nameImgDPad[dpad_state];
       if(imgName!=nil)
       {  
         NSString *name = [NSString stringWithFormat:@"./SKIN_%d/%@",iOS_skin,imgName];   
         //printf("%s\n",[name UTF8String]);
         UIImage *img = [UIImage imageNamed:name]; 
         [dpadView setImage:img];
         [dpadView setNeedsDisplay];
       }           
       old_dpad_state = dpad_state;
    }
    
    int i = 0;
    for(i=0; i< NUM_BUTTONS;i++)
    {
        if(btnStates[i] != old_btnStates[i])
        {
           NSString *imgName;
           if(btnStates[i] == BUTTON_PRESS)
           {
               imgName = nameImgButton_Press[i];
           }
           else
           {
               imgName = nameImgButton_NotPress[i];
           } 
           if(imgName!=nil)
           {  
              NSString *name = [NSString stringWithFormat:@"./SKIN_%d/%@",iOS_skin,imgName];
              UIImage *img = [UIImage imageNamed:name]; 
              [buttonViews[i] setImage:img];
              [buttonViews[i] setNeedsDisplay];              
           }
           old_btnStates[i] = btnStates[i]; 
        }
    }
    
}

////////////////

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{	       
   
    if(((btUsed || iCadeUsed) && ((!iphone_is_landscape && iOS_full_screen_port) || (iphone_is_landscape && iOS_full_screen_land)))) 
    {
        NSSet *allTouches = [event allTouches];
        UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
        
        if(touch.phase == UITouchPhaseBegan)
		{
			[self runMenu];		
	    }
    }
    else
    {
        [self touchesController:touches withEvent:event];
    }  
}
  
		
- (void)touchesController:(NSSet *)touches withEvent:(UIEvent *)event {	
    
	int i;
	static UITouch *stickTouch = nil;
	//Get all the touches.
	NSSet *allTouches = [event allTouches];
	int touchcount = [allTouches count];
		
	//gp2x_pad_status = 0;
	gp2x_pad_status &= ~GP2X_X;
	gp2x_pad_status &= ~GP2X_Y;
	gp2x_pad_status &= ~GP2X_A;
	gp2x_pad_status &= ~GP2X_B;
	gp2x_pad_status &= ~GP2X_SELECT;
	gp2x_pad_status &= ~GP2X_START;
	gp2x_pad_status &= ~GP2X_L;
	gp2x_pad_status &= ~GP2X_R;
		
	for(i=0; i<NUM_BUTTONS;i++)
    {
       btnStates[i] = BUTTON_NO_PRESS; 
    }
						
	for (i = 0; i < touchcount; i++) 
	{
		UITouch *touch = [[allTouches allObjects] objectAtIndex:i];
		
		if(touch == nil)
		{
			return;
		}
		
		if( touch.phase == UITouchPhaseBegan		||
			touch.phase == UITouchPhaseMoved		||
			touch.phase == UITouchPhaseStationary	)
		{
			struct CGPoint point;
			point = [touch locationInView:self.view];
			
			if(!iOS_inputTouchType)
			{
				if (MyCGRectContainsPoint(Up, point) && !STICK2WAY) {
					//NSLog(@"GP2X_UP");
					gp2x_pad_status |= GP2X_UP;
					dpad_state = DPAD_UP;
												    
				    gp2x_pad_status &= ~GP2X_DOWN;
				    gp2x_pad_status &= ~GP2X_LEFT;
				    gp2x_pad_status &= ~GP2X_RIGHT;		
				    
				    stickTouch = touch;		    				
				}			
				else if (MyCGRectContainsPoint(Down, point) && !STICK2WAY) {
					//NSLog(@"GP2X_DOWN");
					gp2x_pad_status |= GP2X_DOWN;								
					dpad_state = DPAD_DOWN;
					
				    gp2x_pad_status &= ~GP2X_UP;
				    gp2x_pad_status &= ~GP2X_LEFT;
				    gp2x_pad_status &= ~GP2X_RIGHT;				    
				    
				    stickTouch = touch;
				}			
				else if (MyCGRectContainsPoint(Left, point)) {
					//NSLog(@"GP2X_LEFT");
					gp2x_pad_status |= GP2X_LEFT;
					dpad_state = DPAD_LEFT;
					
				    gp2x_pad_status &= ~GP2X_UP;			    
				    gp2x_pad_status &= ~GP2X_DOWN;
				    gp2x_pad_status &= ~GP2X_RIGHT;				    
				    
				    stickTouch = touch;
				}			
				else if (MyCGRectContainsPoint(Right, point)) {
					//NSLog(@"GP2X_RIGHT");
					gp2x_pad_status |= GP2X_RIGHT;
					dpad_state = DPAD_RIGHT;
					
					gp2x_pad_status &= ~GP2X_UP;			    
				    gp2x_pad_status &= ~GP2X_DOWN;
				    gp2x_pad_status &= ~GP2X_LEFT;
				    
				    stickTouch = touch;
				}			
				else if (MyCGRectContainsPoint(UpLeft, point)) {
					//NSLog(@"GP2X_UP | GP2X_LEFT");
					if(!STICK2WAY && !STICK4WAY)
					{
						gp2x_pad_status |= GP2X_UP | GP2X_LEFT;
						dpad_state = DPAD_UP_LEFT;
								    
					    gp2x_pad_status &= ~GP2X_DOWN;
					    gp2x_pad_status &= ~GP2X_RIGHT;
				    }
				    else
				    {
						gp2x_pad_status |= GP2X_LEFT;
						dpad_state = DPAD_LEFT;
								    
					    gp2x_pad_status &= ~GP2X_UP;
					    gp2x_pad_status &= ~GP2X_DOWN;
					    gp2x_pad_status &= ~GP2X_RIGHT;				    
				    }				    
				    stickTouch = touch;				
				}			
				else if (MyCGRectContainsPoint(UpRight, point)) {
					//NSLog(@"GP2X_UP | GP2X_RIGHT");
					
					if(!STICK2WAY && !STICK4WAY)
					{
					   gp2x_pad_status |= GP2X_UP | GP2X_RIGHT;
					   dpad_state = DPAD_UP_RIGHT;
								    
				       gp2x_pad_status &= ~GP2X_DOWN;
				       gp2x_pad_status &= ~GP2X_LEFT;
				    }
				    else
				    {
					   gp2x_pad_status |= GP2X_RIGHT;
					   dpad_state = DPAD_RIGHT;
								    
				       gp2x_pad_status &= ~GP2X_UP;
				       gp2x_pad_status &= ~GP2X_DOWN;
				       gp2x_pad_status &= ~GP2X_LEFT;				    
				    }   				    
				    stickTouch = touch;
				}			
				else if (MyCGRectContainsPoint(DownLeft, point)) {
					//NSLog(@"GP2X_DOWN | GP2X_LEFT");

					if(!STICK2WAY && !STICK4WAY)
					{
						gp2x_pad_status |= GP2X_DOWN | GP2X_LEFT;
						dpad_state = DPAD_DOWN_LEFT;
						
		                gp2x_pad_status &= ~GP2X_UP;			    
					    gp2x_pad_status &= ~GP2X_RIGHT;
				    }
				    else
				    {
						gp2x_pad_status |= GP2X_LEFT;
						dpad_state = DPAD_LEFT;
						
		                gp2x_pad_status &= ~GP2X_DOWN;
		                gp2x_pad_status &= ~GP2X_UP;			    
					    gp2x_pad_status &= ~GP2X_RIGHT;				    
				    }
				    stickTouch = touch;				
				}			
				else if (MyCGRectContainsPoint(DownRight, point)) {
					//NSLog(@"GP2X_DOWN | GP2X_RIGHT");
					if(!STICK2WAY && !STICK4WAY)
					{
					    gp2x_pad_status |= GP2X_DOWN | GP2X_RIGHT;
					    dpad_state = DPAD_DOWN_RIGHT;
					
	                    gp2x_pad_status &= ~GP2X_UP;			    
				        gp2x_pad_status &= ~GP2X_LEFT;
				    }
				    else
				    {    
					    gp2x_pad_status |= GP2X_RIGHT;
					    dpad_state = DPAD_RIGHT;
					
                        gp2x_pad_status &= ~GP2X_DOWN;	                    
	                    gp2x_pad_status &= ~GP2X_UP;			    
				        gp2x_pad_status &= ~GP2X_LEFT;				    
				    }
				    stickTouch = touch;
				}			
			}
			
			if(touch == stickTouch) continue;
			
			if (MyCGRectContainsPoint(ButtonUp, point)) {
				gp2x_pad_status |= GP2X_Y;
				btnStates[BTN_Y] = BUTTON_PRESS; 
				//NSLog(@"GP2X_Y");
			}
			else if (MyCGRectContainsPoint(ButtonDown, point)) {
				gp2x_pad_status |= GP2X_X;
				btnStates[BTN_X] = BUTTON_PRESS;
				//NSLog(@"GP2X_X");
			}
			else if (MyCGRectContainsPoint(ButtonLeft, point)) {
			    if(iOS_BplusX)
			    {
					gp2x_pad_status |= GP2X_X | GP2X_B;
	                btnStates[BTN_B] = BUTTON_PRESS;
	                btnStates[BTN_X] = BUTTON_PRESS;
	                btnStates[BTN_A] = BUTTON_PRESS;
                }
                else
                {
					gp2x_pad_status |= GP2X_A;
					btnStates[BTN_A] = BUTTON_PRESS;
				}
				//NSLog(@"GP2X_A");
			}
			else if (MyCGRectContainsPoint(ButtonRight, point)) {
				gp2x_pad_status |= GP2X_B;
				btnStates[BTN_B] = BUTTON_PRESS;
				//NSLog(@"GP2X_B");
			}
			else if (MyCGRectContainsPoint(ButtonUpLeft, point)) {
				gp2x_pad_status |= GP2X_Y | GP2X_A;
				btnStates[BTN_Y] = BUTTON_PRESS;
				btnStates[BTN_A] = BUTTON_PRESS;
				//NSLog(@"GP2X_Y | GP2X_A");
			}
			else if (MyCGRectContainsPoint(ButtonDownLeft, point)) {

				gp2x_pad_status |= GP2X_X | GP2X_A;
                btnStates[BTN_A] = BUTTON_PRESS;
                btnStates[BTN_X] = BUTTON_PRESS;							
				//NSLog(@"GP2X_X | GP2X_A");
			}
			else if (MyCGRectContainsPoint(ButtonUpRight, point)) {
				gp2x_pad_status |= GP2X_Y | GP2X_B;
                btnStates[BTN_B] = BUTTON_PRESS;
                btnStates[BTN_Y] = BUTTON_PRESS;				
				//NSLog(@"GP2X_Y | GP2X_B");
			}			
			else if (MyCGRectContainsPoint(ButtonDownRight, point)) {
			    if(!iOS_BplusX && iOS_landscape_buttons>=3)
			    {
					gp2x_pad_status |= GP2X_X | GP2X_B;
	                btnStates[BTN_B] = BUTTON_PRESS;
	                btnStates[BTN_X] = BUTTON_PRESS;
                }
				//NSLog(@"GP2X_X | GP2X_B");
			} 
			else if (MyCGRectContainsPoint(Select, point)) {
			    //NSLog(@"GP2X_SELECT");
				gp2x_pad_status |= GP2X_SELECT;				
                btnStates[BTN_SELECT] = BUTTON_PRESS;
			}
			else if (MyCGRectContainsPoint(Start, point)) {
				//NSLog(@"GP2X_START");
				gp2x_pad_status |= GP2X_START;
			    btnStates[BTN_START] = BUTTON_PRESS;
			}						
			else if (MyCGRectContainsPoint(LPad, point)) {
				//NSLog(@"GP2X_L");
				gp2x_pad_status |= GP2X_L;
			    btnStates[BTN_L1] = BUTTON_PRESS;
			}
			else if (MyCGRectContainsPoint(RPad, point)) {
				//NSLog(@"GP2X_R");
				gp2x_pad_status |= GP2X_R;
				btnStates[BTN_R1] = BUTTON_PRESS;
			}			
			else if (MyCGRectContainsPoint(LPad2, point)) {
				//NSLog(@"GP2X_VOL_DOWN");
				//gp2x_pad_status |= GP2X_VOL_DOWN;
				btnStates[BTN_L2] = BUTTON_PRESS;
			}
			else if (MyCGRectContainsPoint(RPad2, point)) {
				//NSLog(@"GP2X_VOL_UP");
				//gp2x_pad_status |= GP2X_VOL_UP;
				btnStates[BTN_R2] = BUTTON_PRESS;
			}			
			else if (MyCGRectContainsPoint(Menu, point)) {
				gp2x_pad_status |= GP2X_SELECT;				
                btnStates[BTN_SELECT] = BUTTON_PRESS;
				gp2x_pad_status |= GP2X_START;
			    btnStates[BTN_START] = BUTTON_PRESS;
			}			
	        			
		}
	    else
	    {
	        if(!iOS_inputTouchType && touch == stickTouch)
			{
	             gp2x_pad_status &= ~GP2X_UP;
			     gp2x_pad_status &= ~GP2X_DOWN;
				 gp2x_pad_status &= ~GP2X_LEFT;
				 gp2x_pad_status &= ~GP2X_RIGHT;
				 dpad_state = DPAD_NONE;
				 stickTouch = nil;
		    }
	    }
	}
	
	[self handle_MENU];
	[self handle_DPAD];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchesBegan:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchesBegan:touches withEvent:event];
}

//
// Keyboard input from iCade
//
- (BOOL)canBecomeFirstResponder 
{ 
    return YES; 
}

- (void)insertText:(NSString *)theText 
{
    //NSLog(@"%s: %@ %d", __FUNCTION__, theText, [theText characterAtIndex:0]);
    static int up = 0;
    static int down = 0;
    static int left = 0;
    static int right = 0;    
    warnIcade = 1;
    
    unichar key = [theText characterAtIndex:0];
    
    switch (key)
    {
        // joystick up
        case 'w':
            //if(!STICK2WAY && !(STICK4WAY && (left || right)))              
            if(STICK4WAY)
            {
               gp2x_pad_status &= ~GP2X_LEFT;
               gp2x_pad_status &= ~GP2X_RIGHT;
            }            
            if(!STICK2WAY)
              gp2x_pad_status |= GP2X_UP;
            up = 1;     
            break;
        case 'e':
            if(STICK4WAY)
            {
               if(left)gp2x_pad_status |= GP2X_LEFT;
               if(right)gp2x_pad_status |= GP2X_RIGHT;
            }            
            gp2x_pad_status &= ~GP2X_UP;
            up = 0;
            break;
            
        // joystick down
        case 'x':
            //if(!STICK2WAY && !(STICK4WAY && (left || right)))
            if(STICK4WAY)
            {
               gp2x_pad_status &= ~GP2X_LEFT;
               gp2x_pad_status &= ~GP2X_RIGHT;
            }            
            if(!STICK2WAY)
               gp2x_pad_status |= GP2X_DOWN;
            down = 1;   
            break;
        case 'z':
            if(STICK4WAY)
            {
               if(left)gp2x_pad_status |= GP2X_LEFT;
               if(right)gp2x_pad_status |= GP2X_RIGHT;
            }
            gp2x_pad_status &= ~GP2X_DOWN;
            down = 0;   
            break;
            
        // joystick right
        case 'd':            
            if(STICK4WAY)
            {
               gp2x_pad_status &= ~GP2X_UP;
               gp2x_pad_status &= ~GP2X_DOWN;
            }
            gp2x_pad_status |= GP2X_RIGHT;
            right = 1;
            break;
        case 'c':
            if(STICK4WAY)
            {
               if(up)gp2x_pad_status |= GP2X_UP;
               if(down)gp2x_pad_status |= GP2X_DOWN;
            }
            gp2x_pad_status &= ~GP2X_RIGHT;
            right = 0;
            break;
            
        // joystick left
        case 'a':            
            if(STICK4WAY)
            {
               gp2x_pad_status &= ~GP2X_UP;
               gp2x_pad_status &= ~GP2X_DOWN;
            }
            gp2x_pad_status |= GP2X_LEFT;
            left = 1;
            break;
        case 'q':
            if(STICK4WAY)
            {
               if(up)gp2x_pad_status |= GP2X_UP;
               if(down)gp2x_pad_status |= GP2X_DOWN;
            }
            gp2x_pad_status &= ~GP2X_LEFT;
            left = 0;
            break;
            
        // Y / UP
        case 'i':
            gp2x_pad_status |= GP2X_Y;
            btnStates[BTN_Y] = BUTTON_PRESS;
            break;
        case 'm':
            gp2x_pad_status &= ~GP2X_Y;
            btnStates[BTN_Y] = BUTTON_NO_PRESS;
            break;
            
        // X / DOWN
        case 'l':
            gp2x_pad_status |= GP2X_X;
            btnStates[BTN_X] = BUTTON_PRESS;
            break;
        case 'v':
            gp2x_pad_status &= ~GP2X_X;
            btnStates[BTN_X] = BUTTON_NO_PRESS;
            break;
            
        // A / LEFT
        case 'k':
            gp2x_pad_status |= GP2X_A;
            btnStates[BTN_A] = BUTTON_PRESS;
            break;
        case 'p':
            gp2x_pad_status &= ~GP2X_A;
            btnStates[BTN_A] = BUTTON_NO_PRESS;
            break;
            
        // B / RIGHT
        case 'o':
            gp2x_pad_status |= GP2X_B;
            btnStates[BTN_B] = BUTTON_PRESS;
            break;
        case 'g':
            gp2x_pad_status &= ~GP2X_B;
            btnStates[BTN_B] = BUTTON_NO_PRESS;
            break;
            
        // SELECT / COIN
        case 'y': //button down
            gp2x_pad_status |= GP2X_SELECT;
            btnStates[BTN_SELECT] = BUTTON_PRESS;
            break;
        case 't': //button up
            gp2x_pad_status &= ~GP2X_SELECT;
            btnStates[BTN_SELECT] = BUTTON_NO_PRESS;
            break;
            
        // START
        case 'u':   //button down
            if(iOS_iCadeLayout) { 
                gp2x_pad_status |= GP2X_L;
                btnStates[BTN_L1] = BUTTON_PRESS;
            }
            else {
                gp2x_pad_status |= GP2X_START;
                btnStates[BTN_START] = BUTTON_PRESS;
            }
            break;
        case 'f':   //button up
            if(iOS_iCadeLayout) { 
                gp2x_pad_status &= ~GP2X_L;
                btnStates[BTN_L1] = BUTTON_NO_PRESS;
            }
            else {
                gp2x_pad_status &= ~GP2X_START;
                btnStates[BTN_START] = BUTTON_NO_PRESS;
            }
            break;
            
        // 
        case 'h':   //button down
            if(iOS_iCadeLayout) { 
                gp2x_pad_status |= GP2X_START;
                btnStates[BTN_START] = BUTTON_PRESS;
            }
            else {
                gp2x_pad_status |= GP2X_L;
                btnStates[BTN_L1] = BUTTON_PRESS;
            }
            break;
        case 'r':   //button up
            if(iOS_iCadeLayout) { 
                gp2x_pad_status &= ~GP2X_START;
                btnStates[BTN_START] = BUTTON_NO_PRESS;
            }
            else {
                gp2x_pad_status &= ~GP2X_L;
                btnStates[BTN_L1] = BUTTON_NO_PRESS;
            }
            break;
            
        // 
        case 'j':
            gp2x_pad_status |= GP2X_R;
            btnStates[BTN_R1] = BUTTON_PRESS;
            break;
        case 'n':
            gp2x_pad_status &= ~GP2X_R;
            btnStates[BTN_R1] = BUTTON_NO_PRESS;
            break;
    }
    
    // calculate dpad_state
    switch (gp2x_pad_status & (GP2X_UP|GP2X_DOWN|GP2X_LEFT|GP2X_RIGHT))
    {
        case    GP2X_UP:    dpad_state = DPAD_UP; break;
        case    GP2X_DOWN:  dpad_state = DPAD_DOWN; break;
        case    GP2X_LEFT:  dpad_state = DPAD_LEFT; break;
        case    GP2X_RIGHT: dpad_state = DPAD_RIGHT; break;
            
        case    GP2X_UP | GP2X_LEFT:  dpad_state = DPAD_UP_LEFT; break;
        case    GP2X_UP | GP2X_RIGHT: dpad_state = DPAD_UP_RIGHT; break;
        case    GP2X_DOWN | GP2X_LEFT:  dpad_state = DPAD_DOWN_LEFT; break;
        case    GP2X_DOWN | GP2X_RIGHT: dpad_state = DPAD_DOWN_RIGHT; break;
            
        default: dpad_state = DPAD_NONE;
    }
    
    static int cycleResponder = 0;
    if (++cycleResponder > 20) {
        // necessary to clear a buffer that accumulates internally
        cycleResponder = 0;
        warnIcade = 0;
        [self resignFirstResponder];
        [self becomeFirstResponder];
        warnIcade = 1;
        
    }
    
    //[self handle_MENU];
    [self handle_DPAD];
}

- (void)deleteBackward 
{
}
- (BOOL)hasText 
{
    return YES;
}

- (void)getControllerCoords:(int)orientation {
    char string[256];
    FILE *fp;
	
	if(!orientation)
	{
		if(isIpad)
		{
 		   if(iOS_full_screen_port)
		     fp = fopen([[NSString stringWithFormat:@"%s/SKIN_%d/controller_portrait_full_iPad.txt",  get_resource_path("/"), iOS_skin_data] UTF8String], "r");
		   else
		     fp = fopen([[NSString stringWithFormat:@"%s/SKIN_%d/controller_portrait_iPad.txt",  get_resource_path("/"), iOS_skin_data] UTF8String], "r");
		}  
		else
		{
		   if(iOS_full_screen_port)
		     fp = fopen([[NSString stringWithFormat:@"%s/SKIN_%d/controller_portrait_full_iPhone.txt", get_resource_path("/"),  iOS_skin_data] UTF8String], "r");
		   else
		     fp = fopen([[NSString stringWithFormat:@"%s/SKIN_%d/controller_portrait_iPhone.txt", get_resource_path("/"),  iOS_skin_data] UTF8String], "r");  
		}
    }
	else
	{
		if(isIpad)
		{
		   if(iOS_full_screen_land)
		     fp = fopen([[NSString stringWithFormat:@"%s/SKIN_%d/controller_landscape_full_iPad.txt", get_resource_path("/"), iOS_skin_data] UTF8String], "r");
		   else
		     fp = fopen([[NSString stringWithFormat:@"%s/SKIN_%d/controller_landscape_iPad.txt", get_resource_path("/"), iOS_skin_data] UTF8String], "r");
		}
		else
		{
		   if(iOS_full_screen_land)
		     fp = fopen([[NSString stringWithFormat:@"%s/SKIN_%d/controller_landscape_full_iPhone.txt", get_resource_path("/"), iOS_skin_data] UTF8String], "r");
		   else
		     fp = fopen([[NSString stringWithFormat:@"%s/SKIN_%d/controller_landscape_iPhone.txt", get_resource_path("/"), iOS_skin_data] UTF8String], "r");
		}
	}
	
	if (fp) 
	{

		int i = 0;
        while(fgets(string, 256, fp) != NULL && i < 39) 
       {
			char* result = strtok(string, ",");
			int coords[4];
			int i2 = 1;
			while( result != NULL && i2 < 5 )
			{
				coords[i2 - 1] = atoi(result);
				result = strtok(NULL, ",");
				i2++;
			}
			
			/*
			if(isIpad && orientation==1)
			{
			     coords[1] =  coords[1] - 100;
			}*/
			
			switch(i)
			{
    		case 0:    DownLeft   	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 1:    Down   	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 2:    DownRight    = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 3:    Left  	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 4:    Right  	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 5:    UpLeft     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 6:    Up     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 7:    UpRight  	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 8:    Select = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 9:    Start  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 10:   LPad   = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 11:   RPad   = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 12:   Menu   = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 13:   ButtonDownLeft   	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 14:   ButtonDown   	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 15:   ButtonDownRight    	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 16:   ButtonLeft  		= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 17:   ButtonRight  	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 18:   ButtonUpLeft     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 19:   ButtonUp     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 20:   ButtonUpRight  	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 21:   LPad2   = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 22:   RPad2   = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 23:   rShowKeyboard  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		
    		case 24:   rButton_image[BTN_B] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 25:   rButton_image[BTN_X]  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 26:   rButton_image[BTN_A]  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 27:   rButton_image[BTN_Y]  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 28:   rDPad_image  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 29:   rButton_image[BTN_SELECT]  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 30:   rButton_image[BTN_START]  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 31:   rButton_image[BTN_L1] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 32:   rButton_image[BTN_R1] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 33:   rButton_image[BTN_L2] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 34:   rButton_image[BTN_R2] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            
            case 35:   rStickWindow = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 36:   rStickArea = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 37:   iOS_stick_radio =coords[0]; break;            
            case 38:   iphone_controller_opacity= coords[0]; break;
			}
      i++;
    }
    fclose(fp);
    
    if(iOS_touchDeadZone)
    {
        //ajustamos
        if(!isIpad)
        {
           if(!orientation)
           {
             Left.size.width -= 17;//Left.size.width * 0.2;
             Right.origin.x += 17;//Right.size.width * 0.2;
             Right.size.width -= 17;//Right.size.width * 0.2;
           }
           else
           {
             Left.size.width -= 14;
             Right.origin.x += 20;
             Right.size.width -= 20;
           }
        }
        else
        {
           if(!orientation)
           {
             Left.size.width -= 22;//Left.size.width * 0.2;
             Right.origin.x += 22;//Right.size.width * 0.2;
             Right.size.width -= 22;//Right.size.width * 0.2;
           }
           else
           {
             Left.size.width -= 22;
             Right.origin.x += 22;
             Right.size.width -= 22;
           }
        }    
    }
  }
}

- (void)getConf{
    char string[256];
    FILE *fp;
	
	if(isIpad)
	   fp = fopen([[NSString stringWithFormat:@"%sconfig_iPad.txt", get_resource_path("/")] UTF8String], "r");
	else
	   fp = fopen([[NSString stringWithFormat:@"%sconfig_iPhone.txt", get_resource_path("/")] UTF8String], "r");
	   	
	if (fp) 
	{

		int i = 0;
        while(fgets(string, 256, fp) != NULL && i < 12) 
       {
			char* result = strtok(string, ",");
			int coords[4];
			int i2 = 1;
			while( result != NULL && i2 < 5 )
			{
				coords[i2 - 1] = atoi(result);
				result = strtok(NULL, ",");
				i2++;
			}
						
			switch(i)
			{
    		case 0:    rEmulatorFrame   	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 1:    rPortraitViewFrame     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 2:    rPortraitViewFrameNotFull = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;    		
    		case 3:    rPortraitImageBackFrame     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 4:    rPortraitImageOverlayFrame     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;    		    		
    		case 5:    rLandscapeViewFrame = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 6:    rLandscapeViewFrameFull = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;      		    		    		
    		case 7:    rLandscapeViewFrameNotFull = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;    		
    		case 8:    rLandscapeImageBackFrame  	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;  
    		case 9:    rLandscapeImageOverlayFrame     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;      		  		
            case 10:    rLoopImageMask = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;    	
            case 11:   enable_dview = coords[0]; break;
			}
      i++;
    }
    fclose(fp);
  }
}


- (void)didReceiveMemoryWarning {
	//[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {

    [self removeDPadView];

    if(screenView!=nil)
      [screenView release];
       
    if(imageBack!=nil)
      [imageBack release];
      
    if(imageOverlay!=nil)
      [imageOverlay release];
 
    if(dview!=nil)
	   [dview release];	   
	   
	[super dealloc];
}

- (void)filldrectsController {

	    	drects[0]=ButtonDownLeft;
	    	drects[1]=ButtonDown;
	    	drects[2]=ButtonDownRight;
	    	drects[3]=ButtonLeft;
	    	drects[4]=ButtonRight;
	    	drects[5]=ButtonUpLeft;
	    	drects[6]=ButtonUp;
	        drects[7]=ButtonUpRight;
    		drects[8]=Select;
    		drects[9]=Start;
    		drects[10]=LPad;
    		drects[11]=RPad;
    		drects[12]=Menu;
    		drects[13]=LPad2;
    		drects[14]=RPad2;
    		drects[15]=rShowKeyboard;
    		
    		if(iOS_inputTouchType==TOUCH_INPUT_DIGITAL)
    		{
				drects[16]=DownLeft;
				drects[17]=Down;
				drects[18]=DownRight;
				drects[19]=Left;
				drects[20]=Right;
				drects[21]=UpLeft;
				drects[22]=Up;
				drects[23]=UpRight;
	    		
	            ndrects = 24;     
            }
            else
            {
  	    		drects[16]=rStickWindow;
	    		drects[17]=rStickArea;
	    		
	            ndrects = 18;          
            }   
}

@end
