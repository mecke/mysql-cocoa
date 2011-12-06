//
//  MCPModel.m
//  MCPModeler
//
//  Created by Serge Cohen (serge.cohen@m4x.org) on 09/08/04.
//  Copyright 2004 Serge Cohen. All rights reserved.
//
//  This code is free software; you can redistribute it and/or modify it under
//  the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or any later version.
//
//  This code is distributed in the hope that it will be useful, but WITHOUT ANY
//  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
//  FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
//  details.
//
//  For a copy of the GNU General Public License, visit <http://www.gnu.org/> or
//  write to the Free Software Foundation, Inc., 59 Temple Place--Suite 330,
//  Boston, MA 02111-1307, USA.
//
//  More info at <http://mysql-cocoa.sourceforge.net/>
//

#import "MCPModel.h"

#import "MCPEntrepriseNotifications.h"

#import "MCPClassDescription.h"
#import "MCPAttribute.h"
#import "MCPRelation.h"


@implementation MCPModel

#pragma mark Class methods
+ (void) initialize
{
	if (self = [MCPModel class]) {
		[self setVersion:010101]; // Ma.Mi.Re -> MaMiRe
	}
	return;
}


#pragma mark Life cycle
- (id) initWithName:(NSString *) iName
{
	self = [super init];
	if (self) {
		[self setName:iName];
		classDescriptions = [[NSMutableArray alloc] init];
	}
//	NSLog(@"MAKING a new object : %@", self);
	return self;
}

- (void) dealloc
{
//	NSLog(@"DEALLOCATING object : %@", self);
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[name release];
	[classDescriptions release];
	[super dealloc];
}

#pragma mark NSCoding protocol
- (id) initWithCoder:(NSCoder *) decoder
{
	self = [super init];
	if ((self) && ([decoder allowsKeyedCoding])) {
//      NSLog(@"in MCPModel initWithCoder, model = %@ (pointer = %p)", self, self);
		[self setName:[decoder decodeObjectForKey:@"MCPname"]];
		[self setClassDescriptions:[decoder decodeObjectForKey:@"MCPclassDescriptions"]];
		[self setUsesInnoDBTables:[decoder decodeBoolForKey:@"MCPusesInnoDBTables"]];
	}
	else {
		NSLog(@"For some reason, unable to decode MCPModel from the coder!!!");
	}
//	NSLog(@"MAKING a new object : %@", self);
	return self;
}

- (void) encodeWithCoder:(NSCoder *) encoder
{
	if (! [encoder allowsKeyedCoding]) {
		NSLog(@"In MCPModel -encodeWithCoder : Unable to encode to a non-keyed encoder!!, will not perform encoding!!");
		return;
	}
//   [super encodeWithCoder:encoder];
//   NSLog(@"in MCPModel encodeWithCoder, model = %@ (pointer = %p)", self, self);
	[encoder encodeObject:[self name] forKey:@"MCPname"];
	[encoder encodeObject:[self classDescriptions] forKey:@"MCPclassDescriptions"];
	[encoder encodeBool:[self usesInnoDBTables] forKey:@"MCPusesInnoDBTables"];
	[encoder encodeObject:@"1.1.1" forKey:@"MCPversion"];
	return;
}

#pragma mark Making new class description
- (MCPClassDescription *) addNewClassDescriptionWithName:(NSString *) iName inPosition:(int) index;
{
	MCPClassDescription		*theClassDescription = [[MCPClassDescription alloc] initInModel:self withName:iName];
	
//	[self addClassDescription:theClassDescription];
	[self insertObject:theClassDescription inClassDescriptionsAtIndex:(index < 0) ? ([self countOfClassDescriptions] + index + 1) : index];
	[theClassDescription release];
	return theClassDescription;
}

#pragma mark Setters
- (void) setName:(NSString *) iName
{
	if (iName != name) {
		[name release];
		name = [iName retain];
		[[NSNotificationCenter defaultCenter] postNotificationName:MCPModelChangedNotification object:self];
	}
}

