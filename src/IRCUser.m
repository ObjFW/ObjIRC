/*
 * Copyright (c) 2010, 2011, 2012, 2013, 2016, 2017, 2018, 2021, 2024
 *   Jonathan Schleifer <js@nil.im>
 *
 * https://fl.nil.im/objirc
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND ISC DISCLAIMS ALL WARRANTIES WITH
 * REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS.  IN NO EVENT SHALL ISC BE LIABLE FOR ANY SPECIAL, DIRECT,
 * INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
 * LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
 * OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 */

#include <stdlib.h>
#include <string.h>

#import <ObjFW/OFString.h>

#import <ObjFW/OFInvalidFormatException.h>
#import <ObjFW/OFOutOfMemoryException.h>

#import <ObjFW/macros.h>

#import "IRCUser.h"

@implementation IRCUser
@synthesize username = _username, nickname = _nickname, hostname = _hostname;

+ (instancetype)userWithString: (OFString *)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

- (instancetype)initWithString: (OFString *)string
{
	self = [super init];

	@try {
		size_t pos;

		pos = [string rangeOfString: @"@"].location;
		if (pos == OFNotFound)
			@throw [OFInvalidFormatException exception];

		_hostname = [[string substringFromIndex: pos + 1] copy];

		string = [string substringToIndex: pos];

		pos = [string rangeOfString: @"!"].location;
		if (pos == OFNotFound)
			@throw [OFInvalidFormatException exception];

		_username = [[string substringFromIndex: pos + 1] copy];
		_nickname = [[string substringToIndex: pos] copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_nickname release];
	[_username release];
	[_hostname release];

	[super dealloc];
}

- (id)copy
{
	return [self retain];
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"%@!%@@%@",
					   _nickname, _username, _hostname];
}
@end
