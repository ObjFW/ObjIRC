/*
 * Copyright (c) 2010, 2011, 2012, 2013, 2016, 2017, 2018, 2021, 2024
 *   Jonathan Schleifer <js@nil.im>
 *
 * https://git.nil.im/ObjFW/ObjIRC
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

#define IRC_CONNECTION_M

#include <stdarg.h>

#import <ObjFW/ObjFW.h>

#import "IRCConnection.h"
#import "IRCUser.h"

@interface IRCConnection () <OFTCPSocketDelegate>
@end

@implementation IRCConnection
@synthesize socketClass = _socketClass;
@synthesize server = _server, port = _port;
@synthesize nickname = _nickname, username = _username, realname = _realname;
@synthesize delegate = _delegate, socket = _socket;
@synthesize fallbackEncoding = _fallbackEncoding;
@synthesize pingInterval = _pingInterval, pingTimeout = _pingTimeout;

+ (instancetype)connection
{
	return [[[self alloc] init] autorelease];
}

- (instancetype)init
{
	self = [super init];

	@try {
		_socketClass = [OFTCPSocket class];
		_channels = [[OFMutableDictionary alloc] init];
		_port = 6667;
		_fallbackEncoding = OFStringEncodingISO8859_1;
		_pingInterval = 120;
		_pingTimeout = 30;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_socket release];
	[_server release];
	[_nickname release];
	[_username release];
	[_realname release];
	[_channels release];
	[_pingData release];
	[_pingTimer release];

	[super dealloc];
}

- (void)connect
{
	void *pool = objc_autoreleasePoolPush();

	if (_socket != nil)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	_socket = [[_socketClass alloc] init];
	[_socket setDelegate: self];
	[_socket asyncConnectToHost: _server port: _port];

	objc_autoreleasePoolPop(pool);
}

-     (void)socket: (OF_KINDOF(OFTCPSocket *))socket
  didConnectToHost: (OFString *)host
	      port: (uint16_t)port
	 exception: (id)exception
{
	if (exception != nil) {
		if ([_delegate respondsToSelector:
		    @selector(connection:didFailToConnectWithException:)])
			[_delegate	       connection: self
			    didFailToConnectWithException: exception];

		return;
	}

	if ([_delegate respondsToSelector:
	    @selector(connection:didCreateSocket:)])
		[_delegate connection: self didCreateSocket: _socket];

	[self sendLineWithFormat: @"NICK %@", _nickname];
	[self sendLineWithFormat: @"USER %@ * 0 :%@", _username, _realname];

	[socket asyncReadLine];
}

- (void)disconnect
{
	[self disconnectWithReason: nil];
}

- (void)disconnectWithReason: (OFString *)reason
{
	void *pool = objc_autoreleasePoolPush();

	reason = [[reason componentsSeparatedByString: @"\n"] firstObject];

	if (reason == nil)
		[self sendLine: @"QUIT"];
	else
		[self sendLineWithFormat: @"QUIT :%@", reason];

	objc_autoreleasePoolPop(pool);
}

- (void)joinChannel: (OFString *)channel
{
	void *pool = objc_autoreleasePoolPush();

	channel = [channel componentsSeparatedByString: @"\n"].firstObject;

	[self sendLineWithFormat: @"JOIN %@", channel];

	objc_autoreleasePoolPop(pool);
}

- (void)leaveChannel: (OFString *)channel
{
	[self leaveChannel: channel reason: nil];
}

- (void)leaveChannel: (OFString *)channel reason: (OFString *)reason
{
	void *pool = objc_autoreleasePoolPush();

	channel = [channel componentsSeparatedByString: @"\n"].firstObject;
	reason = [reason componentsSeparatedByString: @"\n"].firstObject;

	if (reason == nil)
		[self sendLineWithFormat: @"PART %@", channel];
	else
		[self sendLineWithFormat: @"PART %@ :%@", channel, reason];

	[_channels removeObjectForKey: channel];

	objc_autoreleasePoolPop(pool);
}

- (void)sendLine: (OFString *)line
{
	if ([_delegate respondsToSelector: @selector(connection:didSendLine:)])
		[_delegate connection: self didSendLine: line];

	[_socket writeLine: line];
}

- (void)sendLineWithFormat: (OFConstantString *)format, ...
{
	void *pool = objc_autoreleasePoolPush();
	OFString *line;
	va_list args;

	va_start(args, format);
	line = [[[OFString alloc] initWithFormat: format
				       arguments: args] autorelease];
	va_end(args);

	[self sendLine: line];

	objc_autoreleasePoolPop(pool);
}

- (void)sendMessage: (OFString *)message to: (OFString *)to
{
	void *pool = objc_autoreleasePoolPush();

	for (OFString *line in [message componentsSeparatedByString: @"\n"])
		[self sendLineWithFormat: @"PRIVMSG %@ :%@", to, line];

	objc_autoreleasePoolPop(pool);
}

- (void)sendNotice: (OFString *)notice to: (OFString *)to
{
	void *pool = objc_autoreleasePoolPush();

	for (OFString *line in [notice componentsSeparatedByString: @"\n"])
		[self sendLineWithFormat: @"NOTICE %@ :%@", to, line];

	objc_autoreleasePoolPop(pool);
}

- (void)kickUser: (OFString *)user
	 channel: (OFString *)channel
	  reason: (OFString *)reason
{
	void *pool = objc_autoreleasePoolPush();

	reason = [[reason componentsSeparatedByString: @"\n"] firstObject];

	[self sendLineWithFormat: @"KICK %@ %@ :%@", channel, user, reason];

	objc_autoreleasePoolPop(pool);
}

- (void)changeNicknameTo: (OFString *)nickname
{
	void *pool = objc_autoreleasePoolPush();

	nickname = [nickname componentsSeparatedByString: @"\n"].firstObject;

	[self sendLineWithFormat: @"NICK %@", nickname];

	objc_autoreleasePoolPop(pool);
}

- (void)irc_processLine: (OFString *)line
{
	OFArray *components;
	OFString *action = nil;

	if ([_delegate respondsToSelector:
	    @selector(connection:didReceiveLine:)])
		[_delegate connection: self didReceiveLine: line];

	components = [line componentsSeparatedByString: @" "];

	/* PING */
	if (components.count == 2 &&
	    [components.firstObject isEqual: @"PING"]) {
		OFMutableString *s = [[line mutableCopy] autorelease];
		[s replaceCharactersInRange: OFMakeRange(0, 4)
				 withString: @"PONG"];
		[self sendLine: s];

		return;
	}

	/* PONG */
	if (components.count == 4 &&
	    [[components objectAtIndex: 1] isEqual: @"PONG"] &&
	    [[components objectAtIndex: 3] isEqual: _pingData]) {
		[_pingTimer invalidate];

		[_pingData release];
		[_pingTimer release];

		_pingData = nil;
		_pingTimer = nil;
	}

	action = [[components objectAtIndex: 1] uppercaseString];

	/* Connected */
	if ([action isEqual: @"001"] && components.count >= 4) {
		if ([_delegate respondsToSelector:
		    @selector(connectionWasEstablished:)])
			[_delegate connectionWasEstablished: self];

		[OFTimer scheduledTimerWithTimeInterval: _pingInterval
						 target: self
					       selector: @selector(irc_sendPing)
						repeats: true];

		return;
	}

	/* JOIN */
	if ([action isEqual: @"JOIN"] && components.count == 3) {
		OFString *who = [components objectAtIndex: 0];
		OFString *where = [components objectAtIndex: 2];
		IRCUser *user;
		OFMutableSet *channel;

		who = [who substringFromIndex: 1];
		user = [IRCUser userWithString: who];

		if ([who hasPrefix:
		    [_nickname stringByAppendingString: @"!"]]) {
			channel = [OFMutableSet set];
			[_channels setObject: channel forKey: where];
		} else
			channel = [_channels objectForKey: where];

		[channel addObject: user.nickname];

		if ([_delegate respondsToSelector:
		    @selector(connection:didSeeUser:joinChannel:)])
			[_delegate connection: self
				   didSeeUser: user
				  joinChannel: where];

		return;
	}

	/* NAMES reply */
	if ([action isEqual: @"353"] && components.count >= 6) {
		OFString *where;
		OFMutableSet *channel;
		OFArray *users;
		size_t pos;

		where = [components objectAtIndex: 4];

		if ((channel = [_channels objectForKey: where]) == nil) {
			/* We did not request that */
			return;
		}

		pos = [[components objectAtIndex: 0] length] +
		    [[components objectAtIndex: 1] length] +
		    [[components objectAtIndex: 2] length] +
		    [[components objectAtIndex: 3] length] +
		    [[components objectAtIndex: 4] length] + 6;

		users = [[line substringWithRange:
		    OFMakeRange(pos, line.length - pos)]
		    componentsSeparatedByString: @" "];

		for (OFString *user in users) {
			if ([user hasPrefix: @"@"] || [user hasPrefix: @"+"] ||
			    [user hasPrefix: @"%"] || [user hasPrefix: @"*"])
				user = [user substringFromIndex: 1];

			[channel addObject: user];
		}

		if ([_delegate respondsToSelector:
		    @selector(connection:didReceiveNamesForChannel:)])
			[_delegate	   connection: self
			    didReceiveNamesForChannel: where];

		return;
	}

	/* PART */
	if ([action isEqual: @"PART"] && [components count] >= 3) {
		OFString *who = [components objectAtIndex: 0];
		OFString *where = [components objectAtIndex: 2];
		IRCUser *user;
		OFMutableSet *channel;
		OFString *reason = nil;
		size_t pos = who.length + 1 +
		    [[components objectAtIndex: 1] length] + 1 + where.length;

		who = [who substringFromIndex: 1];
		user = [IRCUser userWithString: who];
		channel = [_channels objectForKey: where];

		if (components.count > 3)
			reason = [line substringFromIndex: pos + 2];

		[channel removeObject: user.nickname];

		if ([_delegate respondsToSelector:
		    @selector(connection:didSeeUser:leaveChannel:reason:)])
			[_delegate connection: self
				   didSeeUser: user
				 leaveChannel: where
				       reason: reason];

		return;
	}

	/* KICK */
	if ([action isEqual: @"KICK"] && components.count >= 4) {
		OFString *who = [components objectAtIndex: 0];
		OFString *where = [components objectAtIndex: 2];
		OFString *whom = [components objectAtIndex: 3];
		IRCUser *user;
		OFMutableSet *channel;
		OFString *reason = nil;
		size_t pos = who.length + 1 +
		    [[components objectAtIndex: 1] length] + 1 +
		    where.length + 1 + whom.length;

		who = [who substringFromIndex: 1];
		user = [IRCUser userWithString: who];
		channel = [_channels objectForKey: where];

		if (components.count > 4)
			reason = [line substringFromIndex: pos + 2];

		[channel removeObject: user.nickname];

		if ([_delegate respondsToSelector:
		    @selector(connection:didSeeUser:kickUser:channel:reason:)])
			[_delegate connection: self
				   didSeeUser: user
				     kickUser: whom
				      channel: where
				       reason: reason];

		return;
	}

	/* QUIT */
	if ([action isEqual: @"QUIT"] && components.count >= 2) {
		OFString *who = [components objectAtIndex: 0];
		IRCUser *user;
		OFString *reason = nil;
		size_t pos = who.length + 1 +
		    [[components objectAtIndex: 1] length];

		who = [who substringFromIndex: 1];
		user = [IRCUser userWithString: who];

		if ([components count] > 2)
			reason = [line substringFromIndex: pos + 2];

		for (OFString *channel in _channels)
			[[_channels objectForKey: channel]
			    removeObject: user.nickname];

		if ([_delegate respondsToSelector:
		    @selector(connection:didSeeUserQuit:reason:)])
			[_delegate connection: self
			       didSeeUserQuit: user
				       reason: reason];

		return;
	}

	/* NICK */
	if ([action isEqual: @"NICK"] && components.count == 3) {
		OFString *who = [components objectAtIndex: 0];
		OFString *nickname = [components objectAtIndex: 2];
		IRCUser *user;

		who = [who substringFromIndex: 1];
		nickname = [nickname substringFromIndex: 1];

		user = [IRCUser userWithString: who];

		if ([user.nickname isEqual: _nickname]) {
			[_nickname release];
			_nickname = [nickname copy];
		}

		for (OFMutableSet *channel in _channels) {
			if ([channel containsObject: user.nickname]) {
				[channel removeObject: user.nickname];
				[channel addObject: nickname];
			}
		}

		if ([_delegate respondsToSelector:
		    @selector(connection:didSeeUser:changeNicknameTo:)])
			[_delegate connection: self
				   didSeeUser: user
			     changeNicknameTo: nickname];

		return;
	}

	/* PRIVMSG */
	if ([action isEqual: @"PRIVMSG"] && components.count >= 4) {
		OFString *from = [components objectAtIndex: 0];
		OFString *to = [components objectAtIndex: 2];
		IRCUser *user;
		OFString *message;
		size_t pos = from.length + 1 +
		    [[components objectAtIndex: 1] length] + 1 + to.length;

		from = [from substringFromIndex: 1];
		message = [line substringFromIndex: pos + 2];
		user = [IRCUser userWithString: from];

		if (![to isEqual: _nickname]) {
			if ([_delegate respondsToSelector: @selector(connection:
			    didReceiveMessage:channel:user:)])
				[_delegate connection: self
				    didReceiveMessage: message
					      channel: to
						 user: user];
		} else {
			if ([_delegate respondsToSelector: @selector(connection:
			    didReceivePrivateMessage:user:)])
				[_delegate	  connection: self
				    didReceivePrivateMessage: message
							user: user];
		}

		return;
	}

	/* NOTICE */
	if ([action isEqual: @"NOTICE"] && components.count >= 4) {
		OFString *from = [components objectAtIndex: 0];
		OFString *to = [components objectAtIndex: 2];
		IRCUser *user = nil;
		OFString *notice;
		size_t pos = from.length + 1 +
		    [[components objectAtIndex: 1] length] + 1 + to.length;

		from = [from substringFromIndex: 1];
		notice = [line substringFromIndex: pos + 2];

		if (![from containsString: @"!"] || [to isEqual: @"*"]) {
			/* System message - ignore for now */
			return;
		}

		user = [IRCUser userWithString: from];

		if (![to isEqual: _nickname]) {
			if ([_delegate respondsToSelector: @selector(connection:
			    didReceiveNotice:channel:user:)])
				[_delegate connection: self
				     didReceiveNotice: notice
					      channel: to
						 user: user];
		} else {
			if ([_delegate respondsToSelector:
			    @selector(connection:didReceiveNotice:user:)])
				[_delegate connection: self
				     didReceiveNotice: notice
						 user: user];
		}

		return;
	}
}

