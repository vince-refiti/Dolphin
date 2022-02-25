﻿"Filed out from Dolphin Smalltalk"!

ICoreWebView2EventHandler subclass: #ICoreWebView2NewWindowRequestedEventHandler
	instanceVariableNames: ''
	classVariableNames: ''
	imports: #()
	classInstanceVariableNames: ''
	classConstants: {}!
ICoreWebView2NewWindowRequestedEventHandler guid: (OS.COM.IID fromString: '{d4c185fe-c81c-4989-97af-2d3fa7ab5651}')!
ICoreWebView2NewWindowRequestedEventHandler comment: '`ICoreWebView2NewWindowRequestedEventHandler` is a wrapper class for the COM interface ''WebView2.ICoreWebView2NewWindowRequestedEventHandler'' generated from type information in the '''' library. It contains methods to invoke the member functions exposed by that interface.

The type library contains no documentation for this interface

** This comment was automatically generated from a type library. Delete this line to prevent any manual edits from being overwritten if the wrapper class is regenerated.

IDL definition follows:
```
[
	object, 
	uuid(d4c185fe-c81c-4989-97af-2d3fa7ab5651)
]
interface ICoreWebView2NewWindowRequestedEventHandler : IUnknown
 {
	[id(0x60010000)]
	HRESULT __stdcall Invoke(
		[in]ICoreWebView2* sender,
		[in]ICoreWebView2NewWindowRequestedEventArgs* args);
};
```
'!
!ICoreWebView2NewWindowRequestedEventHandler categoriesForClass!COM-Interfaces!WebView2-Interfaces! !
!ICoreWebView2NewWindowRequestedEventHandler methodsFor!

basicRegister: tokenBuffer
	source Add_NewWindowRequested: self token: tokenBuffer!

basicUnregister
	source Remove_NewWindowRequested: token! !
!ICoreWebView2NewWindowRequestedEventHandler categoriesForMethods!
basicRegister:!private!realizing/unrealizing! !
basicUnregister!private!realizing/unrealizing! !
!

!ICoreWebView2NewWindowRequestedEventHandler class methodsFor!

defineFunctions
	"Declare the virtual function table for the COM interface 'WebView2.ICoreWebView2NewWindowRequestedEventHandler'
		ICoreWebView2NewWindowRequestedEventHandler defineTemplate"

	self
		defineFunction: #Invoke:args:
			argumentTypes: 'ICoreWebView2* ICoreWebView2NewWindowRequestedEventArgs*'
!

eventName
	"Answer the symbolic name for this event (i.e. the SASE event trigger name)"

	^#newWindowRequested:! !
!ICoreWebView2NewWindowRequestedEventHandler class categoriesForMethods!
defineFunctions!**auto generated**!initializing!public! !
eventName!constants!public! !
!
