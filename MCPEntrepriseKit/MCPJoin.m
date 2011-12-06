//
//  MCPJoin.m
//  MCPModeler
//
//  Created by Serge Cohen (serge.cohen@m4x.org) on 18/08/04.
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

#import "MCPJoin.h"


#import "MCPModel.h"
#import "MCPClassDescription.h"
#import "MCPAttribute.h"
#import "MCPRelation.h"
#import "MCPRelation.h"


@implementation MCPJoin

#pragma mark Class methods
+ (void) initialize
{
	if (self = [MCPJoin class]) {
		[self setVersion:010101]; // Ma.Mi.Re -> MaMiRe
	}
	return;
}


#pragma mark Life cycle
- (id) initForRelation:(MCPRelation *) iRelation from:(MCPAttribute *) iOrigin to:(MCPAttribute *) iDestination;
{
	self = [super init];
	if (self) {
		relation = iRelation;
		[self setOrigin:iOrigin];
		[self setDestination:iDestination];
//		NSLog(@"MAKING a new object : %@", self);
	}
	return self;
}

- (void) invalidate
{
	[self retain];
	NSLog(@"Enterring -[MCPJoin invalidate], retain count is %u (after retaining : should be 4)", [self retainCount]);
	[origin removeObjectFromJoinsAtIndex:[origin indexOfJoinIdenticalTo:self]];
	[destination removeObjectFromJoinsAtIndex:[destination indexOfJoinIdenticalTo:self]];
	[relation removeObjectFromJoinsAtIndex:[relation indexOfJoinIdenticalTo:self]];
	NSLog(@"Enterring -[MCPJoin invalidate], retain count is %u (before releasing : should be 1)", [self retainCount]);
	[self release];
	return;
}

- (void) dealloc
{
// Nothing to release, because the attributes are NOT retained.
//	NSLog(@"DEALLOCATING object : %@", self);
	[super dealloc];
}

#pragma mark NSCoding protocol
- (id) initWithCoder:(NSCoder *) decoder
{
//	NSLog(@"MAKING a new object : %@", self);
	self = [super init];
	if ((self) && ([decoder allowsKeyedCoding])) {
		relation = [decoder decodeObjectForKey:@"MCPrelation"];
		[self setOrigin:[decoder decodeObjectForKey:@"MCPorigin"]];
		[self setDestination:[decoder decodeObjectForKey:@"MCPdestination"]];
	}
	else {
		NSLog(@"For some reason, unable to decode MCPJoin from the coder!!!");
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *) encoder
{
	if (! [encoder allowsKeyedCoding]) {
		NSLog(@"In MCPJoin -encodeWithCoder : Unable to encode to a non-keyed encoder!!, will not perform encoding!!");
		return;
	}
	[encoder encodeObject:[self relation] forKey:@"MCPrelation"];
	[encoder encodeObject:[self origin] forKey:@"MCPorigin"];
	[encoder encodeObject:[self destination] forKey:@"MCPdestination"];
}

#pragma mark Setters
- (void) setOrigin:(MCPAttribute *) iOrigin
{
	if (origin != iOrigin) {
		if (origin) {
			[origin removeObjectFromJoinsAtIndex:[origin indexOfJoinIdenticalTo:self]];
		}
		origin = iOrigin;
		if (origin) {
			[origin insertObject:self inJoinsAtIndex:[origin countOfJoins]];
		}
	}
}

- (void) setDestination:(MCPAttribute *) iDestination
{
	if (destination != iDestination) {
		if (destination) {
			[destination removeObjectFromJoinsAtIndex:[destination indexOfJoinIdenticalTo:self]];
		}
		destination = iDestination;
		if (destination) {
			[destination insertObject:self inJoinsAtIndex:[destination countOfJoins]];
		}
	}
}

#pragma mark Getters
- (MCPRelation *) relation
{
	return relation;
}

- (MCPAttribute *) origin
{
	return origin;
}

- (MCPAttribute *) destination
{
	return destination;
}

- (unsigned int) index
{
	return [relation indexOfJoinIdenticalTo:self];
}

#pragma mark Some general methods:
- (BOOL) isEqual:(id) iObject
{
	if ([iObject isKindOfClass:[MCPJoin class]]) {
		MCPJoin				*theJoin = (MCPJoin *)iObject;
		
		return ([relation isEqual:[theJoin relation]]) && ([origin isEqual:[theJoin origin]]) && ([destination isEqual:[theJoin destination]]);
	}
	if ([iObject isKindOfClass:[NSDictionary class]]) {
		NSDictionary		*theDict = (NSDictionary *)iObject;
		
		return ([relation isEqual:[theDict valueForKey:@"relation"]]) && ([origin isEqual:[theDict valueForKey:@"origin"]]) && ([destination isEqual:[theDict valueForKey:@"destination"]]);
	}
	return NO;
}

#pragma mark For debugging the retain counting
- (id) retain
{
	[super retain];
//	NSLog(@"in -[MCPJoin retain] for %@, count is %u (after retain).", self, [self retainCount]);
	return self;
}

- (void) release
{
//	NSLog(@"in -[MCPJoin release] for %@, count is %u (after release).", self, [self retainCount]-1);
	[super release];
	return;
}

@end
