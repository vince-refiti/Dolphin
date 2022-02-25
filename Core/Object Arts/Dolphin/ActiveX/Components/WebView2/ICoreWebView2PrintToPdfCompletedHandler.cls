﻿"Filed out from Dolphin Smalltalk"!

ICoreWebViewCompletedHandler subclass: #ICoreWebView2PrintToPdfCompletedHandler
	instanceVariableNames: ''
	classVariableNames: ''
	imports: #()
	classInstanceVariableNames: ''
	classConstants: {}!
ICoreWebView2PrintToPdfCompletedHandler guid: (OS.COM.IID fromString: '{ccf1ef04-fd8e-4d5f-b2de-0983e41b8c36}')!
ICoreWebView2PrintToPdfCompletedHandler comment: '`ICoreWebView2PrintToPdfCompletedHandler` is a wrapper class for the COM interface ''WebView2.ICoreWebView2PrintToPdfCompletedHandler'' generated from type information in the '''' library. It contains methods to invoke the member functions exposed by that interface.

The type library contains no documentation for this interface

** This comment was automatically generated from a type library. Delete this line to prevent any manual edits from being overwritten if the wrapper class is regenerated.

IDL definition follows:
```
[
	object, 
	uuid(ccf1ef04-fd8e-4d5f-b2de-0983e41b8c36)
]
interface ICoreWebView2PrintToPdfCompletedHandler : IUnknown
 {
	[id(0x60010000)]
	HRESULT __stdcall Invoke(
		[in]HRESULT errorCode,
		long isSuccessful);
};
```
'!
!ICoreWebView2PrintToPdfCompletedHandler categoriesForClass!COM-Interfaces!WebView2-Interfaces! !
!ICoreWebView2PrintToPdfCompletedHandler class methodsFor!

defineFunctions
	"Declare the virtual function table for the COM interface 'WebView2.ICoreWebView2PrintToPdfCompletedHandler'
		ICoreWebView2PrintToPdfCompletedHandler defineTemplate
	"

	self defineFunction: #value:value: argumentTypes: 'hresult bool'! !
!ICoreWebView2PrintToPdfCompletedHandler class categoriesForMethods!
defineFunctions!initializing!public! !
!
