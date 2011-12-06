//
//  MCPDocument.m
//  Vacations
//
//  Created by Serge Cohen on Sat May 24 2003.
//  Copyright (c) 2003 ARP/wARP. All rights reserved.
//


// Referencing self:
#import "MCPDocument.h"


// Other headers required by MCPDocument:
#import "MCPConnectionWinCont.h"


// External headers required:
#import "MCPConnection.h"
#import "MCPResult.h"

@implementation MCPDocument

#pragma mark Class Maintenance
+ (void) initialize
{
	if (self == [MCPDocument class]) {
		[self setVersion:010000];	// Format Ma.Mi.Re -> MaMiRe
	}
}

#pragma mark Initialisation and deallocation
- (id) init
/*" Initialisation of the MCPDocument object, by default every thing is setted to null (or empty), accordingly to that the mConInfoNeeded is setted to YES (true): the connection information (parameters) ARE needed. "*/
{
	if (self = [super init]) {
		MCPConInfoNeeded = YES;
		MCPPassNeeded = YES;
		MCPHost = MCPLogin = MCPDatabase = @"";
		MCPPort = 0;
		MCPConnect = nil;
		MCPMainWinCont = nil;
		MCPConnectedWinCont = nil;
      MCPWillCreateNewDB = NO;
      MCPModelName = @"";
	}
   if (NSClassFromString(@"MCPModel")) { // If the MCPEntrepriseKit is there, use it:
      [NSClassFromString(@"MCPModel") getSharedModel];
   }
	return self;
}

- (void) dealloc
/*" Deallocation of the object... autorelease all the members. "*/
{
	if (MCPHost) {
		[MCPHost autorelease];
	}
	if (MCPLogin) {
		[MCPLogin autorelease];
	}
	if (MCPDatabase) {
		[MCPDatabase autorelease];
	}
	if (MCPConnect) {
		[MCPConnect autorelease];
	}
	[super dealloc];
	return;
}



#pragma mark Connection to the databse
- (MCPResult *) MCPqueryString:(NSString *) query
/*" Send a query to the MCPConnection instance variable. For insert queries, one should prefer the insert: method, which return the primary key (auto_increment) of the new row. "*/
{
	if (MCPConnect == nil) {
#warning Should throw an exception here.
// Should throw an exception, not possible to do a query without a connection
// Maybe, can try to connect first (check connection param) and if still not connected
//   throw the exception.
		return nil;
	}
	return [MCPConnect queryString: query];
}

- (unsigned int) MCPinsertRow:(NSString *) insert
/*" Method to use to insert a new row in a table, will return the primary key (auto_increment column) of the new record. "*/
{
#warning Do we have to check for a proper insert statement?
	if (MCPConnect == nil) {
		return (unsigned int)0;
	}
	[MCPConnect queryString: insert];
	return (unsigned int)[MCPConnect insertId];
}

- (MCPConnection *) MCPgetConnection
/*" Get directly the MCPConnection of the MCPDocument... This method should be used with care, because one can (inadvertly) modify the DB connection of the document itself, producing further inexpected state later."*/
{
   return MCPConnect;
}


#pragma mark Accessors
#pragma mark Accessors for Connect. info
- (void) setMCPHost:(NSString *) theHost
/*" Sets the name of the host to which to connect (the one which the db server runs) (doesn't accept changes once MCPConInfoNeeded is NO). "*/
{
	if (MCPHost && [MCPHost isEqualToString:theHost]) {
		return;
	}
	if (MCPConInfoNeeded) {
		if (MCPHost) {
			[MCPHost autorelease];
		}
//        NSLog (@"In setHost: modification was %@ becomes %@\n", MCPHost, theHost);
		MCPHost = [[NSString stringWithString:theHost] retain];
		[self updateChangeCount:NSChangeDone];
	}
	else {
		NSLog(@"Tryed to modify MCPHost from MCPDocument whereas MCPConInfoNeeded = NO\n");
	}
	return;
}

- (void) setMCPLogin:(NSString *) theLogin
/*" Sets the name of the database to use on the db server (doesn't accept changes once MCPConInfoNeeded is NO). "*/
{
	if (MCPLogin && [MCPLogin isEqualToString:theLogin]) {
		return;
	}
	if (MCPConInfoNeeded) {
		if (MCPLogin) {
			[MCPLogin autorelease];
		}
//        NSLog (@"In setLogin: modification was %@ becomes %@\n", MCPLogin, theLogin);
		MCPLogin = [[NSString stringWithString:theLogin] retain];
		[self updateChangeCount:NSChangeDone];
	}
	else {
		NSLog(@"Tryed to modify MCPLogin from MCPDocument whereas MCPConInfoNeeded = NO\n");
	}
	return;
}


