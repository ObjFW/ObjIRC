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

#import <ObjFW/ObjFW.h>

OF_ASSUME_NONNULL_BEGIN

@class IRCConnection;
@class IRCUser;

@protocol IRCConnectionDelegate <OFObject>
@optional
- (void)connection: (IRCConnection *)connection
   didCreateSocket: (OF_KINDOF(OFTCPSocket *))socket;
- (void)connection: (IRCConnection *)connection
    didReceiveLine: (OFString *)line;
- (void)connection: (IRCConnection *)connection didSendLine: (OFString *)line;
- (void)connectionWasEstablished: (IRCConnection *)connection;
-	       (void)connection: (IRCConnection *)connection
  didFailToConnectWithException: (id)exception;
- (void)connection: (IRCConnection *)connection
	didSeeUser: (IRCUser *)user
       joinChannel: (OFString *)channel;
- (void)connection: (IRCConnection *)connection
	didSeeUser: (IRCUser *)user
      leaveChannel: (OFString *)channel
	    reason: (nullable OFString *)reason;
- (void)connection: (IRCConnection *)connection
        didSeeUser: (IRCUser *)user
  changeNicknameTo: (OFString *)nickname;
- (void)connection: (IRCConnection *)connection
	didSeeUser: (IRCUser *)user
	  kickUser: (OFString *)kickedUser
	   channel: (OFString *)channel
	    reason: (nullable OFString *)reason;
- (void)connection: (IRCConnection *)connection
    didSeeUserQuit: (IRCUser *)user
	    reason: (nullable OFString *)reason;
-  (void)connection: (IRCConnection *)connection
  didReceiveMessage: (OFString *)msg
	    channel: (OFString *)channel
	       user: (IRCUser *)user;
-	  (void)connection: (IRCConnection *)connection
  didReceivePrivateMessage: (OFString *)msg
		      user: (IRCUser *)user;
- (void)connection: (IRCConnection *)connection
  didReceiveNotice: (OFString *)notice
	      user: (IRCUser *)user;
- (void)connection: (IRCConnection *)connection
  didReceiveNotice: (OFString *)notice
	   channel: (OFString *)channel
	      user: (IRCUser *)user;
-	   (void)connection: (IRCConnection *)connection
  didReceiveNamesForChannel: (OFString *)channel;
- (void)connectionWasClosed: (IRCConnection *)connection;
@end

@interface IRCConnection: OFObject
{
	Class _socketClass;
	OF_KINDOF(OFTCPSocket *) _Nullable _socket;
	OFString *_Nullable _server;
	uint16_t _port;
	OFString *_Nullable _nickname, *_Nullable _username;
	OFString *_Nullable _realname;
	OFMutableDictionary OF_GENERIC(OFString *, OFMutableSet *) *_channels;
	id <IRCConnectionDelegate> _Nullable _delegate;
	OFStringEncoding _fallbackEncoding;
	OFTimeInterval _pingInterval, _pingTimeout;
	OFString *_Nullable _pingData;
	OFTimer *_Nullable _pingTimer;
	bool _fallbackEncodingUsed;
}

@property (readonly, nonatomic) Class socketClass;
@property OF_NULLABLE_PROPERTY (copy, nonatomic) OFString *server;
@property (nonatomic) uint16_t port;
@property OF_NULLABLE_PROPERTY (copy, nonatomic)
    OFString *nickname, *username, *realname;
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <IRCConnectionDelegate> delegate;
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    OF_KINDOF(OFTCPSocket *) socket;
@property (nonatomic) OFStringEncoding fallbackEncoding;
@property (nonatomic) OFTimeInterval pingInterval, pingTimeout;

+ (instancetype)connection;
- (void)sendLine: (OFString *)line;
- (void)sendLineWithFormat: (OFConstantString *)line, ...;
- (void)connect;
- (void)disconnect;
- (void)disconnectWithReason: (nullable OFString *)reason;
- (void)joinChannel: (OFString *)channelName;
- (void)leaveChannel: (OFString *)channel;
- (void)leaveChannel: (OFString *)channel reason: (nullable OFString *)reason;
- (void)sendMessage: (OFString *)message to: (OFString *)to;
- (void)sendNotice: (OFString *)notice to: (OFString *)to;
- (void)kickUser: (OFString *)user
	 channel: (OFString *)channel
	  reason: (nullable OFString *)reason;
- (void)changeNicknameTo: (OFString *)nickname;
- (nullable OFSet OF_GENERIC(OFString *) *)usersInChannel: (OFString *)channel;
@end

OF_ASSUME_NONNULL_END
