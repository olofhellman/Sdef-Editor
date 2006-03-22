/*
 *  SdefXMLNode.h
 *  Sdef Editor
 *
 *  Created by Rainbow Team.
 *  Copyright © 2006 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKTreeNode.h>

@interface SdefXMLNode : SKTreeNode {
  BOOL empty;
  NSString *sd_name;
  NSMutableArray *sd_attrKeys, *sd_attrValues;
  
  NSMutableArray *sd_comments;
  NSString * sd_content;
}

+ (id)nodeWithElementName:(NSString *)aName;
- (id)initWithElementName:(NSString *)name;

- (BOOL)isEmpty;
- (void)setEmpty:(BOOL)flag;

- (NSString *)elementName;
- (void)setElementName:(NSString *)aName;

- (unsigned)attributeCount;

- (NSArray *)attrKeys;
- (NSArray *)attrValues;

- (id)attributForKey:(NSString *)key;
- (void)setAttribute:(NSString *)value forKey:(NSString *)key;
- (void)removeAttributeForKey:(NSString *)key;

- (NSString *)content;
- (void)setContent:(NSString *)aContent;

- (NSArray *)comments;
- (void)setComments:(NSArray *)comments;
- (void)addComment:(NSString *)comment;
- (void)removeCommentAtIndex:(unsigned)index;

@end