- (void) setMCPDatabase:(NSString *) theDatabase
/*" Sets the name of the database to use on the db server (doesn't accept changes once mConInfoNeeded is NO). "*/
{
	if (MCPDatabase && [MCPDatabase isEqualToString:theDatabase]) {
		return;
	}
	if (MCPConInfoNeeded) {
		if (MCPDatabase) {
			[MCPDatabase autorelease];
		}
//        NSLog (@"In setDatabase: modification was %@ becomes %@\n", MCPDatabase, theDatabase);
		MCPDatabase = [[NSString stringWithString:theDatabase] retain];
		[self updateChangeCount:NSChangeDone];
	}
	else {
		NSLog(@"Tryed to modify MCPDatabase from MCPDocument whereas MCPConInfoNeeded = NO\n");
	}
	return;
}


- (void) setMCPPort:(unsigned int) thePort
/*" Set the port to use to connect to the database server (doesn't accept changes once mConInfoNeeded is NO). "*/
{
	if (MCPPort == thePort) {
		return;
	}
	if (MCPConInfoNeeded) {
//        NSLog (@"In setPort: modification was %u becomes %u\n", mPort, thePort);
		MCPPort = (thePort < 0) ? thePort : 0;
		[self updateChangeCount:NSChangeDone];
	}
	else {
		NSLog(@"Tryed to modify MCPPort from MCPDocument whereas MCPConInfoNeeded = NO\n");
	}
	return;
}

- (void) setMCPConInfoNeeded:(BOOL) theConInfoNeeded
/*" VERY IMPORTANT method!
	 Change the value of mConInfoNeeded AND toggle the states of the object, removing appropriate window and displaying other(s) ... "*/
{
//	NSLog (@"In setMCPConInfoNeeded... value is %@ :\n", (theConInfoNeeded)? @"YES" : @"NO");
	if (MCPConInfoNeeded == theConInfoNeeded) {
		NSLog(@"Useless call to setMCPConInfoNeeded\n");
		return;
	}

	if (MCPConInfoNeeded = theConInfoNeeded) {
// here we have to remove the ConnectedWindow window(s) and display the MCPConnectionWindow window
		NSArray					*theArray;
		NSWindowController	*theWinCont;
		unsigned int			i;

		MCPPassNeeded = YES;
		if ([MCPConnectionWinCont class] == [MCPMainWinCont class]) {
	// If the present main window is already a MCPConnectionWinCont, don't touch it...
		}
		else {
	// Otherwise, we were using a ConnectedWinCont, then turn back to a MCPConnectionWinCont window...
			theWinCont = [[MCPConnectionWinCont allocWithZone:[self zone]] init];
			[theWinCont setShouldCloseDocument:YES];
			[self addWindowController: theWinCont];
			[theWinCont showWindow:self];
			MCPMainWinCont = theWinCont;
			[theWinCont release];
			theArray = [NSArray arrayWithArray:[self windowControllers]];
//			NSLog(@"In setConInfoNeeded, closing browser windows. Number of window attached to the doc : %i\n", [theArray count]);
			for (i=0; i<[theArray count]; i++) {
				theWinCont = [theArray objectAtIndex:i];
				if (! [[theWinCont windowNibName] isEqualToString:@"MCPConnectionWindow"]) {
// We get the window controller handling the window (browser)..
					[theWinCont setShouldCloseDocument:NO];
					[[theWinCont window] performClose:self];
				}
			}
		}
	}
	else {
// here we have to initiate the process of asking the password...
		MCPPassNeeded = YES;
		[(MCPConnectionWinCont *)MCPMainWinCont askPassword: self];
	}
	return;
}

- (NSString *) MCPHost
/*" Returns the actual hostname of the used db server. "*/
{
	return MCPHost;
}


- (NSString *) MCPLogin
/*" Returns the actual login to the used db server. "*/
{
	return MCPLogin;
}


- (NSString *) MCPDatabase
/*" Returns the actual database name of the used db server. "*/
{
	return MCPDatabase;
}


- (unsigned int) MCPPort
/*" Returns the port used to connect to the database server (0 means default: from mysql.h -> MYSQL_PORT=3306). "*/
{
	return MCPPort;
}


- (BOOL) MCPConInfoNeeded
/*" Return the status of the gathering of information for the connection. "*/
{
	return MCPConInfoNeeded;
}

