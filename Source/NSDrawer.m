/** <title>NSDrawer</title>

   <abstract>The drawer class</abstract>

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author: Douglas Simons <doug.simons@testplant.com>
   Date: 2009
   Author: Gregory Casamento <greg_casamento@yahoo.com>
   Date: 2006
   Author: Fred Kiefer <FredKiefer@gmx.de>
   Date: 2001
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/ 

#import <Foundation/NSCoder.h>
#import <Foundation/NSArchiver.h>
#import <Foundation/NSKeyedArchiver.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSException.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSTimer.h>
#import "AppKit/NSWindow.h"
#import "AppKit/NSBox.h"
#import "AppKit/NSView.h"
#import "AppKit/NSDrawer.h"
#import "AppKit/NSGraphics.h"
#import "AppKit/NSScreen.h"

static NSNotificationCenter *nc = nil;

@interface GSDrawerWindow : NSWindow
{
  NSWindow  *_parentWindow;
  NSWindow  *_pendingParentWindow;
  NSDrawer  *_drawer;
  id         _container;
  NSBox     *_borderBox;
  NSSize     _borderSize;
  NSTimer   *_timer;
  NSRect     _latestParentFrame;
  BOOL       _wasOpen;
  NSRectEdge _currentEdge;
}

- (NSRect) frameFromParentWindowFrameInState:(NSInteger)state;

// open/close
- (void) openOnEdge: (NSRectEdge)edge;
- (void) closeOnEdge: (NSRectEdge)edge;
- (void) closeOnEdge;
- (void) slideOpen: (BOOL)opening onEdge: (NSRectEdge)edge;
- (void) slideOpen: (BOOL)opening;
- (void) startTimer;
- (void) stopTimer;

// window/drawer properties
- (void) setParentWindow: (NSWindow *)window;
- (NSWindow *) parentWindow;
- (void) setPendingParentWindow: (NSWindow *)window;
- (NSWindow *) pendingParentWindow;
- (void) setDrawer: (NSDrawer *)drawer;
- (NSDrawer *) drawer;

// handle notifications...
- (void) handleWindowDidBecomeKey: (NSNotification *)notification;
- (void) handleWindowClose: (NSNotification *)notification;
- (void) handleWindowMiniaturize: (NSNotification *)notification;
- (void) handleWindowDeminiaturize: (NSNotification *)notification;
- (void) handleWindowMove: (NSNotification *)notification;

@end

@implementation GSDrawerWindow

+ (void) initialize
{
  if (self == [GSDrawerWindow class])
    {
      nc = [NSNotificationCenter defaultCenter];
      [self setVersion: 0];
    }
}

- (void) _configureContainer: (NSRect)contentRect
{
  NSRect rect = contentRect;
  NSSize containerContentSize;

  rect.origin.x += 1.0;
  rect.origin.y -= 5.0;
  if (_container == nil)
    {
      _container = [[NSBox alloc] initWithFrame: rect];
      [[super contentView] addSubview: _container];

      [_container setTitle: @""];
      [_container setTitlePosition: NSNoTitle];
      [_container setBorderType: NSBezelBorder];
      [_container setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
      [_container setContentViewMargins: NSMakeSize(2,2)];  
    }
  else
    {
      [_container setFrame: rect];
    }

  // determine the difference between the container's content size and the window content size
  containerContentSize = [[_container contentView] frame].size;
  _borderSize = NSMakeSize(contentRect.size.width - containerContentSize.width,
			   contentRect.size.height - containerContentSize.height);
}

- (id) initWithContentRect: (NSRect)contentRect
		 styleMask: (NSUInteger)aStyle
		   backing: (NSBackingStoreType)bufferingType
		     defer: (BOOL)flag
{
  if(NSIsEmptyRect(contentRect))
    {
      contentRect = NSMakeRect(0,0,100,100);
    }

  self = [super initWithContentRect: contentRect
			  styleMask: aStyle
			    backing: bufferingType
			      defer: flag];

  if (self != nil)
    {
      [self _configureContainer: contentRect];
    }
  
  return self;
}

- (id) container
{
  return _container;
}

- (NSRect) frameFromParentWindowFrameInState: (NSInteger)state
{
  NSRect newFrame = [_parentWindow frame];
  CGFloat totalOffset = [_drawer leadingOffset] + [_drawer trailingOffset];
  BOOL opened = (state == NSDrawerOpenState || state == NSDrawerOpeningState);
  NSSize size = [_parentWindow frame].size;
  NSRect windowContentRect = [[_parentWindow contentView] frame];
  CGFloat windowHeightWithoutTitleBar = windowContentRect.origin.y + windowContentRect.size.height;

  // FIXME: This should probably add the toolbar height too, if the window has a toolbar
  [self _configureContainer: windowContentRect];
  if (_currentEdge == NSMinXEdge) // left
    {
      if (opened)
        newFrame.size.width = [_drawer minContentSize].width + _borderSize.width;
      else
        newFrame.size.width = 16;

      newFrame.size.height = windowHeightWithoutTitleBar - totalOffset;
      newFrame.origin.y += [_drawer trailingOffset];
      if (opened)
        newFrame.origin.x -= newFrame.size.width;
    }
  else if (_currentEdge == NSMinYEdge) // bottom
    {
      if (opened)
        newFrame.size.height = [_drawer minContentSize].height + _borderSize.height;
      else
        newFrame.size.height = 16;

      newFrame.size.width -= totalOffset;
      newFrame.origin.x += [_drawer leadingOffset];
      if (opened)
        newFrame.origin.y -= newFrame.size.height;
    }
  else if (_currentEdge == NSMaxXEdge) // right
    {
      if (opened)
        newFrame.size.width = [_drawer minContentSize].width + _borderSize.width;
      else
        newFrame.size.width = 16;

      newFrame.size.height = windowHeightWithoutTitleBar - totalOffset;
      newFrame.origin.y += [_drawer trailingOffset];
      newFrame.origin.x += size.width;
      if (!opened)
        newFrame.origin.x -= newFrame.size.width;
    }
  else if (_currentEdge == NSMaxYEdge) // top
    {
      if (opened)
        newFrame.size.height = [_drawer minContentSize].height + _borderSize.height;
      else
        newFrame.size.height = 16;

      newFrame.size.width -= totalOffset;
      newFrame.origin.x += [_drawer leadingOffset];
      newFrame.origin.y += size.height; // put above the window
      if (!opened)
        newFrame.origin.y -= newFrame.size.height;
    }

  return newFrame;
}

- (BOOL) canBecomeKeyWindow
{
  return YES;
}

- (BOOL) canBecomeMainWindow
{
  return NO;
}

- (void) becomeKeyWindow
{
  [_parentWindow orderFrontRegardless]; // so clicking on the drawer will bring the parent to the front
  [super becomeKeyWindow];
}

- (void) startTimer
{
  NSTimeInterval time = 0.1;
  _timer = [NSTimer scheduledTimerWithTimeInterval: time
					    target: self
					  selector: @selector(_timedWindowReset)
					  userInfo: nil
					   repeats: YES];
}

- (void) stopTimer
{
  [_timer invalidate];
  _timer = nil;
}

- (void) orderFrontRegardless
{
  [self orderFront: self];
}

- (void) orderOut: (id)sender
{
  [super orderOut: sender];
}

// set the _borderBox to not resize during the slide,
// and attach it to the appropriate edge instead
- (void) lockBorderBoxForSliding
{
  NSUInteger resizeMask = 0;

  if (_currentEdge == NSMinXEdge) // left
    {
      resizeMask = NSViewMaxXMargin;
    }
  else if (_currentEdge == NSMinYEdge) // bottom
    {
      resizeMask = NSViewMaxYMargin;
    }
  else if (_currentEdge == NSMaxXEdge) // right
    {
      resizeMask = NSViewMinXMargin;
    }
  else if (_currentEdge == NSMaxYEdge) // top
    {
      resizeMask = NSViewMinYMargin;
    }  

  // don't resize -- just give appearance of sliding
  [_borderBox setAutoresizingMask: resizeMask]; 
}

- (void) unlockBorderBoxAfterSliding
{
  // set the _borderBox to resize again
  [_borderBox setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
}

// prepare drawer contents before sliding...
- (void) openOnEdge: (NSRectEdge)edge
{
  NSRect frame = [self frameFromParentWindowFrameInState:NSDrawerOpenState];

  _currentEdge = edge;
  [self setFrame:frame display: YES]; // make sure it's the full (open) size before locking the borderBox
  if ([_parentWindow isVisible]) // don't order front until parent window is visible
    {
      [self lockBorderBoxForSliding];
      [self slideOpen: YES onEdge: edge];
      [self orderFront: self];
      [self performSelector:@selector(unlockBorderBoxAfterSliding) withObject:nil afterDelay:0.01];
    }
  [self startTimer];
}

- (void) openOnEdge
{
  [self openOnEdge: _currentEdge];
}

- (void) closeOnEdge: (NSRectEdge)edge
{
  NSRect frame;

  [self stopTimer];
  [self lockBorderBoxForSliding];
  [self slideOpen: NO onEdge: edge];
  [self orderOut: self];

  frame = [self frameFromParentWindowFrameInState:NSDrawerOpenState];
  [self setFrame:frame display: YES]; // make sure it's the full (open) size again (offscreen) before unlocking
  [self performSelector:@selector(unlockBorderBoxAfterSliding) withObject:nil afterDelay:0.01];

  if (_pendingParentWindow != nil
    && _pendingParentWindow != _parentWindow)
    {
      [self setParentWindow: _pendingParentWindow];
      _pendingParentWindow = nil;
    }
}

- (void) closeOnEdge
{
  [self closeOnEdge: _currentEdge];
}

- (void) slideOpen: (BOOL)opening onEdge: (NSRectEdge)edge
{
  NSUInteger count = 10;
  NSRect frame = [self frameFromParentWindowFrameInState:
			    (opening?NSDrawerClosedState:NSDrawerOpenState)];
  NSRect newFrame = [self frameFromParentWindowFrameInState:
				 (opening?NSDrawerOpenState:NSDrawerClosedState)];
  NSTimeInterval slideDelay = 0.03;
  NSDate *nextStop = [NSDate dateWithTimeIntervalSinceNow:slideDelay];
  CGFloat deltaX = (newFrame.origin.x - frame.origin.x) / count;
  CGFloat deltaY = (newFrame.origin.y - frame.origin.y) / count;
  CGFloat deltaW = (newFrame.size.width - frame.size.width) / count;
  CGFloat deltaH = (newFrame.size.height - frame.size.height) / count;

  _currentEdge = edge;
  while (count--)
    {
      frame.origin.x += deltaX;
      frame.origin.y += deltaY;
      frame.size.width += deltaW;
      frame.size.height += deltaH;
      [self setFrame: frame display: YES];
      [NSThread sleepUntilDate:nextStop];
      nextStop = [nextStop addTimeInterval: slideDelay];
    }
  
  [self setFrame:newFrame display: YES];
}

- (void) slideOpen: (BOOL)opening
{
  [self slideOpen: opening onEdge: _currentEdge];
}

- (void) _resetWindowPosition
{
  if ([_parentWindow isVisible]) // don't set our frame until parent window is visible
    { 
      NSRect frame = [self frameFromParentWindowFrameInState:[_drawer state]]; 
      [self setFrame: frame display: YES];
      if (![self isVisible] && [_drawer state] != NSDrawerClosedState)
        [self orderFront:self];
    }
  if ([self isVisible] && [_parentWindow isKeyWindow]) // do our best to maintain proper window ordering
    {
      [super orderFrontRegardless];
      [_parentWindow orderFront:self];
    }
}

- (void) _timedWindowReset
{
  NSRect frame = [_parentWindow frame];
  if (!NSEqualRects(frame, _latestParentFrame))
    {
      [self _resetWindowPosition];
      _latestParentFrame = frame;
    }
}

- (void) handleWindowClose: (NSNotification *)notification
{
  [self stopTimer];
  [self close];
}

- (void) handleWindowMiniaturize: (NSNotification *)notification
{
  _wasOpen = ([_drawer state] == NSDrawerOpenState);
  if (_wasOpen)
    {
      // It would be nice to call [self closeOnEdge] here, but the parent window is already closing
      // (with animation) so it doesn't look right to slide the drawer. So we'll do this instead:
      [self stopTimer];
      [self close];
    }
}

- (void) handleWindowDeminiaturize: (NSNotification *)notification
{
  if (_wasOpen)
    {
      //[self openOnEdge]; -- this also doesn't work: see comment above
      _latestParentFrame = NSMakeRect(0,0,0,0);
      [self startTimer];
    }
}

- (void) handleWindowMove: (NSNotification *)notification
{
  [self _resetWindowPosition];
}

- (void) handleWindowDidBecomeKey: (NSNotification *)notification
{
  if([_drawer state] == NSDrawerOpenState)
    {
      [self _resetWindowPosition];
    }
}

- (void) setParentWindow: (NSWindow *)window
{
  if (_parentWindow != window)
    {
      [super setParentWindow: window];
      ASSIGN(_parentWindow, window);
      [nc removeObserver: self];

      if (_parentWindow != nil)
	{
	  [self _resetWindowPosition];

	  // add observers....
	  [nc addObserver: self
	      selector: @selector(handleWindowClose:)
	      name: NSWindowWillCloseNotification
	      object: _parentWindow];

	  [nc addObserver: self
	      selector: @selector(handleWindowMiniaturize:)
	      name: NSWindowWillMiniaturizeNotification
	      object: _parentWindow];

	  [nc addObserver: self
	      selector: @selector(handleWindowDeminiaturize:)
	      name: NSWindowDidDeminiaturizeNotification
	      object: _parentWindow];

	  [nc addObserver: self
	      selector: @selector(handleWindowMove:)
	      name: NSWindowWillMoveNotification
	      object: _parentWindow];

	  [nc addObserver: self
	      selector: @selector(handleWindowMove:)
	      name: NSWindowDidResizeNotification
	      object: _parentWindow];
	  
	  [nc addObserver: self
	      selector: @selector(handleWindowDidBecomeKey:)
	      name: NSWindowDidBecomeKeyNotification
	      object: _parentWindow];
	}
    }
}

- (NSWindow *) parentWindow
{
  return _parentWindow;
}

- (void) setPendingParentWindow: (NSWindow *)window
{
  ASSIGN(_pendingParentWindow, window);
}

- (NSWindow *) pendingParentWindow
{
  return _pendingParentWindow;
}

- (void) setDrawer: (NSDrawer *)drawer
{
  // don't retain, since the drawer retains us...
  _drawer = drawer;
}

- (NSDrawer *) drawer
{
  return _drawer;
}

- (void) dealloc
{
  [self stopTimer];
  RELEASE(_parentWindow);
  RELEASE(_borderBox);
  TEST_RELEASE(_pendingParentWindow);
  [super dealloc];
}
@end

@implementation NSDrawer

+ (void) initialize
{
  if (self == [NSDrawer class])
    {
      nc = [NSNotificationCenter defaultCenter];
      [self setVersion: 0];
    }
}

// Creation
- (id) init
{
  return [self initWithContentSize: NSMakeSize(100,100)
	       preferredEdge: NSMinXEdge];
}

- (id) initWithContentSize: (NSSize)contentSize 
	     preferredEdge: (NSRectEdge)edge
{  
  self = [super init];

  if (self != nil)
    {
        NSRect rect = NSMakeRect(0, 0, contentSize.width, contentSize.height);

	// initialize the drawer window...  
	_drawerWindow =  [[GSDrawerWindow alloc] 
			     initWithContentRect: rect
				       styleMask: 0
					 backing: NSBackingStoreBuffered
					   defer: NO];
	[_drawerWindow setDrawer: self];
	[_drawerWindow setReleasedWhenClosed: NO];
	
	_preferredEdge = edge;
	_currentEdge = edge;
	_maxContentSize = NSMakeSize(200,200);
	_minContentSize = contentSize;
	
	// for side drawers, top of drawer is immediately below the title bar
	if (edge == NSMinXEdge || edge == NSMaxXEdge)
	  {
	    _leadingOffset = 0.0;
	    _trailingOffset = 10.0;
	  }
	else
	  { 
	    _leadingOffset = 10.0;
	    _trailingOffset = 10.0;
	  }
	_state = NSDrawerClosedState;
    }
  
  return self;
}

- (void) dealloc
{
  RELEASE(_drawerWindow);
  if (_delegate != nil)
    {
      [nc removeObserver: _delegate name: nil object: self];
      _delegate = nil;
    }
  [super dealloc];
}

// Opening and Closing
- (NSRectEdge) _computeEdge
{
  NSRectEdge result = _preferredEdge;
  NSRect windowFrame = [[self parentWindow] frame];
  NSRect screenRect = [[NSScreen mainScreen] frame];
  NSSize contentSize = [self contentSize];
  
  // Diffs,,,
  CGFloat top = screenRect.size.height - (windowFrame.origin.y + windowFrame.size.height);
  CGFloat bottom = windowFrame.origin.y;
  CGFloat right = screenRect.size.width - (windowFrame.origin.x + windowFrame.size.width);
  CGFloat left = windowFrame.origin.x;

  // Space left...
  CGFloat topSpace = top - contentSize.height;
  CGFloat bottomSpace = bottom - contentSize.height;
  CGFloat rightSpace = right - contentSize.width;
  CGFloat leftSpace = left - contentSize.width;
  
  switch (_preferredEdge)
    {
    case NSMinXEdge:
      if (leftSpace < 0.0 && rightSpace > leftSpace)
	{
	  result = NSMaxXEdge;
	}
      break;
      
    case NSMinYEdge:
      if (bottomSpace < 0.0 && topSpace > bottomSpace)
	{
	  result = NSMaxYEdge;
	}
      break;
      
    case NSMaxXEdge:
      if (rightSpace < 0.0 && leftSpace > rightSpace)
	{
	  result = NSMinXEdge;
	}
      break;
      
    case NSMaxYEdge:
      if (topSpace < 0.0 && bottomSpace > topSpace)
	{
	  result = NSMinYEdge;
	}
      break;
    }

  return result;
}

- (void) close
{
  if (_state != NSDrawerOpenState)
    return;

  if ((_delegate != nil)
    && ([_delegate respondsToSelector: @selector(drawerShouldClose:)])
    && ![_delegate drawerShouldClose: self])
    return;

  _state = NSDrawerClosingState;
  [nc postNotificationName: NSDrawerWillCloseNotification object: self];

  [_drawerWindow closeOnEdge];

  _state = NSDrawerClosedState;
  [nc postNotificationName: NSDrawerDidCloseNotification object: self];
}

- (void) close: (id)sender
{
  [self close];
}

- (void) open
{
  NSRectEdge edge = [self _computeEdge];
  [self openOnEdge: edge];
}

- (void) open: (id)sender
{
  [self open];
}

- (void) openOnEdge: (NSRectEdge)edge
{
  if ((_state != NSDrawerClosedState)
    || ([self parentWindow] == nil))
    return;

  if ((_delegate != nil)
    && ([_delegate respondsToSelector: @selector(drawerShouldOpen:)])
    && ![_delegate drawerShouldOpen: self])
    return;

  _state = NSDrawerOpeningState;
  [nc postNotificationName: NSDrawerWillOpenNotification object: self];

  _currentEdge = edge;
  [_drawerWindow openOnEdge: edge]; 
  
  _state = NSDrawerOpenState;
  [nc postNotificationName: NSDrawerDidOpenNotification object: self];
}

- (void) toggle: (id)sender
{
  if (_state == NSDrawerClosedState)
    [self open: sender];
  else if (_state == NSDrawerOpenState)
    [self close: sender];
  // Do nothing for inbetween states
}

// Managing Size
- (NSSize) contentSize
{
  return [[_drawerWindow contentView] frame].size;
}

- (CGFloat) leadingOffset
{
  return _leadingOffset;
}

- (NSSize) maxContentSize
{
  return _maxContentSize; 
}

- (NSSize) minContentSize
{
  return _minContentSize;
}

- (void) setContentSize: (NSSize)size
{
  // Check with min and max size
  if (size.width < _minContentSize.width)
    size.width = _minContentSize.width;
  if (size.height < _minContentSize.height)
    size.height = _minContentSize.height;
  if (size.width > _maxContentSize.width)
    size.width = _maxContentSize.width;
  if (size.height > _maxContentSize.height)
    size.height = _maxContentSize.height;

  // Check with delegate
  if ((_delegate != nil)
    && ([_delegate respondsToSelector:
      @selector(drawerWillResizeContents:toSize:)]))
    {
      size = [_delegate drawerWillResizeContents: self
					  toSize: size];
    }

  [_drawerWindow setContentSize: size];
}

- (void) setLeadingOffset: (CGFloat)offset
{
  _leadingOffset = offset;
}

- (void) setMaxContentSize: (NSSize)size
{
  _maxContentSize = size;
}

- (void) setMinContentSize: (NSSize)size
{
  _minContentSize = size;
}

- (void) setTrailingOffset: (CGFloat)offset
{
  _trailingOffset = offset;
}

- (CGFloat) trailingOffset
{
  return _trailingOffset;
}

// Managing Edge
- (NSRectEdge) edge
{
  return _currentEdge;
}

- (NSRectEdge) preferredEdge
{
  return _preferredEdge;
}

- (void) setPreferredEdge: (NSRectEdge)preferredEdge
{
  _preferredEdge = preferredEdge;
}

// Managing Views
- (NSView *) contentView
{
  return [[_drawerWindow container] contentView];
}

- (NSWindow *) parentWindow
{
  return [_drawerWindow parentWindow];
}

- (void) setContentView: (NSView *)aView
{
  [[_drawerWindow container] setContentView: aView];
}

- (void) setParentWindow: (NSWindow *)parent
{
  if (_state == NSDrawerClosedState)
    {
      [_drawerWindow setParentWindow: parent];
    }
  else
    {
      [_drawerWindow setPendingParentWindow: parent];
    }
}

 
// Delegation and State
- (id) delegate
{
  return _delegate;
}

- (void) setDelegate: (id)anObject
{
  if (_delegate)
    {
      [nc removeObserver: _delegate name: nil object: self];
    }

  _delegate = anObject; 

#define SET_DELEGATE_NOTIFICATION(notif_name) \
  if ([_delegate respondsToSelector: @selector(drawer##notif_name:)]) \
    [nc addObserver: _delegate \
      selector: @selector(drawer##notif_name:) \
      name: NSDrawer##notif_name##Notification object: self]

  SET_DELEGATE_NOTIFICATION(DidClose);
  SET_DELEGATE_NOTIFICATION(DidOpen);
  SET_DELEGATE_NOTIFICATION(WillClose);
  SET_DELEGATE_NOTIFICATION(WillOpen);
}

- (NSInteger) state
{
  return _state;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  id parent = [self parentWindow];

  [super encodeWithCoder: aCoder];
  if ([aCoder allowsKeyedCoding])
    {
      [aCoder encodeSize: [self contentSize] forKey: @"NSContentSize"];

      if (_delegate != nil)
	{
	  [aCoder encodeObject: _delegate forKey: @"NSDelegate"];
	}

      [aCoder encodeFloat: _leadingOffset forKey: @"NSLeadingOffset"];
      [aCoder encodeSize: _maxContentSize forKey: @"NSMaxContentSize"];
      [aCoder encodeSize: _minContentSize forKey: @"NSMinContentSize"];
      
      if (parent != nil)
	{
	  [aCoder encodeObject: parent forKey: @"NSParentWindow"];
	}

      [aCoder encodeInt: _preferredEdge forKey: @"NSPreferredEdge"];
      [aCoder encodeFloat: _trailingOffset forKey: @"NSTrailingOffset"];
    }
  else
    {
      [aCoder encodeSize: [self contentSize]];
      [aCoder encodeObject: _delegate];
      [aCoder encodeValueOfObjCType: @encode(float) at: &_leadingOffset];
      [aCoder encodeSize: _maxContentSize];
      [aCoder encodeSize: _minContentSize];
      [aCoder encodeObject: parent];
      [aCoder encodeValueOfObjCType: @encode(unsigned) at: &_preferredEdge];
      [aCoder encodeValueOfObjCType: @encode(float) at: &_trailingOffset];
    }
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  if ((self = [super initWithCoder: aDecoder]) != nil)
    {
      NSWindow *parentWindow = nil;
      
      if ([aDecoder allowsKeyedCoding])
	{
	  _contentSize = [aDecoder decodeSizeForKey: @"NSContentSize"];

	  if ([aDecoder containsValueForKey: @"NSDelegate"])
	    {
	      ASSIGN(_delegate, [aDecoder decodeObjectForKey: @"NSDelegate"]);
	    }

	  _leadingOffset = [aDecoder decodeFloatForKey: @"NSLeadingOffset"];
	  _maxContentSize = [aDecoder decodeSizeForKey: @"NSMaxContentSize"];
	  _minContentSize = [aDecoder decodeSizeForKey: @"NSMinContentSize"];
	  
	  if ([aDecoder containsValueForKey: @"NSParentWindow"])
	    {
	      parentWindow = [aDecoder decodeObjectForKey: @"NSParentWindow"];
	    }

	  _preferredEdge = [aDecoder decodeIntForKey: @"NSPreferredEdge"];
	  _trailingOffset = [aDecoder decodeFloatForKey: @"NSTrailingOffset"];
	}
      else
	{
	  int version = [aDecoder versionForClassName: @"NSDrawer"];
	  if (version == 0)
	    {
	      _contentSize = [aDecoder decodeSize];
	      ASSIGN(_delegate, [aDecoder decodeObject]);
	      [aDecoder decodeValueOfObjCType: @encode(float)
					   at: &_leadingOffset];
	      _maxContentSize = [aDecoder decodeSize];
	      _minContentSize = [aDecoder decodeSize];
	      parentWindow = [aDecoder decodeObject];
	      [aDecoder decodeValueOfObjCType: @encode(unsigned)
					   at: &_preferredEdge];
	      [aDecoder decodeValueOfObjCType: @encode(float)
					   at: &_trailingOffset];	      
	    }
	  else      
	    {
	      [NSException raise: NSInternalInconsistencyException
		format: @"Invalid version of NSDrawer (version = %d).",
		version];
	      return nil; // not reached, but keeps gcc happy...
	    }
	}

      // set up drawer...
      _drawerWindow =  [[GSDrawerWindow alloc] 
			 initWithContentRect:  
			   NSMakeRect(0, 0,_contentSize.width,
				      _contentSize.height)
			 styleMask: 0
			 backing: NSBackingStoreBuffered
			 defer: NO];
      [_drawerWindow setParentWindow: parentWindow];      
      [_drawerWindow setDrawer: self];
      [_drawerWindow setReleasedWhenClosed: NO];

      // initial state...
      _state = NSDrawerClosedState;
  
    }
  return self;
}

@end