- (void) setClassDescriptions:(NSArray *) iClassDescriptions
{
	if (iClassDescriptions != classDescriptions) {
		[classDescriptions release];
		classDescriptions = [[NSMutableArray alloc] initWithArray:iClassDescriptions];
		[[NSNotificationCenter defaultCenter] postNotificationName:MCPModelChangedNotification object:self];
	}
}

- (void) insertObject:(MCPClassDescription *) iClassDescription inClassDescriptionsAtIndex:(unsigned int) index
{
	[classDescriptions insertObject:iClassDescription atIndex:index];
	[[NSNotificationCenter defaultCenter] postNotificationName:MCPModelChangedNotification object:self];	
}

- (void) removeObjectFromClassDescriptionsAtIndex:(unsigned int) index
{
	[classDescriptions removeObjectAtIndex:index];
	[[NSNotificationCenter defaultCenter] postNotificationName:MCPModelChangedNotification object:self];
}

- (void) setUsesInnoDBTables:(BOOL) iUsesInnoDB
{
	usesInnoDBTables = iUsesInnoDB;
	[[NSNotificationCenter defaultCenter] postNotificationName:MCPModelChangedNotification object:self];
}


// Deprecated : non KVC
/*
- (void) removeClassDescription:(MCPClassDescription *) iClassDescription
{
	[classDescriptions removeObject:iClassDescription];
	[[NSNotificationCenter defaultCenter] postNotificationName:MCPModelChangedNotification object:self];
}

 - (void) addClassDescription:(MCPClassDescription *) iClassDescription
 {
	 [classDescriptions addObject:iClassDescription];
	 [[NSNotificationCenter defaultCenter] postNotificationName:MCPModelChangedNotification object:self];
 }
 
 */

#pragma mark Getters
- (NSString *) name
{
	return name;
//   return [NSString stringWithString:name];
}

- (NSArray *) classDescriptions
{
	return [NSArray arrayWithArray:classDescriptions];
}

- (unsigned int) countOfClassDescriptions
{
	return [classDescriptions count];
}

- (MCPClassDescription *) objectInClassDescriptionsAtIndex:(unsigned int) index
{
	return (MCPClassDescription *)((NSNotFound != index) ? [classDescriptions objectAtIndex:index] : nil);
}

- (MCPClassDescription *) classDescriptionWithClassName:(NSString *) iClassDescriptionClassName
{
// Given the implementation of isEqual: for the MCPClassDescription, one should be able to use NSArray method directly:
	/*   unsigned int      i;
	
	for (i=0; ([classDescriptions count] != i) && (! [iClassDescriptionClassName isEqualToString:[(MCPClassDescription *) [classDescriptions objectAtIndex:i] className]]); ++i ) {
	}
	return (i == [classDescriptions count]) ? nil : (MCPClassDescription *)[classDescriptions objectAtIndex:i];
	*/
	unsigned int   theIndex = [classDescriptions indexOfObject:iClassDescriptionClassName];
	return (NSNotFound == theIndex) ? nil : [classDescriptions objectAtIndex:theIndex];
}

- (unsigned int) indexOfClassDescription:(id) iClassDescription
{
	return [classDescriptions indexOfObject:iClassDescription];
}

- (BOOL) usesInnoDBTables
{
	return usesInnoDBTables;
}


// Deprecated : non KVC

#pragma mark Output for logging
- (NSString *) descriptionWithLocale:(NSDictionary *) locale
{
//	NSLog(@"Enterred in -[MCPModel descriptionWithLocale:]...");
	return [NSString stringWithFormat:@"<MCPModel with name %@ : %p>", [self name], self];
}

#pragma mark For debugging the retain counting
- (id) retain
{
	[super retain];
//	NSLog(@"in -[MCPModel retain] for %@, count is %u (after retain).", self, [self retainCount]);
	return self;
}

- (void) release
{
//	NSLog(@"in -[MCPModel release] for %@, count is %u (after release).", self, [self retainCount]-1);
	[super release];
	return;
}

@end
