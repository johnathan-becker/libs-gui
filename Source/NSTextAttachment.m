/** <title>NSTextAttachment</title>

   <abstract>Classes to represent text attachments.</abstract>
   
   NSTextAttachment is used to represent text attachments. When inline, 
   text attachments appear as the value of the NSAttachmentAttributeName 
   attached to the special character NSAttachmentCharacter.
   
   NSTextAttachment uses an object obeying the NSTextAttachmentCell 
   protocol to get input from the user and to display an image.

   NSTextAttachmentCell is a simple subclass of NSCell which provides 
   the NSTextAttachment protocol.

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: June 2000
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#include <Foundation/Foundation.h>
#include <AppKit/NSCell.h>
#include <AppKit/NSFileWrapper.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSTextContainer.h>
#include <AppKit/NSTextAttachment.h>


@implementation NSTextAttachmentCell

- (void)drawWithFrame:(NSRect)cellFrame 
	       inView:(NSView *)controlView 
       characterIndex:(unsigned)charIndex
{
  [self drawWithFrame: cellFrame 
	inView: controlView];
}

- (void)drawWithFrame:(NSRect)cellFrame 
	       inView:(NSView *)controlView 
       characterIndex:(unsigned)charIndex
	layoutManager:(NSLayoutManager *)layoutManager
{
  [self drawWithFrame: cellFrame 
	inView: controlView
	characterIndex: charIndex];
}

- (NSPoint)cellBaselineOffset
{
  return NSZeroPoint;
}

- (NSRect)cellFrameForTextContainer:(NSTextContainer *)textContainer 
	       proposedLineFragment:(NSRect)lineFrag
		      glyphPosition:(NSPoint)position 
		     characterIndex:(unsigned)charIndex
{
  NSRect aRect;
  
  // FIXME: We ignore the proposedLineFragment
  aRect.origin = position;
  aRect.size = [self cellSize];
  return aRect;
}

- (BOOL)wantsToTrackMouse
{
  return YES;
}

- (BOOL)wantsToTrackMouseForEvent:(NSEvent *)theEvent 
			   inRect:(NSRect)cellFrame 
			   ofView:(NSView *)controlView
		 atCharacterIndex:(unsigned)charIndex
{
  return [self wantsToTrackMouse];
}

- (BOOL)trackMouse:(NSEvent *)theEvent 
	    inRect:(NSRect)cellFrame 
	    ofView:(NSView *)controlView 
      untilMouseUp:(BOOL)flag
{
  if ([controlView respondsToSelector: @selector(delegate)])
    {
      NSTextView *textView = (NSTextView*)controlView;
      id delegate = [textView delegate];
      NSEventType type = [theEvent type];
      
      if (type == NSLeftMouseUp)
        {
	  if ([theEvent clickCount] == 2)
	    {
	      if (delegate != nil && 
		  [delegate respondsToSelector: 
				@selector(textView:doubleClickedOnCell:inRect:)])
	        {
		  [delegate textView: textView 
			    doubleClickedOnCell: self 
			    inRect: cellFrame];
		  return YES;
		}
	    }
	  else
	    {
	      if (delegate != nil && 
		  [delegate respondsToSelector: 
				@selector(textView:clickedOnCell:inRect:)])
	        {
		  [delegate textView: textView 
			    clickedOnCell: self 
			    inRect: cellFrame];
		  return YES;
		}
	    }
	}
      else if (type == NSLeftMouseDragged)
        {
	  if (delegate != nil && 
	      [delegate respondsToSelector: 
			    @selector(textView:draggedCell:inRect:event:)])
	    {
	      [delegate textView: textView 
			draggedCell: self 
			inRect: cellFrame
			event: theEvent];
	      return YES;
	    }
	}
    }
     
  return [super trackMouse: theEvent 
		inRect: cellFrame 
		ofView: controlView 
		untilMouseUp: flag];
}

- (BOOL)trackMouse:(NSEvent *)theEvent 
	    inRect:(NSRect)cellFrame 
	    ofView:(NSView *)controlView
  atCharacterIndex:(unsigned)charIndex 
      untilMouseUp:(BOOL)flag
{
  if ([controlView respondsToSelector: @selector(delegate)])
    {
      NSTextView *textView = (NSTextView*)controlView;
      id delegate = [textView delegate];
      NSEventType type = [theEvent type];
      
      if (type == NSLeftMouseDown)
        { 
	  if ([theEvent clickCount] == 2)
	    {
	      if (delegate != nil && 
		  [delegate respondsToSelector: 
				@selector(textView:doubleClickedOnCell:inRect:atIndex:)])
	        {
		  [delegate textView: textView 
			    doubleClickedOnCell: self 
			    inRect: cellFrame
			    atIndex: charIndex];
		  return YES;
		}
	    }
	  else
	    {
	      if (delegate != nil && 
		  [delegate respondsToSelector: 
				@selector(textView:clickedOnCell:inRect:atIndex:)])
	        {
		  [delegate textView: textView 
			    clickedOnCell: self 
			    inRect: cellFrame
			    atIndex: charIndex];
		  return YES;
		}
	    }
	}
      else if (type == NSLeftMouseDragged)
        {
	  if (delegate != nil && 
	      [delegate respondsToSelector: 
			    @selector(textView:draggedCell:inRect:event:atIndex:)])
	    {
	      [delegate textView: textView 
			draggedCell: self 
			inRect: cellFrame
			event: theEvent
			atIndex: charIndex];
	      return YES;
	    }
	}
    }
  
  return [self trackMouse: theEvent 
	       inRect: cellFrame 
	       ofView: controlView 
	       untilMouseUp: flag];
}

- (void)setAttachment:(NSTextAttachment *)anObject
{
  NSFileWrapper *fileWrap = [anObject fileWrapper];

  // Do not retain the attachment
  _attachment = anObject;

  if (fileWrap != nil)
    {
      NSImage *icon = nil;
      NSString *fileName = [fileWrap filename];

      if (fileName != nil)
        {
	  // Try to set the image to the file wrapper content
	  icon = [[NSImage alloc] initByReferencingFile: fileName];
        }
      if (icon == nil)
	icon = [fileWrap icon];

      [self setImage: icon];
    }
}

- (NSTextAttachment *)attachment
{
  return _attachment;
}

//FIXME: I had to add those methods to keep the compiler quite. 
// This are already defined on the super class and should be taken from there.

- (NSSize)cellSize
{
  return [super cellSize];
}

- (void)highlight:(BOOL)flag 
	withFrame:(NSRect)cellFrame 
	   inView:(NSView *)controlView
{
  [super highlight: flag 
	 withFrame: cellFrame 
	 inView: controlView];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
  [super drawWithFrame: cellFrame inView: controlView];
}

@end


@implementation NSTextAttachment

- (id)init
{
  return [self initWithFileWrapper: nil];
}

- (void)dealloc
{
  DESTROY(_fileWrapper);
  DESTROY(_cell);
}

- (id)initWithFileWrapper:(NSFileWrapper *)fileWrapper
{
  ASSIGN(_fileWrapper, fileWrapper);
  _cell = [[NSTextAttachmentCell alloc ] init];
  [_cell setAttachment: self];

  return self;
}

- (void)setFileWrapper:(NSFileWrapper *)fileWrapper
{
  ASSIGN(_fileWrapper, fileWrapper);
  // Reset the cell, so it shows the new attachment
  [_cell setAttachment: self];
}

- (NSFileWrapper *)fileWrapper
{
  return _fileWrapper;
}

- (id <NSTextAttachmentCell>)attachmentCell
{
  return _cell;
}

- (void)setAttachmentCell:(id <NSTextAttachmentCell>)cell
{
  ASSIGN(_cell, cell);
  [_cell setAttachment: self];
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeObject: _fileWrapper];
  [aCoder encodeObject: _cell];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_fileWrapper];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_cell];

  // Reconnect the cell, so the cell does not have to store the attachment
  [_cell setAttachment: self];
  return self;
}

@end