- (void)irc_sendPing
{
	[_pingData release];
	[_pingTimer release];
	_pingData = nil;
	_pingTimer = nil;

	_pingData = [[OFString alloc] initWithFormat: @":%d", rand()];
	[_socket writeFormat: @"PING %@\r\n", _pingData];

	_pingTimer = [[OFTimer
	    scheduledTimerWithTimeInterval: _pingTimeout
				    target: self
				  selector: @selector(irc_pingTimeout)
				   repeats: false] retain];
}

- (void)irc_pingTimeout
{
	if ([_delegate respondsToSelector: @selector(connectionWasClosed:)])
		[_delegate connectionWasClosed: self];

	[_socket cancelAsyncRequests];
	[_socket release];
	_socket = nil;
}

- (bool)stream: (OF_KINDOF(OFStream *))stream
   didReadLine: (OFString *)line
     exception: (OFException *)exception
{
	if (line != nil) {
		[self irc_processLine: line];

		if (_fallbackEncodingUsed) {
			_fallbackEncodingUsed = false;
			[stream asyncReadLine];
			return false;
		}

		return true;
	}

	if ([exception isKindOfClass: [OFInvalidEncodingException class]]) {
		_fallbackEncodingUsed = true;
		[stream asyncReadLineWithEncoding: _fallbackEncoding];
		return false;
	}

	if ([_delegate respondsToSelector: @selector(connectionWasClosed:)])
		[_delegate connectionWasClosed: self];

	[_pingTimer invalidate];

	[_socket performSelector: @selector(cancelAsyncRequests) afterDelay: 0];
	[_socket release];
	_socket = nil;

	return false;
}

- (OFSet OF_GENERIC(OFString *) *)usersInChannel: (OFString *)channel
{
	return [[[_channels objectForKey: channel] copy] autorelease];
}
@end
