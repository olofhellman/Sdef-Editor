//
//  SdtplWindow.h
//  Sdef Editor
//
//  Created by Grayfox on 25/03/05.
//  Copyright 2005 Shadow Lab. All rights reserved.
//

#import "SKWindowController.h"

@class SdefDocument, SdefTemplate, SdtplGenerator;
@interface SdtplWindow : SKWindowController {
  IBOutlet NSPopUpButton *templates;
  IBOutlet SdtplGenerator *generator;
  IBOutlet NSView *generalView, *tocView, *htmlView, *infoView;
@private
  SdefDocument *sd_document;
  SdefTemplate *sd_template;
}

- (id)initWithDocument:(SdefDocument *)aDoc;

- (IBAction)export:(id)sender;
- (IBAction)showPreview:(id)sender;
- (IBAction)changeTemplate:(id)sender;

- (BOOL)importTemplate;
- (SdefTemplate *)selectedTemplate;
- (void)setSelectedTemplate:(SdefTemplate *)aTemplate;

@end