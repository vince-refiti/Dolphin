﻿"Filed out from Dolphin Smalltalk 7"!

ArrayFieldLength subclass: #FixedArrayFieldLength
	instanceVariableNames: 'elementCount'
	classVariableNames: ''
	poolDictionaries: ''
	classInstanceVariableNames: ''!
FixedArrayFieldLength guid: (GUID fromString: '{f257b54a-a33a-4696-b457-e7e6d4dc0509}')!
FixedArrayFieldLength comment: ''!
!FixedArrayFieldLength categoriesForClass!Kernel-Objects! !
!FixedArrayFieldLength methodsFor!

allocationLength
	^elementCount!

elementCount
	^elementCount!

elementCount: anInteger
	elementCount := anInteger!

getElementCountOf: anExternalField in: anExternalStructure
	"Private - Answer the number of elements in the array field of the <ExternalStructure> argument."

	"The length is fixed, and doesn't depend on the structure instance."

	^elementCount!

isFixedSize
	"Private - Answer whether the field described by the receiver is of a fixed size, i.e.
	known statically as opposed to varying dynamically at runtime."

	^true!

printElementCountExpressionFor: anExternalField on: aWriteStream
	aWriteStream print: elementCount!

printSetSizeFor: structClass on: aWriteStream
	"Private - Print a statement to set the length field corresponding to this field."

	"Only relevant to conformant/sized subclasses."

	!

setElementCount: anArrayedCollection of: anExternalField in: anExternalStructure
	"Private - Set the length field corresponding to this array field, if any."

	"anExternalField describes a fixed length array - nothing to do here"

	! !
!FixedArrayFieldLength categoriesFor: #allocationLength!accessing!private! !
!FixedArrayFieldLength categoriesFor: #elementCount!accessing!private! !
!FixedArrayFieldLength categoriesFor: #elementCount:!accessing!private! !
!FixedArrayFieldLength categoriesFor: #getElementCountOf:in:!indirect accessing!private! !
!FixedArrayFieldLength categoriesFor: #isFixedSize!private!testing! !
!FixedArrayFieldLength categoriesFor: #printElementCountExpressionFor:on:!automatic generation!private! !
!FixedArrayFieldLength categoriesFor: #printSetSizeFor:on:!automatic generation!development!private! !
!FixedArrayFieldLength categoriesFor: #setElementCount:of:in:!indirect accessing!private! !

!FixedArrayFieldLength class methodsFor!

elementCount: anInteger
	"Answer a new instance of the receiver to describe a fixed array length of the specified
	number of elements on behalf of some kind of <ArrayField>."

	^self new elementCount: anInteger! !
!FixedArrayFieldLength class categoriesFor: #elementCount:!instance creation!public! !

