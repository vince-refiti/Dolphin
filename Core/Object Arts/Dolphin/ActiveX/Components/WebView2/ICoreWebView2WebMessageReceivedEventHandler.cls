﻿"Filed out from Dolphin Smalltalk"!

ICoreWebView2EventHandler subclass: #ICoreWebView2WebMessageReceivedEventHandler
	instanceVariableNames: ''
	classVariableNames: ''
	imports: #()
	classInstanceVariableNames: ''
	classConstants: {}!
ICoreWebView2WebMessageReceivedEventHandler guid: (OS.COM.IID fromString: '{57213f19-00e6-49fa-8e07-898ea01ecbd2}')!
ICoreWebView2WebMessageReceivedEventHandler comment: '`ICoreWebView2WebMessageReceivedEventHandler` is a wrapper class for the COM interface ''WebView2.ICoreWebView2WebMessageReceivedEventHandler'' generated from type information in the '''' library. It contains methods to invoke the member functions exposed by that interface.

The type library contains no documentation for this interface

** This comment was automatically generated from a type library. Delete this line to prevent any manual edits from being overwritten if the wrapper class is regenerated.

IDL definition follows:
```
[
	object, 
	uuid(57213f19-00e6-49fa-8e07-898ea01ecbd2)
]
interface ICoreWebView2WebMessageReceivedEventHandler : IUnknown
 {
	[id(0x60010000)]
	HRESULT __stdcall Invoke(
		[in]ICoreWebView2* sender,
		[in]ICoreWebView2WebMessageReceivedEventArgs* args);
};
```
'!
!ICoreWebView2WebMessageReceivedEventHandler categoriesForClass!COM-Interfaces!WebView2-Interfaces! !
!ICoreWebView2WebMessageReceivedEventHandler methodsFor!

basicRegister: tokenBuffer
	source Add_WebMessageReceived: self token: tokenBuffer!

basicUnregister
	source Remove_WebMessageReceived: token! !
!ICoreWebView2WebMessageReceivedEventHandler categoriesForMethods!
basicRegister:!private!realizing/unrealizing! !
basicUnregister!private!realizing/unrealizing! !
!

!ICoreWebView2WebMessageReceivedEventHandler class methodsFor!

defineFunctions
	"Declare the virtual function table for the COM interface 'WebView2.ICoreWebView2WebMessageReceivedEventHandler'
		ICoreWebView2WebMessageReceivedEventHandler defineTemplate"

	self
		defineFunction: #Invoke:args:
			argumentTypes: 'ICoreWebView2* ICoreWebView2WebMessageReceivedEventArgs*'
!

eventName
	"Answer the symbolic name for this event (i.e. the SASE event trigger name)"

	^#webMessageReceived:! !
!ICoreWebView2WebMessageReceivedEventHandler class categoriesForMethods!
defineFunctions!**auto generated**!initializing!public! !
eventName!constants!public! !
!
