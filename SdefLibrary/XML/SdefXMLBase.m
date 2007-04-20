/*
 *  SdefXMLObject.m
 *  Sdef Editor
 *
 *  Created by Rainbow Team.
 *  Copyright © 2006 Shadow Lab. All rights reserved.
 */

#import "SdefXMLBase.h"
#import "SdefXMLNode.h"
#import <ShadowKit/SKExtensions.h>

#import "SdefComment.h"

@implementation SdefObject (SdefXMLManager)
#pragma mark XML Generation
- (SdefXMLNode *)xmlNodeForVersion:(SdefVersion)version {
  SdefXMLNode *node = nil;
  SdefObject *child = nil;
  NSEnumerator *children;
  node = [SdefXMLNode nodeWithElementName:[self xmlElementName]];
  NSAssert1(!node || ([node elementName] != nil), @"%@ return an invalid node", self);
  if (node && [node elementName]) {
    /* Comments */
    if (sd_comments)
      [node setComments:[self comments]];
    /* Hidden */
    if ([self isHidden]) {
      if (version >= kSdefTigerVersion)
        [node setAttribute:@"yes" forKey:@"hidden"];
      else
        [node setAttribute:@"hidden" forKey:@"hidden"];
    }
    /* Children */
    children = [self childEnumerator];
    while (child = [children nextObject]) {
      SdefXMLNode *childNode = [child xmlNodeForVersion:version];
      if (childNode) {
        NSAssert1([childNode isList] || [childNode elementName], @"%@ return an invalid node", child);
        [node appendChild:childNode];
      }
    }
    /* Handle ignored */
    if ([self hasIgnore]) {
      children = [[self ignores] reverseObjectEnumerator];
      while (child = [children nextObject]) {
        SdefXMLNode *childNode = [child xmlNodeForVersion:version];
        if (childNode) {
          NSAssert1([childNode isList] || [childNode elementName], @"%@ return an invalid node", child);
          [node prependChild:childNode];
        }
      }
    }
  }
  return node;
}

- (NSString *)xmlElementName {
  return nil;
}

#pragma mark XML Parsing
- (id)initWithAttributes:(NSDictionary *)attributes {
  if (self = [self initWithName:nil]) {
    [self setAttributes:attributes];
    if (![self name]) { [self setName:[[self class] defaultName]]; }
  }
  return self;
}

- (void)setAttributes:(NSDictionary *)attrs {
  [self setName:[[attrs objectForKey:@"name"] stringByUnescapingEntities:nil]];
  
  NSString *hidden = [attrs objectForKey:@"hidden"];
  if (hidden && ![hidden isEqualToString:@"no"]) {
    [self setHidden:YES];
  }
}

- (SdefParserVersion)acceptXMLElement:(NSString *)element attributes:(NSDictionary *)attrs {
  return kSdefParserUnknownVersion;
}

@end

#pragma mark -
@implementation SdefCollection (SdefXMLManager)
#pragma mark XML Generation
- (SdefXMLNode *)xmlNodeForVersion:(SdefVersion)version {
  if (![self hasChildren])
    return nil;
  
  if (kSdefPantherVersion == version) {
    return [super xmlNodeForVersion:version];
  } else if (version >= kSdefTigerVersion) {
    SdefXMLNode *list = [[SdefXMLNode alloc] initWithElementName:nil];
    [list setList:YES];
    SdefObject *child = nil;
    NSEnumerator *children = [self childEnumerator];
    while (child = [children nextObject]) {
      SdefXMLNode *node = [child xmlNodeForVersion:version];
      if (node) {
        [list appendChild:node];
      }
    }
    return list;
  }
  return nil;
}

- (NSString *)xmlElementName {
  return [self elementName];
}

#pragma mark XML Parsing
- (void)setAttributes:(NSDictionary *)attrs {
  /* Do nothing */
}

- (SdefParserVersion)acceptXMLElement:(NSString *)element attributes:(NSDictionary *)attrs {
  return kSdefParserPantherVersion;
}

@end
