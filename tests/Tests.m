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

#import <ObjFW/OFString.h>
#import <ObjFW/OFApplication.h>
#import <ObjFW/OFFile.h>

#import "IRCConnection.h"
#import "IRCUser.h"

@interface TestApp: OFObject <OFApplicationDelegate, IRCConnectionDelegate>
@end

OF_APPLICATION_DELEGATE(TestApp)

@implementation TestApp
- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
	IRCConnection *connection = [[IRCConnection alloc] init];

	connection.server = @"irc.oftc.net";
	connection.nickname = @"ObjIRC";
	connection.username = @"ObjIRC";
	connection.realname = @"ObjIRC";
	connection.delegate = self;

	[connection connect];
}

- (void)connection: (IRCConnection*)connection didReceiveLine: (OFString*)line
{
	[OFStdErr writeFormat: @"> %@\n", line];
}

- (void)connection: (IRCConnection*)connection didSendLine: (OFString*)line
{
	[OFStdErr writeFormat: @"< %@\n", line];
}

- (void)connectionWasEstablished: (IRCConnection*)connection
{
	[connection joinChannel: @"#objfw"];
}

-	       (void)connection: (IRCConnection *)connection
  didFailToConnectWithException: (id)exception
{
	[OFStdErr writeFormat: @"Failed to connect: %@\n", exception];

	[OFApplication terminateWithStatus: 1];
}

- (void)connection: (IRCConnection*)connection
	didSeeUser: (IRCUser*)user
       joinChannel: (OFString*)channel
{
	OFLog(@"%@ joined %@.", user, channel);
}

- (void)connection: (IRCConnection*)connection
	didSeeUser: (IRCUser*)user
      leaveChannel: (OFString*)channel
	    reason: (OFString*)reason
{
	OFLog(@"%@ left %@ (%@).", user, channel, reason);
}

-    (void)connection: (IRCConnection*)connection
	   didSeeUser: (IRCUser*)user
	     kickUser: (OFString*)kickedUser
	      channel: (OFString*)channel
	       reason: (OFString*)reason
{
	OFLog(@"%@ kicked %@ from %@: %@", user, kickedUser, channel, reason);
}

- (void)connection: (IRCConnection*)connection
    didSeeUserQuit: (IRCUser*)user
	    reason: (OFString*)reason
{
	OFLog(@"%@ quit (%@).", user, reason);
}

- (void)connection: (IRCConnection*)connection
	didSeeUser: (IRCUser*)user
  changeNicknameTo: (OFString *)nickname
{
	OFLog(@"%@ changed nick to %@.", user, nickname);
}

-  (void)connection: (IRCConnection*)connection
  didReceiveMessage: (OFString*)msg
	    channel: (OFString*)channel
	       user: (IRCUser*)user
{
	OFLog(@"[%@] %@: %@", channel, [user nickname], msg);
}

-	  (void)connection: (IRCConnection*)connection
  didReceivePrivateMessage: (OFString*)msg
		      user: (IRCUser*)user
{
	OFLog(@"(%@): %@", user, msg);
}

- (void)connection: (IRCConnection*)connection
  didReceiveNotice: (OFString*)notice
	   channel: (OFString*)channel
	      user: (IRCUser*)user
{
	OFLog(@"NOTICE: [%@] %@: %@", channel, [user nickname], notice);
}

- (void)connection: (IRCConnection*)connection
  didReceiveNotice: (OFString*)notice
	      user: (IRCUser*)user
{
	OFLog(@"NOTICE: (%@): %@", user, notice);
}

-	   (void)connection: (IRCConnection*)connection
  didReceiveNamesForChannel: (OFString*)channel
{
	OFLog(@"Users in %@: %@", channel,
	    [connection usersInChannel: channel]);
}

- (void)connectionWasClosed: (IRCConnection*)connection
{
	OFLog(@"Disconnected!");

	[OFApplication terminate];
}
@end
