//
//  PDFDocument.h
//  PdfAnnotator
//
//  Created by Raphael Cruzeiro on 6/25/11.
//  Copyright 2011 Raphael Cruzeiro. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Annotation;

@interface PDFDocument : NSObject {
}

- (id)initWithDocument:(NSURL *)documentPath;

- (NSInteger) pageCount;
- (void) loadPage:(NSInteger)number;
- (BOOL)save;

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *hash;
@property (readwrite, nonatomic, assign) CGPDFDocumentRef document;
@property (readwrite, nonatomic, assign) CGPDFPageRef page;

@property (nonatomic, assign) BOOL dirty;

@property (nonatomic, retain) Annotation *annotation;

@end