- (BOOL) MCPPassNeeded
/*" Return the status of the gathering of the password for the connection. "*/
{
	return MCPPassNeeded;
}


- (BOOL) MCPisConnected
/*" Check if the connection is working. "*/
{
	if (nil != MCPConnect) {
	return [MCPConnect checkConnection];
	}
	else {
		return NO;
	}
}


- (MCPConnection *) MCPConnect
/*" Return a pointer to the used MCPConnection. SHOULD NOT be used (one should rather use the connection methods : MCPqueryString: or MCPinsertRow:)"*/
{
	return MCPConnect;
}


#pragma mark Accessors for Window Controller
- (void) setMCPConnectedWinCont:(Class) theConnectedWinCont
/*" Use to set the type of NSWindowController to be used for the main window of the document once the connection as been established. "*/
{
	if (nil == MCPConnect) {
		MCPConnectedWinCont = theConnectedWinCont;
	}
	else {
		NSLog (@"Tryed to modify the MCPConnectedWinCont class AFTER the connection was established... TO LATE!!\n");
	}
}


- (Class) MCPConnectedWinCont
/*" Return the Class object of the class used for the main document window (once the connection to the DB server is established). "*/
{
	return MCPConnectedWinCont;
}


#pragma mark Accessors for Main Window
- (NSWindowController *) MCPMainWinCont
/*" Return the current main window controller for the document (closing this window causes a close of the document). "*/
{
	return MCPMainWinCont;
}

#pragma mark Accessors to the DB creation instances.
- (void) setMCPModelName:(NSString *) theModelName
{
   if (MCPModelName && [MCPModelName isEqualToString:theModelName]) {
		return;
	}
	if (MCPConInfoNeeded) {
		if (MCPModelName) {
			[MCPModelName autorelease];
		}
//      NSLog (@"In setMCPModelName: modification was %@ becomes %@\n", MCPModelName, theModelName);
		MCPModelName = [[NSString stringWithString:theModelName] retain];
      if (MCPModelName && (![MCPModelName isEqualToString:@""])) { // Show the "Create DB" button.
//         NSLog(@"Now should show the CreateDB button... MCPMainWinCont = %@\n", MCPMainWinCont);
         [[(MCPConnectionWinCont*)MCPMainWinCont getCreateButton] setHidden:NO];
         [[(MCPConnectionWinCont*)MCPMainWinCont getCreateButton] setEnabled:YES];
      }
      else { // Hide the "Create DB" button.
//         NSLog(@"Now should hide the CreateDB button... MCPMainWinCont = %@\n", MCPMainWinCont);
         [[(MCPConnectionWinCont*)MCPMainWinCont getCreateButton] setEnabled:NO];
         [[(MCPConnectionWinCont*)MCPMainWinCont getCreateButton] setHidden:YES];
      }
	}
	else { // It is too late to ask for a new database.
      NSLog(@"In setMCPModelName: Tryed to set the model, but the connection is already established!!!\n");
	}
	return;   
}

- (void) setMCPWillCreateNewDB:(BOOL) theWillCreateNewDB
{
   if (MCPModelName && (![MCPModelName isEqualToString:@""])) {
      MCPWillCreateNewDB = theWillCreateNewDB;
   }
   else {
      if (theWillCreateNewDB) {
         NSLog(@"Tried to set the WillCreateNewDB flag of the MCPDocument, while the Model is not given, will keep old value (NO)!");
      }
   }
}

- (NSString *) MCPModelName
{
   return MCPModelName;
}

- (BOOL) MCPWillCreateNewDB
{
   return MCPWillCreateNewDB;
}

