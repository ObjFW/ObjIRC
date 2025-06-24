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

#import <ObjFW/OFObject.h>

OF_ASSUME_NONNULL_BEGIN

@interface IRCUser: OFObject <OFCopying>
{
	OFString *_nickname, *_username, *_hostname;
}

@property (readonly, nonatomic) OFString *nickname, *username, *hostname;

+ (instancetype)userWithString: (OFString *)string;
- (instancetype)initWithString: (OFString *)string OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
