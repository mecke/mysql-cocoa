//
//  MCPConnectionWinCont.m
//  Vacations
//
//  Created by Serge Cohen on Mon May 26 2003.
//  Copyright (c) 2003 ARP/wARP. All rights reserved.
//

// Referencing self:
#import "MCPConnectionWinCont.h"


// Other headers required by MCPDocument:
#import "MCPDocument.h"


// External headers required:
#if FRAMEWORK_TYPE == SYSTEM
#import <MCPKit_system/MCPKit_system.h>
#elif FRAMEWORK_TYPE == BUNDLED
#import <MCPKit_bundled/MCPKit_bundled.h>
#else
#error The type of framework to compile should be defined on using the macro FRAMEWORK_TYPE (SYSTEM, or BUNDLED)
#endif // FRAMEWORK_TYPE

@implementation MCPConnectionWinCont
/*" This class is the WindowController for the window asking parameters of connection to the user.

 It is responsible to set the appropriate value of the MCPDocument instance variables. "*/

- (IBAction) doGo:(id) sender
/*" What to do when the user clicks on the Go button of the window. "*/
{
	MCPDocument	*theDoc = (MCPDocument *)[self document];
// Send update message to the previously setted element
	[[self window] endEditingFor:[[self window] firstResponder]];
	
// Check that the proper fields are set
	if (([[theDoc MCPHost] isEqualToString:@""]) || ([[theDoc MCPLogin] isEqualToString:@""]) || ([[theDoc MCPDatabase] isEqualToString:@""])  || ([theDoc MCPHost] == nil)  || ([theDoc MCPLogin] == nil)  || ([theDoc MCPDatabase] == nil)) {
		NSBeginAlertSheet(@"", @"OK", nil, nil, [sender window], self, nil, nil, self, @"Unable to connect, one of the fields Host, Login or Database might be empty!");
		return;
	}
	[theDoc setMCPConInfoNeeded:NO];
	return;
}


- (IBAction) doCancel:(id) sender
/*" What to do when the user clicks on the Cancel button of the window. "*/
{
	[[self window] performClose:self];
	return;
}

- (IBAction) doCreate:(id) sender
{
   NSLog(@"Asked for creation of the databes...");
   [(MCPDocument*)[self document] setMCPWillCreateNewDB:YES];
   [self doGo:sender];
   return;
}


- (IBAction) modifyInstance:(id) sender
/*" Action to take when the user modify one of the entry of the New Connection dialog. "*/
{
	MCPDocument		*theDoc = (MCPDocument *)[self document];

	if (sender == mHostField) {
		[theDoc setMCPHost:[sender stringValue]];
	}
	else if (sender == mLoginField) {
		[theDoc setMCPLogin:[sender stringValue]];
	}
	else if (sender == mPortField) {
		[theDoc setMCPPort:[sender intValue]];
	}
	else if (sender == mDatabaseField) {
		[theDoc setMCPDatabase:[sender stringValue]];
	}
	else {
// Where is the action coming from?
		NSLog (@"modifyInstance from an unknown sender : %@\n", sender);
	}
	return;
}


	/*" For the password. "*/
- (IBAction) passwordClick:(id) sender
{
	[[NSApplication sharedApplication] endSheet:[sender window] returnCode:[sender tag]];
	return;
}


- (IBAction) askPassword:(id) sender
{
	[[NSApplication sharedApplication] beginSheet:mPasswordSheet modalForWindow:[self window] modalDelegate:[self document] didEndSelector:@selector(MCPPasswordSheetDidEnd:returnCode:contextInfo:) contextInfo:self];
	return;
}

- (NSString *) Password
/*" Send the password (from the NSPasswordField), this method puts the password in the answer (as an autoreleased object), and DELETE it from the NSSecureTextField. "*/
{
	NSString	*thePass = [NSString stringWithString:[mPasswordField stringValue]];
	[mPasswordField setStringValue:@""];
	return thePass;
}


/*" Overrides of NSWindowController method, to adapt to this Window Controller. "*/
- (id) init
/*" When inited, open the proper window... "*/
{
	self = [super initWithWindowNibName:@"MCPConnectionWindow"];
	return self;
}

- (void) dealloc
/*" Gives notification that the WindowController is being deallocated (is it really useful? not yet!). "*/
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


- (void) windowDidLoad
/*" What to do once the window has been loaded : update the fields... "*/
{
	MCPDocument		*theDoc = (MCPDocument *)[self document];

	[super windowDidLoad];
//    [self showWindow:self];
	if ([theDoc MCPHost]) {
		[mHostField setStringValue:[theDoc MCPHost]];
	}
	if ([theDoc MCPLogin]) {
		[mLoginField setStringValue:[theDoc MCPLogin]];
	}
	if ([theDoc MCPDatabase]) {
		[mDatabaseField setStringValue:[theDoc MCPDatabase]];
	}
	[mPortField setIntValue:[theDoc MCPPort]];
   if ([theDoc MCPModelName] && (! [[theDoc MCPModelName] isEqualToString:@""])) {
      [mCreateButton setHidden:NO];
      [mCreateButton setEnabled:YES];
   }
   else {
      [mCreateButton setEnabled:NO];
      [mCreateButton setHidden:YES];
   }
	return;
}

#pragma mark Getting the button for creating a DB.
- (NSButton*) getCreateButton
{
   return mCreateButton;
}

@end
