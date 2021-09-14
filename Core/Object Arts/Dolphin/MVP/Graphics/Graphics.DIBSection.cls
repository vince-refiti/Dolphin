﻿"Filed out from Dolphin Smalltalk"!

Graphics.Bitmap subclass: #'Graphics.DIBSection'
	instanceVariableNames: 'depth imageBits'
	classVariableNames: ''
	imports: #()
	classInstanceVariableNames: ''
	classConstants: {}!
Graphics.DIBSection guid: (Core.GUID fromString: '{f44c914a-2b3f-11d3-8368-7a8b5a000000}')!
Graphics.DIBSection comment: ''!
!Graphics.DIBSection categoriesForClass!Graphics-Tools! !
!Graphics.DIBSection methodsFor!

cacheInfo
	"Private - Cache info about the receiver garnered from the bitmap itself.
	Since we also grab a pointer to the image bits, it is now possible to scribble all over a DIB loaded from resources/a file."

	| bitmapInfo |
	bitmapInfo := self getInfo.
	extent := bitmapInfo extent.
	depth := bitmapInfo depth.
	imageBits := bitmapInfo bmBits!

clearCached
	"Private - Clear down the receiver's handles and cached info."
 
	super clearCached.
	imageBits := nil.
	"The depth may doesn't change after creation, so we don't clear it."!

copyToGlobalHeap
	| hGlobal pGlobal ds header headerSize endHeader colorTable imageSize |
	ds := self getInfo.
	header := ds dsBmih.
	colorTable := self depth <= 8 ifTrue: [self getColorTable bytes] ifFalse: [#[]].
	headerSize := header byteSize.
	imageSize := ds biSizeImage.
	hGlobal := Kernel32 globalAlloc: ##(GHND | GMEM_DDESHARE)
				dwBytes: headerSize + colorTable size + imageSize.
	pGlobal := Kernel32 globalLock: hGlobal.
	pGlobal
		replaceFrom: 1
		to: headerSize
		with: header
		startingAt: 1.
	pGlobal
		replaceFrom: headerSize + 1
		to: (endHeader := headerSize + colorTable size)
		with: colorTable
		startingAt: 1.
	pGlobal
		replaceFrom: endHeader + 1
		to: endHeader + imageSize
		with: self imageBits
		startingAt: 1.
	Kernel32 globalUnlock: hGlobal.
	^hGlobal!

depth
	"Answer the colour depth of the receiver."

	depth isNil ifTrue: [self cacheInfo].
	^depth!

errorInappropriateColorTable: aRGBQUADArray
	"Raise an error that the receiver cannot hold aRGBQUADArray as its colour table"

	^self error: 'Inappropriate color table'!

getColorTable
	"Answer a StructureArray of RGBQUADs which is the colour table for the receiver.
	Answer nil if the receiver has no color table"

	| bits canvas size quads |
	bits := self depth.
	bits > 8 ifTrue: [^nil].
	size := 2 raisedToInteger: bits.
	quads := StructureArray length: size elementClass: RGBQUAD.
	canvas := self canvas.
	size := Gdi32
				getDIBColorTable: canvas asParameter
				uStartIndex: 0
				cEntries: size
				pColors: quads.
	size == 0 ifTrue: [^Win32Error signal].
	quads length: size.
	^quads!

imageBits
	"Answer the handle of the receiver's image bits"

	imageBits isNil ifTrue: [self cacheInfo].
	^imageBits!

imageBytes
	"Answer a ByteArray initialized from the receiver's image bits."

	^ByteArray fromAddress: self imageBits length: self getInfo biSizeImage!

setColorTable: anRGBQUADArray
	"Sets the colour table for the receiver to be that in anRGBQUADArray.
	Signals #errorInvalidColorTable if the table is the wrong size, or not appropriate,
	for the receiver"

	| bits size newSize canvas |
	bits := self depth.
	size := 2 raisedToInteger: bits.
	anRGBQUADArray size = size
		ifFalse: 
			["Inappropriate colour table size"
			self errorInappropriateColorTable: anRGBQUADArray].
	canvas := self canvas.
	newSize := Gdi32
				setDIBColorTable: canvas asParameter
				uStartIndex: 0
				cEntries: size
				pColors: anRGBQUADArray.
	size == newSize ifFalse: [^Win32Error signal]!

structClass
	^DIBSECTION! !
!Graphics.DIBSection categoriesForMethods!
cacheInfo!helpers!private! !
clearCached!initializing!private! !
copyToGlobalHeap!accessing!private! !
depth!accessing!public! !
errorInappropriateColorTable:!exceptions!public! !
getColorTable!accessing!public! !
imageBits!accessing!public! !
imageBytes!copying!public! !
setColorTable:!accessing!public! !
structClass!constants!private! !
!

!Graphics.DIBSection class methodsFor!

blankInitializerClass
	^DIBSectionFromBlankInitializer!

defaultLoadFlags
	^##(LR_COLOR | LR_CREATEDIBSECTION)!

displayCompatibleWithExtent: aPoint
	"Answer a new instance of the receiver with suitable dimensions and a colour depth compatible with the display (almost always 32-bpp these days though)."

	^self initializer: (DIBSectionFromBlankInitializer extent: aPoint
				depth: SystemMetrics current defaultColorDepth)!

fromGlobalHandle: anExternalHandle
	"Answer a new <DIBSection> instantiated with header and bits from the global memory block
	with the specified handle. The memory block is assumed to contain a BITMAPINFO structure
	followed by the image bits."

	| pBitmap header offset dibSection |
	pBitmap := Kernel32 globalLock: anExternalHandle.
	header := BITMAPINFOHEADER fromAddress: pBitmap.
	dibSection := self
				width: header biWidth
				height: header biHeight
				depth: header biBitCount.
	offset := header size + 1.
	header biBitCount <= 8
		ifTrue: 
			[| colorTable |
			colorTable := StructureArray
						fromAddress: (pBitmap yourAddress + header byteSize) asExternalAddress
						length: (2 raisedToInteger: header biBitCount)
						elementClass: RGBQUAD.
			colorTable beUnfinalizable.
			dibSection setColorTable: colorTable.
			offset := offset + colorTable size].
	dibSection imageBits
		replaceFrom: 1
		to: header biSizeImage
		with: pBitmap
		startingAt: offset.
	Kernel32 globalUnlock: anExternalHandle.
	^dibSection!

width: widthInteger height: heightInteger
	"Answers a true-colour DIBSection bitmap of dimensions width*height*24 bits/pixel."

	^self extent: widthInteger @ heightInteger!

width: widthInteger height: heightInteger depth: depthInteger
	"Answers a DIBSection bitmap of dimensions width*height. The number of colour bits per pixel are given by depth, which must be one of 1,4,8,16,24 or 32."

	^self extent: widthInteger @ heightInteger depth: depthInteger! !
!Graphics.DIBSection class categoriesForMethods!
blankInitializerClass!constants!private! !
defaultLoadFlags!constants!private! !
displayCompatibleWithExtent:!instance creation!public! !
fromGlobalHandle:!instance creation!public! !
width:height:!instance creation!public! !
width:height:depth:!instance creation!public! !
!
