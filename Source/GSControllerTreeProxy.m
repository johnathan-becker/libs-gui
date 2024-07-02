/* Implementation of class GSControllerTreeProxy
   Copyright (C) 2024 Free Software Foundation, Inc.
   
   By: Gregory John Casamento
   Date: 24-06-2024

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110 USA.
*/

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>

#import "AppKit/NSTreeController.h"

#import "GSControllerTreeProxy.h"
#import "GSBindingHelpers.h"

@implementation GSControllerTreeProxy

+ (NSMutableDictionary *) dictionaryWithChildren: (NSMutableArray *)children
{
  NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObject: children
								       forKey: @"children"];
  return dictionary;
}

- (instancetype) initWithRepresentedObject: (id)representedObject
			    withController: (id)controller
{
  self = [super initWithRepresentedObject: representedObject];
  if (self != nil)
    {
      ASSIGN(_controller, controller);
    }
  return self;
}

- (NSUInteger) count
{
  NSArray *children = [[self representedObject] objectForKey: @"children"];
  return [children count];
}

- (NSMutableArray *) childNodes
{
  NSDictionary *ro = [self representedObject];
  NSMutableArray *children = [ro objectForKey: @"children"];
  return children;
}

- (id) value
{
  return nil;
}

@end

