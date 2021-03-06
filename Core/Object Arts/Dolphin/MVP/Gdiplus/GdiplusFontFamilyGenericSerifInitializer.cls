﻿"Filed out from Dolphin Smalltalk 7"!

GdiplusFontFamilyInitializer subclass: #GdiplusFontFamilyGenericSerifInitializer
	instanceVariableNames: ''
	classVariableNames: 'Default'
	poolDictionaries: ''
	classInstanceVariableNames: ''!
GdiplusFontFamilyGenericSerifInitializer guid: (GUID fromString: '{57c9fb99-3104-48e2-b5e7-d4f2041b5a3e}')!
GdiplusFontFamilyGenericSerifInitializer comment: ''!
!GdiplusFontFamilyGenericSerifInitializer categoriesForClass!Unclassified! !
!GdiplusFontFamilyGenericSerifInitializer methodsFor!

createHandle
	| gpHandle status |
	gpHandle := ExternalHandle new.
	status := self library gdipGetGenericFontFamilySerif: gpHandle.
	status == Ok ifFalse: [self gdiplusErrorWith: status].
	^gpHandle! !
!GdiplusFontFamilyGenericSerifInitializer categoriesFor: #createHandle!private!realizing/unrealizing! !

!GdiplusFontFamilyGenericSerifInitializer class methodsFor!

uninitialize
	GenericSerif := nil! !
!GdiplusFontFamilyGenericSerifInitializer class categoriesFor: #uninitialize!class hierarchy-removing!private! !

