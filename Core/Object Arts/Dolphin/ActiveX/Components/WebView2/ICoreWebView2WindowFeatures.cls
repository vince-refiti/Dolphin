﻿"Filed out from Dolphin Smalltalk"!

ICoreWebView2Interface subclass: #ICoreWebView2WindowFeatures
	instanceVariableNames: ''
	classVariableNames: ''
	imports: #()
	classInstanceVariableNames: ''
	classConstants: {}!
ICoreWebView2WindowFeatures guid: (OS.COM.IID fromString: '{5eaf559f-b46e-4397-8860-e422f287ff1e}')!
ICoreWebView2WindowFeatures comment: '`ICoreWebView2WindowFeatures` is a wrapper class for the COM interface ''WebView2.ICoreWebView2WindowFeatures'' generated from type information in the '''' library. It contains methods to invoke the member functions exposed by that interface.

The type library contains no documentation for this interface

** This comment was automatically generated from a type library. Delete this line to prevent any manual edits from being overwritten if the wrapper class is regenerated.

IDL definition follows:
```
[
	object, 
	uuid(5eaf559f-b46e-4397-8860-e422f287ff1e)
]
interface ICoreWebView2WindowFeatures : IUnknown
 {
	[id(0x60010000), propget]
	HRESULT __stdcall HasPosition(
		[out, retval]long* value);
	[id(0x60010001), propget]
	HRESULT __stdcall HasSize(
		[out, retval]long* value);
	[id(0x60010002), propget]
	HRESULT __stdcall left(
		[out, retval]unsigned int* value);
	[id(0x60010003), propget]
	HRESULT __stdcall top(
		[out, retval]unsigned int* value);
	[id(0x60010004), propget]
	HRESULT __stdcall Height(
		[out, retval]unsigned int* value);
	[id(0x60010005), propget]
	HRESULT __stdcall Width(
		[out, retval]unsigned int* value);
	[id(0x60010006), propget]
	HRESULT __stdcall ShouldDisplayMenuBar(
		[out, retval]long* value);
	[id(0x60010007), propget]
	HRESULT __stdcall ShouldDisplayStatus(
		[out, retval]long* value);
	[id(0x60010008), propget]
	HRESULT __stdcall ShouldDisplayToolbar(
		[out, retval]long* value);
	[id(0x60010009), propget]
	HRESULT __stdcall ShouldDisplayScrollBars(
		[out, retval]long* value);
};
```
'!
!ICoreWebView2WindowFeatures categoriesForClass!COM-Interfaces!WebView2-Interfaces! !
!ICoreWebView2WindowFeatures methodsFor!

extent
	^self width @ self height!

get_HasPosition: value
	"Private - Get the value of the 'HasPosition' property of the receiver.

		HRESULT __stdcall HasPosition(
			[out, retval]long* value);"

	<virtual stdcall: hresult 4 sdword*>
	^self invalidCall: _failureCode!

get_HasSize: value
	"Private - Get the value of the 'HasSize' property of the receiver.

		HRESULT __stdcall HasSize(
			[out, retval]long* value);"

	<virtual stdcall: hresult 5 sdword*>
	^self invalidCall: _failureCode!

get_Height: value
	"Private - Get the value of the 'Height' property of the receiver.

		HRESULT __stdcall Height(
			[out, retval]unsigned int* value);"

	<virtual stdcall: hresult 8 dword*>
	^self invalidCall: _failureCode!

get_left: value
	"Private - Get the value of the 'left' property of the receiver.

		HRESULT __stdcall left(
			[out, retval]unsigned int* value);"

	<virtual stdcall: hresult 6 dword*>
	^self invalidCall: _failureCode!

get_ShouldDisplayMenuBar: value
	"Private - Get the value of the 'ShouldDisplayMenuBar' property of the receiver.

		HRESULT __stdcall ShouldDisplayMenuBar(
			[out, retval]long* value);"

	<virtual stdcall: hresult 10 sdword*>
	^self invalidCall: _failureCode!

get_ShouldDisplayScrollBars: value
	"Private - Get the value of the 'ShouldDisplayScrollBars' property of the receiver.

		HRESULT __stdcall ShouldDisplayScrollBars(
			[out, retval]long* value);"

	<virtual stdcall: hresult 13 sdword*>
	^self invalidCall: _failureCode!

get_ShouldDisplayStatus: value
	"Private - Get the value of the 'ShouldDisplayStatus' property of the receiver.

		HRESULT __stdcall ShouldDisplayStatus(
			[out, retval]long* value);"

	<virtual stdcall: hresult 11 sdword*>
	^self invalidCall: _failureCode!

get_ShouldDisplayToolbar: value
	"Private - Get the value of the 'ShouldDisplayToolbar' property of the receiver.

		HRESULT __stdcall ShouldDisplayToolbar(
			[out, retval]long* value);"

	<virtual stdcall: hresult 12 sdword*>
	^self invalidCall: _failureCode!

get_top: value
	"Private - Get the value of the 'top' property of the receiver.

		HRESULT __stdcall top(
			[out, retval]unsigned int* value);"

	<virtual stdcall: hresult 7 dword*>
	^self invalidCall: _failureCode!

get_Width: value
	"Private - Get the value of the 'Width' property of the receiver.

		HRESULT __stdcall Width(
			[out, retval]unsigned int* value);"

	<virtual stdcall: hresult 9 dword*>
	^self invalidCall: _failureCode!

hasPosition
	"Answer the <Boolean> value of the 'HasPosition' property of the receiver."

	| answer |
	answer := BOOL newBuffer.
	self get_HasPosition: answer.
	^answer asObject!

hasSize
	"Answer the <Boolean> value of the 'HasSize' property of the receiver."

	| answer |
	answer := BOOL newBuffer.
	self get_HasSize: answer.
	^answer asObject!

height
	"Answer the <dword> value of the 'Height' property of the receiver."

	| answer |
	answer := DWORD new.
	self get_Height: answer.
	^answer asObject!

left
	"Answer the <dword> value of the 'left' property of the receiver."

	| answer |
	answer := DWORD new.
	self get_left: answer.
	^answer asObject!

position
	^self left @ self top!

printableProperties
	| propertyNames |
	propertyNames := OrderedCollection new: 6.
	self hasPosition ifTrue: [propertyNames add: #position].
	self hasSize ifTrue: [propertyNames add: #extent].
	propertyNames
		addAll: #(#shouldDisplayMenuBar #shouldDisplayScrollBars #shouldDisplayStatus #shouldDisplayToolbar).
	^propertyNames!

shouldDisplayMenuBar
	"Answer the <Boolean> value of the 'ShouldDisplayMenuBar' property of the receiver."

	| answer |
	answer := BOOL newBuffer.
	self get_ShouldDisplayMenuBar: answer.
	^answer asObject!

shouldDisplayScrollBars
	"Answer the <Boolean> value of the 'ShouldDisplayScrollBars' property of the receiver."

	| answer |
	answer := BOOL newBuffer .
	self get_ShouldDisplayScrollBars: answer.
	^answer asObject!

shouldDisplayStatus
	"Answer the <Boolean> value of the 'ShouldDisplayStatus' property of the receiver."

	| answer |
	answer := BOOL newBuffer.
	self get_ShouldDisplayStatus: answer.
	^answer asObject!

shouldDisplayToolbar
	"Answer the <Boolean> value of the 'ShouldDisplayToolbar' property of the receiver."

	| answer |
	answer := BOOL newBuffer.
	self get_ShouldDisplayToolbar: answer.
	^answer asObject!

top
	"Answer the <dword> value of the 'top' property of the receiver."

	| answer |
	answer := DWORD new.
	self get_top: answer.
	^answer asObject!

width
	"Answer the <dword> value of the 'Width' property of the receiver."

	| answer |
	answer := DWORD new.
	self get_Width: answer.
	^answer asObject! !
!ICoreWebView2WindowFeatures categoriesForMethods!
extent!properties!public! !
get_HasPosition:!**auto generated**!COM Interfaces-ICoreWebView2WindowFeatures!private! !
get_HasSize:!**auto generated**!COM Interfaces-ICoreWebView2WindowFeatures!private! !
get_Height:!**auto generated**!COM Interfaces-ICoreWebView2WindowFeatures!private! !
get_left:!**auto generated**!COM Interfaces-ICoreWebView2WindowFeatures!private! !
get_ShouldDisplayMenuBar:!**auto generated**!COM Interfaces-ICoreWebView2WindowFeatures!private! !
get_ShouldDisplayScrollBars:!**auto generated**!COM Interfaces-ICoreWebView2WindowFeatures!private! !
get_ShouldDisplayStatus:!**auto generated**!COM Interfaces-ICoreWebView2WindowFeatures!private! !
get_ShouldDisplayToolbar:!**auto generated**!COM Interfaces-ICoreWebView2WindowFeatures!private! !
get_top:!**auto generated**!COM Interfaces-ICoreWebView2WindowFeatures!private! !
get_Width:!**auto generated**!COM Interfaces-ICoreWebView2WindowFeatures!private! !
hasPosition!properties!public! !
hasSize!properties!public! !
height!**auto generated**!properties!public! !
left!**auto generated**!properties!public! !
position!properties!public! !
printableProperties!development!printing!private! !
shouldDisplayMenuBar!properties!public! !
shouldDisplayScrollBars!properties!public! !
shouldDisplayStatus!properties!public! !
shouldDisplayToolbar!properties!public! !
top!**auto generated**!properties!public! !
width!**auto generated**!properties!public! !
!

!ICoreWebView2WindowFeatures class methodsFor!

defineFunctions
	"Declare the virtual function table for the COM interface 'WebView2.ICoreWebView2WindowFeatures'
		ICoreWebView2WindowFeatures defineTemplate"

	self
		defineFunction: #get_HasPosition:
			argumentTypes: 'sdword*';
		defineFunction: #get_HasSize:
			argumentTypes: 'sdword*';
		defineFunction: #get_left:
			argumentTypes: 'dword*';
		defineFunction: #get_top:
			argumentTypes: 'dword*';
		defineFunction: #get_Height:
			argumentTypes: 'dword*';
		defineFunction: #get_Width:
			argumentTypes: 'dword*';
		defineFunction: #get_ShouldDisplayMenuBar:
			argumentTypes: 'sdword*';
		defineFunction: #get_ShouldDisplayStatus:
			argumentTypes: 'sdword*';
		defineFunction: #get_ShouldDisplayToolbar:
			argumentTypes: 'sdword*';
		defineFunction: #get_ShouldDisplayScrollBars:
			argumentTypes: 'sdword*'
! !
!ICoreWebView2WindowFeatures class categoriesForMethods!
defineFunctions!**auto generated**!initializing!public! !
!
