/** <title>NSTableColumn</title>

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: December 1999
   Completely Rewritten.

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#include <Foundation/NSNotification.h>
#include <AppKit/NSTableHeaderCell.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSTableView.h>

/**
  <unit>
  <heading>Class Description</heading>

  <p>
  NSTableColumn objects represent columns in NSTableViews.  
  </p>
  <section>
    <heading>The Column Identifier</heading>
    <p>
    Each NSTableColumn object is identified by an object, called 
    the column identifier.  The reason is that, after a column has been 
    added to a table view, the user might move the columns around, so  
    there is a need to identify the columns regardless of their position 
    in the table.  
    </p>
    <p>
    The identifier is typically a string describing the column.  
    This identifier object is never displayed to the user !   
    It is only used internally by the program to identify 
    the column - so yes, you may use a funny string for it 
    and nobody will know, except people reading the code. 
    </p>
  </section>
  <section>
    <heading>Information Stored in an NSTableColumn Object</heading>
    <p>
    An NSTableColumn object mainly keeps information about the width
    of the column, its minimum and maximum width; whether the column 
    can be edited or resized; and the cells used to draw the column 
    header and the data in the column.  You can change all these 
    attributes of the column by calling the appropriate methods.  
    Please note that the table column does not hold nor has access 
    to the data to be displayed in the column; this data is maintained 
    in the table view's data source, as described in the NSTableView 
    documentation.  A last hint: to set the title of a table column, 
    ask the table column for its header cell, and set the string value 
    of this header cell to the desired title.
    </p>
  </section>
  </unit>
*/  
@implementation NSTableColumn

/*
 *
 * Class methods
 *
 */
+ (void) initialize
{
  if (self == [NSTableColumn class])
    [self setVersion: 1];
}

/*
 *
 * Instance methods
 *
 */

/**
  Initialize the column.  anObject is an object used to identify the
  column; it is usually a string, but might be any kind of object.
  anObject is retained.  */
- (id)initWithIdentifier: (id)anObject
{
  self = [super init];
  _width = 0;
  _min_width = 0;
  _max_width = 100000;
  _is_resizable = YES;
  _is_editable = YES;
  _tableView = nil;

  _headerCell = [NSTableHeaderCell new];
  _dataCell = [NSTextFieldCell new];

  ASSIGN (_identifier, anObject);
  return self;
}

- (void)dealloc
{
  RELEASE (_headerCell);
  RELEASE (_dataCell);
  TEST_RELEASE (_identifier);
  [super dealloc];
}

/*
 * Managing the Identifier
 */
/**
  Set the identifier used to identify the table.  The old identifier
  is released, and the new one is retained.  */
- (void)setIdentifier: (id)anObject
{
  ASSIGN (_identifier, anObject);
}

/**
  Return the column identifier, an object used to identify the column.
  This object is usually a string, but might be any kind of object.
  */
- (id)identifier
{
  return _identifier;
}
/*
 * Setting the NSTableView 
 */
/**
  Set the table view corresponding to this table column.  This method
  is invoked internally by the table view, and you should not call it
  directly; it is exposed because you may want to override it in
  subclasses.  To use the table column in a table view, you should use
  NSTableView's addTableColumn: instead.  */
- (void)setTableView: (NSTableView*)aTableView
{
  // We do *not* RETAIN aTableView. 
  // On the contrary, aTableView is supposed to RETAIN us.
  _tableView = aTableView;
}

/**
  Return the table view the column belongs to, or nil if the table
  column was not added to any table view.  */
- (NSTableView *)tableView
{
  return _tableView;
}

/*
 * Controlling size 
 */
/**
  Set the width of the table column.  Before being resized, the new
  width is constrained to the table column minimum and maximum width:
  if newWidth is smaller than the table column's min width, the table
  column is simply resized to its min width.  If newWidth is bigger
  than the table column's max width, the table column is simply
  resized to its max width.  Otherwise, it is resized to newWidth.  If
  the width of the table was actually changed, the table view (if any)
  is redisplayed (by calling tile), and the
  NSTableViewColumnDidResizeNotification is posted on behalf of the
  table view.  */
- (void)setWidth: (float)newWidth
{
  float oldWidth = _width;

  if (newWidth > _max_width)
    newWidth = _max_width;
  else if (newWidth < _min_width)
    newWidth = _min_width;

  if (_width == newWidth)
    return;
  
  _width = newWidth;
  
  if (_tableView)
    {
      // Tiling also marks it as needing redisplay
      [_tableView tile];
      
      [[NSNotificationCenter defaultCenter] 
	postNotificationName: NSTableViewColumnDidResizeNotification
	object: _tableView
	userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
				  [NSNumber numberWithFloat: oldWidth],
				@"NSOldWidth", nil]];
    }
}

