/*
 *  SdefXMLSuite.m
 *  Sdef Editor
 *
 *  Created by Rainbow Team.
 *  Copyright © 2006 - 2007 Shadow Lab. All rights reserved.
 */

#import "SdefSuite.h"
#import "SdefVerb.h"

#import "SdefXMLBase.h"

@implementation SdefSuite (SdefXMLManager)
#pragma mark XML Generation
- (NSString *)xmlElementName {
  return @"suite";
}
#pragma mark XML Parser
- (void)addXMLChild:(id<SdefObject>)child {
  switch ([child objectType]) {
    case kSdefType_ValueType:
    case kSdefType_RecordType:
    case kSdefType_Enumeration:
      [[self types] appendChild:(id)child];
      break;
    case kSdefType_Class:
      [[self classes] appendChild:(id)child];
      break;
    case kSdefType_Command: {
      SdefVerb *verb = (SdefVerb *)child;
      if ([verb isCommand]) {
        [[self commands] appendChild:verb];
      } else {
        [[self events] appendChild:verb];
      }
    }
      break;
    default:
      [super addXMLChild:child];
      break;
  }
}

@end