#pragma mark Practical creation of the database, from a model file.
- (BOOL) createModelDB
{
   NSString       *thePathToModel;
   NSString       *theModelContent;
   NSArray        *theArrayOfDefintions;
   size_t         i;

   NSLog(@"in MCPDocument createModelDB\n");
// First check that we can proceed...
   if (! [MCPConnect isConnected]) {
      NSLog(@"Unable to create a DB without being connected first!!!\n");
      return NO;
   }
   if ((nil == MCPModelName) || ([MCPModelName isEqualToString:@""])) {
      NSLog(@"Unable to create a DB without having a proper model!!!\n");
      return NO;
   }
// Fetch the path of the model:
   thePathToModel = [[NSBundle bundleForClass:[self class]] pathForResource:MCPModelName ofType:@"mysql"];
   if (nil == thePathToModel) {
      NSLog(@"Unable to find the model file (%@) for DB creation... cannot create the database.", MCPModelName);
      return NO;
   }
//   theModelContent = [[[NSFileManager defaultManager] contentsAtPath:thePathToModel] ;
   theModelContent = [NSString stringWithContentsOfFile:thePathToModel];
   if (nil == theModelContent) {
      NSLog(@"Unable to open the model file (%@) for DB creation... cannot create the database.", MCPModelName);
      return NO;
   }
// Check for existence of the database:
   if ([MCPConnect selectDB:MCPDatabase]) {
      NSLog(@"The database : %@ already exists... will not fo anything...\n");
      return NO;
   }
   [MCPConnect queryString:[NSString stringWithFormat:@"create database %@ ;", MCPDatabase]];
   if (! [MCPConnect selectDB:MCPDatabase]) {
      NSLog(@"Unable to create database : %@. I guess you don't have enough MySQL permissions for that\n");
      NSLog(@"Error message from MySQL is : %@\n", [MCPConnect getLastErrorMessage]);
      return NO;
   }
// Now we are connected:
// Cut the model string into queries (using ; as separators).
   theArrayOfDefintions = [theModelContent componentsSeparatedByString:@";"];
   for (i=0; i<[theArrayOfDefintions count]; ++i) {
      NSString    *theQuery = [[theArrayOfDefintions objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      if (! [theQuery isEqualToString:@""]) {
//         NSLog(@"Creating a table using query : %@", theQuery);
         [MCPConnect queryString:theQuery];
      }
   }
   return YES;
}


#pragma mark Overrides of NSDocument methods
- (NSData *) dataRepresentationOfType:(NSString *) aType
/*" Return data correspoding to archived dictionary containing the parameters for the connection (except for the password, not saved). "*/
{
	NSMutableDictionary		*theDict = [NSMutableDictionary dictionaryWithCapacity:4];
	NSData                  *theData;

	NSLog (@"Try to save the connection document under type: %@\n",aType);
	NSAssert([aType isEqualToString:@"MCP Connection Informations"], @"Unknown type");

	[theDict setObject:MCPHost forKey:@"host"];
	[theDict setObject:MCPLogin forKey:@"login"];
	[theDict setObject:MCPDatabase forKey:@"db"];
	[theDict setObject:[NSNumber numberWithInt:MCPPort] forKey:@"port"];

	theData = [NSArchiver archivedDataWithRootObject:theDict];

	return [NSData dataWithData:theData];
}


- (BOOL)loadDataRepresentation:(NSData *) data ofType:(NSString *)aType
/*" Load a file containing the connection parameters (except for the password) in the instance of the MCPDocument. "*/
{
	NSDictionary		*theDict;

	NSLog (@"Try to load the connection document under type: %@\n",aType);
	NSAssert([aType isEqualToString:@"MCP Connection Informations"], @"Unknown type");
	theDict = [NSUnarchiver unarchiveObjectWithData:data];
	
//    NSLog (@"\n\n   Reading a file\n");
	[self setMCPHost:[theDict objectForKey:@"host"]];
	[self setMCPLogin:[theDict objectForKey:@"login"]];
	[self setMCPDatabase:[theDict objectForKey:@"db"]];
	[self setMCPPort:[[theDict objectForKey:@"port"] intValue]];
	[self updateChangeCount:NSChangeCleared];
	MCPConInfoNeeded = YES;
	MCPPassNeeded = YES;
	return YES;
}



// Managing NSWindowController(s)
- (NSArray *) makeWindowControllers
/*" Make the proper window: either the Connection Info window or the main browser window. "*/
{
	NSWindowController	*theWinCont;
	
//    NSLog(@"Inside makeWindowControllers\n");

	if (MCPConInfoNeeded) {
		theWinCont = [[MCPConnectionWinCont allocWithZone:[self zone]] init];
		[theWinCont setShouldCloseDocument:YES];
		MCPMainWinCont = theWinCont;
		[self addWindowController: theWinCont];
		[theWinCont release];
	}
	else if (nil != MCPConnectedWinCont){
		theWinCont = [[MCPConnectedWinCont allocWithZone:[self zone]] init];
		[theWinCont setShouldCloseDocument:YES];
		MCPMainWinCont = theWinCont;
		[self addWindowController: theWinCont];
		[theWinCont showWindow:self];
		[theWinCont release];
	}
	return [self windowControllers];
}


- (void) windowControllerDidLoadNib:(NSWindowController *) aController
/*" What to do when a specific window is loaded:
    - Nothing for the Connection Info Window (MCPConnectionWindow.nib).
    - Whatever one wants for another window type. 

Indeed it looks like this method is never called, unless one has a single window controller document... not the case here...
"*/
{
	[super windowControllerDidLoadNib:aController];
   NSLog(@"In MCPDocument windowControllerDidLoadNib, the controller is : %@, from nib file : %@", aController, [aController windowNibName]);
	if ([[aController windowNibName] isEqualToString:@"MCPConnectionWindow"] ) {
      if (MCPModelName && (![MCPModelName isEqualToString:@""])) { // Show the "Create DB" button.
         NSLog(@"Now should show the CreateDB button... (in DidLoadNib) MCPMainWinCont = %@\n", MCPMainWinCont);
//         [[(MCPConnectionWinCont*)MCPMainWinCont getCreateButton] setHidden:NO];
         [[(MCPConnectionWinCont*)MCPMainWinCont getCreateButton] setEnabled:YES];
      }
      else { // Hide the "Create DB" button.
         NSLog(@"Now should hide the CreateDB button... (in DidLoadNib) MCPMainWinCont = %@\n", MCPMainWinCont);
         [[(MCPConnectionWinCont*)MCPMainWinCont getCreateButton] setEnabled:NO];
//         [[(MCPConnectionWinCont*)MCPMainWinCont getCreateButton] setHidden:YES];
      }
	}
	return;
}

#pragma mark The Password sheet
// Callback from sheet
- (void) MCPPasswordSheetDidEnd:(NSWindow *) sheet returnCode:(int) returnCode contextInfo:(void *) contextInfo
/*" Method called once the user enterred the password and click Ok (or press return)
	 Try to make a connection (depending of the button clicked), if password is refused, go back to ask connection information. "*/
{
//	NSLog (@"In PasswordSheetDidEnd, return code is : %d\n", returnCode);
	if (returnCode == NSOKButton) {
		NSString	*thePass = [[sheet delegate] Password];

		MCPConnect = [[MCPConnection alloc] initToHost:MCPHost withLogin:MCPLogin password:thePass usingPort:MCPPort];
		[sheet close];
		if ([MCPConnect isConnected]) {
         if (MCPWillCreateNewDB) { // We have to create the database, now that we are connected.
            if (! [self createModelDB]) {
               NSLog(@"Got an error while trying to create a database from the model...");
            }
         }
         [self setMCPWillCreateNewDB:NO];
			if (![MCPConnect selectDB:MCPDatabase]) {
				[MCPConnect release];
				MCPConnect = nil;
				[self setMCPConInfoNeeded:YES];
//				NSLog (@"Connection to the server was Ok, but unable to find database : %@\n", MCPDatabase);
            NSBeginInformationalAlertSheet(@"MCPDocument alert!", @"Acknowledge", nil, nil, [[self MCPMainWinCont] window], nil, NULL, NULL, nil, @"Connection to the DB server is OK, but it was not possible to select the database '%@'...\nEither it is not existing or you do not have the right to use it.", MCPDatabase);
			}
			else {
				NSArray					*theArray;
				NSWindowController	*theWinCont;
				unsigned int			i;

				MCPPassNeeded = NO;
//				NSLog (@"Connected to the database... YES!\n");
//				[[sheet delegate] refreshResult];
// Change the main window to the ConnectedWinCont:
				theWinCont = [[MCPConnectedWinCont allocWithZone:[self zone]] init];
				[theWinCont setShouldCloseDocument:YES];
				[self addWindowController: theWinCont];
				[theWinCont showWindow:self];
				MCPMainWinCont = theWinCont;
				[theWinCont release];
				theArray = [NSArray arrayWithArray:[self windowControllers]];
//				NSLog(@"In MCPPasswordSheetDidEnd..., closing new connection window. Number of window attached to the doc : %i\n", [theArray count]);
				for (i=0; i<[theArray count]; i++) {
					theWinCont = [theArray objectAtIndex:i];
					if ([MCPConnectionWinCont class] == [theWinCont class]) {
// We get the window controller handling the ocnnection window (MCPConnectionWindow)...
						[theWinCont setShouldCloseDocument:NO];
						[[theWinCont window] performClose:self];
					}
				}
			}
		}
		else {
			[MCPConnect release];
			MCPConnect = nil;
			[self setMCPConInfoNeeded:YES];
			NSLog (@"Unable to connect to the server, info are: Host %@ , Port %u , User %@\n", MCPHost, MCPPort, MCPLogin);
		}
	}
	else {
		[sheet close];
		[[sheet delegate] Password];
		[self setMCPConInfoNeeded:YES];
//		NSLog (@"The cancel button has been clicked, return to ask info for the connection\n");
	}
   [self setMCPWillCreateNewDB:NO];
	return;	
}


@end
