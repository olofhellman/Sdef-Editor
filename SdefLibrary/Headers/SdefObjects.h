/*
 *  SdefObject.h
 *  Sdef Editor
 *
 *  Created by Rainbow Team.
 *  Copyright � 2006 - 2007 Shadow Lab. All rights reserved.
 */

#import "SdefBase.h"

@interface SdefDocumentedObject : SdefObject <NSCopying, NSCoding> {
@private
  SdefDocumentation *sd_documentation;
}

@end

#pragma mark -
@interface SdefImplementedObject : SdefDocumentedObject <NSCopying, NSCoding> {
@private
  SdefImplementation *sd_impl;
}

- (NSString *)cocoaKey;
- (NSString *)cocoaName;
- (NSString *)cocoaClass;
- (NSString *)cocoaMethod;

@end

#pragma mark -
@class SdefSynonym, SdefXRef;
@interface SdefTerminologyObject : SdefImplementedObject <NSCopying, NSCoding> {
@private
  NSString *sd_id;
  NSString *sd_code; 
  NSString *sd_desc;
  NSMutableArray *sd_xrefs;
  NSMutableArray *sd_synonyms;
}

- (NSString *)code;
- (void)setCode:(NSString *)str;

- (NSString *)desc;
- (void)setDesc:(NSString *)newDesc;

#pragma mark XRefs KVC
- (NSArray *)xrefs;
- (void)setXrefs:(NSArray *)xrefs;

- (NSUInteger)countOfXrefs;
- (void)addXrefs:(SdefXRef *)aRef;
- (id)objectInXrefsAtIndex:(NSUInteger)anIndex;
- (void)insertObject:(id)object inXrefsAtIndex:(NSUInteger)anIndex;
- (void)removeObjectFromXrefsAtIndex:(NSUInteger)anIndex;
- (void)replaceObjectInXrefsAtIndex:(NSUInteger)anIndex withObject:(id)object;

#pragma mark Synonyms KVC
- (NSArray *)synonyms;
- (void)setSynonyms:(NSArray *)synonyms;

- (NSUInteger)countOfSynonyms;
- (void)addSynonym:(SdefSynonym *)aSynonym;
- (id)objectInSynonymsAtIndex:(NSUInteger)index;
- (void)insertObject:(id)object inSynonymsAtIndex:(NSUInteger)index;
- (void)removeObjectFromSynonymsAtIndex:(NSUInteger)index;
- (void)replaceObjectInSynonymsAtIndex:(NSUInteger)index withObject:(id)object;

@end

#pragma mark -
@class SdefType;
@interface SdefTypedObject : SdefTerminologyObject <NSCopying, NSCoding> {
@private
  NSMutableArray *sd_types;
}

/* Simple Type */
- (BOOL)hasType;
- (NSString *)type;
- (void)setType:(NSString *)aType;

/* Complex Type */
- (BOOL)hasCustomType;

- (NSArray *)types;
- (NSUInteger)countOfTypes;
- (void)addType:(SdefType *)aType;
- (void)setTypes:(NSArray *)objects;
- (id)objectInTypesAtIndex:(NSUInteger)index;
- (void)removeObjectFromTypesAtIndex:(NSUInteger)index;
- (void)insertObject:(id)object inTypesAtIndex:(NSUInteger)index;
- (void)replaceObjectInTypesAtIndex:(NSUInteger)index withObject:(id)object;

@end

SK_PRIVATE
NSString *SdefStringForOSType(OSType type);
SK_PRIVATE
OSType OSTypeFromSdefString(NSString *string);

SK_PRIVATE
NSArray *SdefTypesForTypeString(NSString *type);
SK_PRIVATE
NSString *SdefTypeStringForTypes(NSArray *types);

#pragma mark -
@interface SdefTypedOrphanObject : SdefTypedObject <NSCopying, NSCoding> {
@private
  id<SdefObject> sd_owner;
}

- (id<SdefObject>)owner;
- (void)setOwner:(id<SdefObject>)anObject;

- (id<SdefObject>)firstParentOfType:(SdefObjectType)aType;

@end
