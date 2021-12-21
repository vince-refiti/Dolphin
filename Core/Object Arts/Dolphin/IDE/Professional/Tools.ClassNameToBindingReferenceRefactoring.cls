﻿"Filed out from Dolphin Smalltalk"!

Refactory.Browser.ClassRefactoring subclass: #'Tools.ClassNameToBindingReferenceRefactoring'
	instanceVariableNames: 'class unqualifiedName'
	classVariableNames: ''
	imports: #(#{Refactory.Browser})
	classInstanceVariableNames: ''
	classConstants: {}!
Tools.ClassNameToBindingReferenceRefactoring guid: (Core.GUID fromString: '{889a55db-e170-4af7-999d-97369a4f1832}')!
Tools.ClassNameToBindingReferenceRefactoring comment: 'Component refactoring to replace old-style symbolic references to classes, e.g. `Smalltalk at: #DiffBrowser` with literal binding references as part of renaming a class in Smalltalk into another namespace.'!
!Tools.ClassNameToBindingReferenceRefactoring categoriesForClass!Refactory-Refactorings! !
!Tools.ClassNameToBindingReferenceRefactoring methodsFor!

className: aString
	super className: aString.
	class := self model classNamed: className!

preconditions
	^RBCondition withBlock: [class notNil and: [class isMeta not]]
		errorString: className , ' is <1?'':not> a valid class name'!

rewriteReferences
	| replacer symbol reference |
	symbol := self unqualifiedName.
	reference := class asQualifiedReference.
	replacer := ParseTreeRewriter new.
	self transformations
		do: [:each | replacer replace: each first << symbol with: each last << reference].
	(self model allReferencesTo: symbol) do: [:method | self convertMethod: method using: replacer]!

transform
	self rewriteReferences!

transformations
	^#(
		#('Smalltalk at: <1p>' '<1p> value') 
		#('Smalltalk lookup: <1p>' '<1p> valueOrNil') 
		#('Smalltalk associationAt: <1p>' '<1p> binding') 
		#('Smalltalk at: <1p> ifAbsent: ``@block' '<1p> ifNotDefined: ``@block') 
		#('Smalltalk at: <1p> ifPresent: ``@block' '<1p> ifDefined:``@block') 
		#('Smalltalk associationAt: <1p> ifAbsent: ``@block' '<1p> bindingOrNil ifNil: ``@block') 
		#('Smalltalk associationAt: <1p> ifPresent: ``@block' '<1p> bindingOrNil ifNotNil: ``@block') 
		#('Smalltalk includesKey: <1p>' '<1p> isDefined')
		#('Smalltalk removeKey: <1p>' '<1p> undeclare')
		#('Smalltalk removeKey: <1p> ifAbsent: ``@block' '<1p> undeclare ifNil: ``@block')
		#('Smalltalk at: <1p> put: ``@expr' '<1p> declare: ``@expr')
		#('Smalltalk bindingFor: <1p>' '<1p> bindingOrNil')
	)!

unqualifiedName
	^unqualifiedName ifNil: [class unqualifiedName]!

unqualifiedName: aSymbol
	unqualifiedName := aSymbol! !
!Tools.ClassNameToBindingReferenceRefactoring categoriesForMethods!
className:!accessing!public! !
preconditions!preconditions!public! !
rewriteReferences!private!transforming! !
transform!public!transforming! !
transformations!constants!private! !
unqualifiedName!accessing!public! !
unqualifiedName:!accessing!initializing!public! !
!

!Tools.ClassNameToBindingReferenceRefactoring class methodsFor!

model: aRBModel replaceSymbolicReferencesTo: aClass
	^self new
		model: aRBModel;
		className: aClass fullName;
		yourself!

replaceSymbolicReferencesTo: aClass
	^self new className: aClass fullName! !
!Tools.ClassNameToBindingReferenceRefactoring class categoriesForMethods!
model:replaceSymbolicReferencesTo:!instance creation!public! !
replaceSymbolicReferencesTo:!instance creation!public! !
!