/** Return the width of the table column. */
- (float)width
{
  return _width;
}

/**
  Set the min width of the table column, eventually adjusting the
  width of the column if it is smaller than the new min width.  In no
  way a table column can be made smaller than its min width.  */
- (void)setMinWidth: (float)minWidth
{
  _min_width = minWidth;
  if (_width < _min_width)
    [self setWidth: _min_width];
}

/**
  Return the column's min width.  The column can in no way be resized
  to a width smaller than this min width.  The default min width is
  zero.  */
- (float)minWidth
{
  return _min_width;
}

/**
  Set the max width of the table column, eventually adjusting the
  width of the column if it is bigger than the new max width.  In no
  way a table column can be made bigger than its max width.  */
- (void)setMaxWidth: (float)maxWidth
{
  _max_width = maxWidth;
  if (_width > _max_width)
    [self setWidth: _max_width];
}

/**
  Return the column's max width.  The column can in no way be resized
  to a width bigger than this max width.  The default max width is
  100000.  */
- (float)maxWidth
{
  return _max_width;
}

/**
  Set whether the user can resize the table column by dragging the
  border of its header with the mouse.  The table column can be
  resized programmatically regardless of this setting.  */
- (void)setResizable: (BOOL)flag
{
  _is_resizable = flag;
}

/**
  Return whether the column might be resized by the user by dragging
  the column header border.  */
- (BOOL)isResizable
{
  return _is_resizable;
}

/**
  Change the width of the column to be just enough to display its
  header; change the minimum width and maximum width to allow the
  column to have this width (if the minimum width is bigger than the
  column header width, it is reduced to it; if the maximum width is
  smaller than the column header width, it is increased to it).  */
- (void)sizeToFit
{
  float new_width;

  new_width = [_headerCell cellSize].width;

  if (new_width > _max_width)
    _max_width = new_width;

  if (new_width < _min_width)
    _min_width = new_width;
  
  // For easier subclassing we dont do it directly
  [self setWidth: new_width];
}

/*
 * Controlling editability 
 */
/**
  Set whether data in the column might be edited by the user by
  double-cliking on them.  */
- (void)setEditable: (BOOL)flag
{
  _is_editable = flag;
}

/**
  Return whether data displayed in the column can be edited by the
  user by double-cliking on them.  */
- (BOOL)isEditable
{
  return _is_editable;
}

/*
 * Setting component cells 
 */
/**
  Set the cell used to display the column header.  aCell can't be nil,
  otherwise a warning will be generated and the method call ignored.
  The old cell is released, the new one is retained.  */
- (void)setHeaderCell: (NSCell*)aCell
{
  if (aCell == nil)
    {
      NSLog (@"Attempt to set a nil headerCell for NSTableColumn");
      return;
    }
  ASSIGN (_headerCell, aCell);
}

/** 
  Return the cell used to display the column title.  The default
  header cell is an NSTableHeaderCell.  */
- (NSCell*)headerCell
{
  return _headerCell;
}

/**
  Set the cell used to display data in the column.  aCell can't be
  nil, otherwise a warning will be generated and the method ignored.
  The old cell is released, the new one is retained.  If you want to
  change the attributes in which a single row in a column is
  displayed, you should better use a delegate for your NSTableView
  implementing tableView:willDisplayCell:forTableColumn:row:.  */
- (void)setDataCell: (NSCell*)aCell
{
  if (aCell == nil)
    {
      NSLog (@"Attempt to set a nil dataCell for NSTableColumn");
      return;
    }
  ASSIGN (_dataCell, aCell);
}

/** 
  Return the cell used to display data in the column.  The default
  data cell is an NSTextFieldCell.  */
- (NSCell*)dataCell
{
  return _dataCell;
}

- (NSCell*)dataCellForRow: (int)row
{
  return [self dataCell];
}

/*
 * Encoding/Decoding
 */

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeObject: _identifier];
  [aCoder encodeObject: _headerCell];
  [aCoder encodeObject: _dataCell];

  [aCoder encodeValueOfObjCType: @encode(float) at: &_width];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_min_width];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_max_width];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_is_resizable];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_is_editable];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  self = [super init];
  _identifier = RETAIN([aDecoder decodeObject]);
  _headerCell = RETAIN([aDecoder decodeObject]);
  _dataCell   = RETAIN([aDecoder decodeObject]);

  [aDecoder decodeValueOfObjCType: @encode(float) at: &_width];
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_min_width];
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_max_width];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_is_resizable];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_is_editable];
  return self;
}

@end
