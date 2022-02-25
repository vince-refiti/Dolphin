﻿"Filed out from Dolphin Smalltalk"!

ICoreWebView2EventArgs subclass: #ICoreWebView2MoveFocusRequestedEventArgs
	instanceVariableNames: ''
	classVariableNames: ''
	imports: #()
	classInstanceVariableNames: ''
	classConstants: {}!
ICoreWebView2MoveFocusRequestedEventArgs guid: (OS.COM.IID fromString: '{2d6aa13b-3839-4a15-92fc-d88b3c0d9c9d}')!
ICoreWebView2MoveFocusRequestedEventArgs comment: '`ICoreWebView2MoveFocusRequestedEventArgs` is a wrapper class for the COM interface ''WebView2.ICoreWebView2MoveFocusRequestedEventArgs'' generated from type information in the '''' library. It contains methods to invoke the member functions exposed by that interface.

The type library contains no documentation for this interface

** This comment was automatically generated from a type library. Delete this line to prevent any manual edits from being overwritten if the wrapper class is regenerated.

IDL definition follows:
```
[
	object, 
	uuid(2d6aa13b-3839-4a15-92fc-d88b3c0d9c9d)
]
interface ICoreWebView2MoveFocusRequestedEventArgs : IUnknown
 {
	[id(0x60010000), propget]
	HRESULT __stdcall reason(
		[out, retval]COREWEBVIEW2_MOVE_FOCUS_REASON* reason);
	[id(0x60010001), propget]
	HRESULT __stdcall Handled(
		[out, retval]long* value);
	[id(0x60010001), propput]
	HRESULT __stdcall Handled(
		[in]long value);
};
```
'!
!ICoreWebView2MoveFocusRequestedEventArgs categoriesForClass!COM-Interfaces!WebView2-Interfaces! !
!ICoreWebView2MoveFocusRequestedEventArgs methodsFor!

get_Handled: value
	"Private - Get the value of the 'Handled' property of the receiver.

		HRESULT __stdcall Handled(
			[out, retval]long* value);"

	<virtual stdcall: hresult 5 sdword*>
	^self invalidCall: _failureCode!

get_reason: reason
	"Private - Get the value of the 'reason' property of the receiver.

		HRESULT __stdcall reason(
			[out, retval]COREWEBVIEW2_MOVE_FOCUS_REASON* reason);"

	<virtual stdcall: hresult 4 sdword*>
	^self invalidCall: _failureCode!

handled
	"Answer the <Boolean> value of the 'Handled' property of the receiver."

	| answer |
	answer := BOOL newBuffer.
	self get_Handled: answer.
	^answer asObject!

handled: value
	"Set the 'Handled' property of the receiver to the <sdword> value of the argument."

	self put_Handled: value asParameter!

put_Handled: value
	"Private - Set the value of the 'Handled' property of the object wrapped by the 
	 receiver to the <sdword> argument, value.

		HRESULT __stdcall Handled(
			[in]long value);"

	<virtual stdcall: hresult 6 sdword>
	^self invalidCall: _failureCode!

reason
	"Answer the <sdword> value of the 'reason' property of the receiver."

	| answer |
	answer := SDWORD new.
	self get_reason: answer.
	^answer asObject! !
!ICoreWebView2MoveFocusRequestedEventArgs categoriesForMethods!
get_Handled:!**auto generated**!COM Interfaces-ICoreWebView2MoveFocusRequestedEventArgs!private! !
get_reason:!**auto generated**!COM Interfaces-ICoreWebView2MoveFocusRequestedEventArgs!private! !
handled!properties!public! !
handled:!properties!public! !
put_Handled:!**auto generated**!COM Interfaces-ICoreWebView2MoveFocusRequestedEventArgs!private! !
reason!**auto generated**!properties!public! !
!

!ICoreWebView2MoveFocusRequestedEventArgs class methodsFor!

defineFunctions
	"Declare the virtual function table for the COM interface 'WebView2.ICoreWebView2MoveFocusRequestedEventArgs'
		ICoreWebView2MoveFocusRequestedEventArgs defineTemplate"

	self
		defineFunction: #get_reason:
			argumentTypes: 'sdword*';
		defineFunction: #get_Handled:
			argumentTypes: 'sdword*';
		defineFunction: #put_Handled:
			argumentTypes: 'sdword'
! !
!ICoreWebView2MoveFocusRequestedEventArgs class categoriesForMethods!
defineFunctions!**auto generated**!initializing!public! !
!
