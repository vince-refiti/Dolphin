; Dolphin Smalltalk
; Primitive routines and helpers in Assembler for IX86
; (Blair knows how these work, honest)
;
; DEBUG Build syntax:
;		ml /coff /c /Zi /Fr /Fl /Sc /Fo /D_DEBUG /Fo WinDebug\primasm.obj primasm.asm
; RELEASE Build syntax:
;		ml /coff /c /Zi /Fr /Fl /Sc /Fo WinRel\primasm.obj primasm.asm
;
; this will generate debug info (Zi) and full browse info (Fr), and this is
; appropriate for debug and release versions, and a listing with timings

; Notes about __fastcall calling convention:
; - The first two args of DWORD or less size are passed in ecx and edx.
; - Other arguments are placed on the stack in the normal CDecl/Stdcall order
; - Return value is in EAX
; - In addition to preserving the normal set of registers, ESI
;	EDI, EBP, you must also preserve EBX (surprisingly),
;	and ES, FS AND GS (not surprisingly) for 32-bit Mixed language
;	programming
; - ECX, EDX and EAX are destroyed
;
; Other register conventions:
;	- 	ESI is used to hold the Smalltalk stack pointer
;	-	ECX is generally used to hold the Oop of the receiver
;	-	Assembler subroutines obey the fastcall calling convention
;
; N.B.
; I have tended to replicate small common code sequences to reduce jumps, as these
; are relatively expensive (3 cycles if taken) and performance is very important
; for the primitives. I have also used the unpleasant technique of jumping
; to a subroutine when I want it to return to my caller, and even (in at least
; one case) of popping a return address (gasp!). In certain critical places
; this is worth doing because of the high cost of a ret instruction (5 cycles on a 486).
;
; In order to try and keep the Pentium pipeline running at full tilt, instruction ordering is not always
; that you might expect. For example, MOV does not affect the flags, so MOV instructions may appear
; between tests/cmps and conditional jumps.
;

INCLUDE IstAsm.Inc

.CODE PRIM_SEG

; Macro for calling CPP Primitives which can change the interpreter state (i.e. may
; change the context), thus requiring the reloading of the registers which cache interpreter
; state
CallContextPrim MACRO mangledName
	call	mangledName						;; Transfer control to primitive 
	LoadIPRegister
	LoadBPRegister							;; _SP is always reloaded after executing a primitive
	ret
ENDM


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Exports

; Helpers
public @callPrimitiveValue@8

; Entry points for byte code dispatcher (see primasm.asm)
public _primitivesTable

; We export this so it can be called from Smalltalk
public HashBytes

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Imports

;; Win32 functions
RaiseException		PROTO STDCALL :DWORD, :DWORD, :DWORD, :DWORD
lstrcmpi			PROTO STDCALL :LPCSTR, :LPCSTR
lstrcmp				PROTO STDCALL :LPCSTR, :LPCSTR
longjmp				PROTO C :DWORD, :DWORD

; Imports from byteasm.asm
extern primitiveReturn:near32
extern activateBlock:near32
extern shortReturn:near32

extern _AtCache:AtCacheEntry
extern _AtPutCache:AtCacheEntry

extern primitiveReturnSelf:near32
extern primitiveReturnTrue:near32
extern primitiveReturnFalse:near32
extern primitiveReturnNil:near32
extern primitiveReturnLiteralZero:near32
extern primitiveReturnStaticZero:near32
extern primitiveActivateMethod:near32
extern primitiveReturnInstVar:near32
extern primitiveSetInstVar:near32

; Imports from flotprim.cpp
primitiveAsFloat EQU ?primitiveAsFloat@Interpreter@@CIPAIXZ
extern primitiveAsFloat:near32
primitiveFloatAdd EQU ?primitiveFloatAdd@Interpreter@@CIPAIXZ
extern primitiveFloatAdd:near32
primitiveFloatSub EQU ?primitiveFloatSubtract@Interpreter@@CIPAIXZ
extern primitiveFloatSub:near32
primitiveFloatMul EQU ?primitiveFloatMultiply@Interpreter@@CIPAIXZ
extern primitiveFloatMul:near32
primitiveFloatDiv EQU ?primitiveFloatDivide@Interpreter@@CIPAIXZ
extern primitiveFloatDiv:near32
primitiveFloatEQ EQU ?primitiveFloatEqual@Interpreter@@CIPAIXZ
extern primitiveFloatEQ:near32
primitiveFloatLT EQU ?primitiveFloatLessThan@Interpreter@@CIPAIXZ
extern primitiveFloatLT:near32
primitiveFloatGT EQU ?primitiveFloatGreaterThan@Interpreter@@CIPAIXZ
extern primitiveFloatGT:near32

; Imports from ExternalBytes.asm
extern primitiveAddressOf:near32
extern primitiveDWORDAt:near32
extern primitiveDWORDAtPut:near32
extern primitiveSDWORDAt:near32
extern primitiveSDWORDAtPut:near32
extern primitiveWORDAt:near32
extern primitiveWORDAtPut:near32
extern primitiveSWORDAt:near32
extern primitiveSWORDAtPut:near32
extern primitiveIndirectDWORDAt:near32
extern primitiveIndirectDWORDAtPut:near32
extern primitiveIndirectSDWORDAt:near32
extern primitiveIndirectSDWORDAtPut:near32
extern primitiveIndirectWORDAt:near32
extern primitiveIndirectWORDAtPut:near32
extern primitiveIndirectSWORDAt:near32
extern primitiveIndirectSWORDAtPut:near32
extern primitiveByteAtAddress:near32
extern primitiveByteAtAddressPut:near32

; Imports from ExternalCall.asm
extern primitiveDLL32Call:near32
extern primitiveVirtualCall:near32

; Imports from SmallIntPrim.asm
extern primitiveAdd:near32
extern primitiveSubtract:near32
extern primitiveLessThan:near32
extern primitiveGreaterThan:near32
extern primitiveLessOrEqual:near32
extern primitiveGreaterOrEqual:near32
extern primitiveEqual:near32
;extern primitiveNotEqual:near32
extern primitiveMultiply:near32
extern primitiveDivide:near32
extern primitiveMod:near32
extern primitiveDiv:near32
extern primitiveQuoAndRem:near32
extern primitiveQuo:near32
extern primitiveBitAnd:near32
extern primitiveAnyMask:near32
extern primitiveAllMask:near32
extern primitiveBitOr:near32
extern primitiveBitXor:near32
extern primitiveBitShift:near32
extern primitiveSmallIntegerAt:near32
extern primitiveHighBit:near32
extern primitiveLowBit:near32

; Imports from LargeIntPrim.CPP
liBitInvert EQU ?liBitInvert@@YGPAV?$TOTE@VLargeInteger@ST@@@@PAV1@@Z
extern liBitInvert:near32

liNegate  EQU ?liNegate@@YGIPAV?$TOTE@VLargeInteger@ST@@@@@Z
extern liNegate:near32

liNormalize  EQU ?liNormalize@@YGIPAV?$TOTE@VLargeInteger@ST@@@@@Z
extern liNormalize:near32

normalizeIntermediateResult EQU ?normalizeIntermediateResult@@YGII@Z
extern normalizeIntermediateResult:near32

; C++ Variable imports
CALLBACKSPENDING EQU ?m_nCallbacksPending@Interpreter@@0IA
extern CALLBACKSPENDING:DWORD

CURRENTCALLBACK EQU ?currentCallbackContext@@3IA
extern CURRENTCALLBACK:DWORD

; C++ Primitive method imports
primitiveTruncated EQU ?primitiveTruncated@Interpreter@@CIPAIXZ
extern primitiveTruncated:near32
primitiveNext EQU ?primitiveNext@Interpreter@@CIPAIXZ
extern primitiveNext:near32
primitiveNextSDWORD EQU ?primitiveNextSDWORD@Interpreter@@CIPAIXZ
extern primitiveNextSDWORD:near32
primitiveNextPut EQU ?primitiveNextPut@Interpreter@@CIPAIXZ
extern primitiveNextPut:near32
primitiveNextPutAll EQU ?primitiveNextPutAll@Interpreter@@CIPAIXZ	
extern primitiveNextPutAll:near32
primitiveAtEnd EQU ?primitiveAtEnd@Interpreter@@CIPAIXZ
extern primitiveAtEnd:near32

primitiveValueWithArgs EQU ?primitiveValueWithArgs@Interpreter@@CIPAIXZ
extern primitiveValueWithArgs:near32
primitivePerform EQU ?primitivePerform@Interpreter@@CIPAIAAVCompiledMethod@ST@@I@Z
extern primitivePerform:near32
primitivePerformWithArgs EQU ?primitivePerformWithArgs@Interpreter@@CIPAIXZ
extern primitivePerformWithArgs:near32
primitivePerformMethod EQU ?primitivePerformMethod@Interpreter@@CIPAIAAVCompiledMethod@ST@@I@Z
extern primitivePerformMethod:near32
primitivePerformWithArgsAt EQU ?primitivePerformWithArgsAt@Interpreter@@CIPAIAAVCompiledMethod@ST@@I@Z
extern primitivePerformWithArgsAt:near32
primitiveValueWithArgsAt EQU ?primitiveValueWithArgsAt@Interpreter@@CIPAIAAVCompiledMethod@ST@@I@Z
extern primitiveValueWithArgsAt:near32
primitiveVariantValue EQU ?primitiveVariantValue@Interpreter@@CIPAIXZ
extern primitiveVariantValue:near32

PRIMUNWINDINTERRUPT EQU ?primitiveUnwindInterrupt@Interpreter@@CIPAIAAVCompiledMethod@ST@@I@Z
extern PRIMUNWINDINTERRUPT:near32

RESUSPENDACTIVEON EQU ?ResuspendActiveOn@Interpreter@@SIPAV?$TOTE@VLinkedList@ST@@@@PAV2@@Z
extern RESUSPENDACTIVEON:near32

RESCHEDULE EQU ?Reschedule@Interpreter@@SGHXZ
extern RESCHEDULE:near32

primitiveSignal EQU ?primitiveSignal@Interpreter@@CIPAIAAVCompiledMethod@ST@@I@Z
extern primitiveSignal:near32

extern ?primitiveSetSignals@Interpreter@@CIPAIXZ:near32
primitiveSignalAtTick EQU ?primitiveSignalAtTick@Interpreter@@CIPAIAAVCompiledMethod@ST@@I@Z
extern primitiveSignalAtTick:near32
primitiveInputSemaphore EQU ?primitiveInputSemaphore@Interpreter@@CIPAIAAVCompiledMethod@ST@@I@Z
extern primitiveInputSemaphore:near32
primitiveSampleInterval EQU ?primitiveSampleInterval@Interpreter@@CIPAIXZ
extern primitiveSampleInterval:near32

PRIMITIVEWAIT EQU ?primitiveWait@Interpreter@@CIPAIAAVCompiledMethod@ST@@I@Z
extern PRIMITIVEWAIT:near32

primitiveFlushCache EQU ?primitiveFlushCache@Interpreter@@CIPAIXZ
extern primitiveFlushCache:near32

PRIMITIVERESUME EQU ?primitiveResume@Interpreter@@CIPAIAAVCompiledMethod@ST@@I@Z
extern PRIMITIVERESUME:near32

PRIMITIVESINGLESTEP EQU ?primitiveSingleStep@Interpreter@@CIPAIAAVCompiledMethod@ST@@I@Z
extern PRIMITIVESINGLESTEP:near32

extern ?primitiveSuspend@Interpreter@@CIPAIXZ	:near32
extern ?primitiveTerminateProcess@Interpreter@@CIPAIXZ	:near32
extern ?primitiveProcessPriority@Interpreter@@CIPAIXZ:near32
primitiveNewVirtual EQU ?primitiveNewVirtual@Interpreter@@CIPAIXZ
extern primitiveNewVirtual:near32
primitiveSnapshot EQU ?primitiveSnapshot@Interpreter@@CIPAIAAVCompiledMethod@ST@@I@Z
extern primitiveSnapshot:near32
primitiveReplaceBytes EQU ?primitiveReplaceBytes@Interpreter@@CIPAIXZ
extern primitiveReplaceBytes:near32
primitiveIndirectReplaceBytes EQU ?primitiveIndirectReplaceBytes@Interpreter@@CIPAIXZ
extern primitiveIndirectReplaceBytes :near32
primitiveReplacePointers EQU ?primitiveReplacePointers@Interpreter@@CIPAIXZ
extern primitiveReplacePointers:near32
primitiveCoreLeft EQU ?primitiveCoreLeft@Interpreter@@CIPAIAAVCompiledMethod@ST@@I@Z
extern primitiveCoreLeft:near32
primitiveQuit EQU ?primitiveQuit@Interpreter@@CIXAAVCompiledMethod@ST@@I@Z
extern primitiveQuit:near32
primitiveOopsLeft EQU ?primitiveOopsLeft@Interpreter@@CIPAIXZ
extern primitiveOopsLeft:near32
primitiveResize EQU ?primitiveResize@Interpreter@@CIPAIXZ
extern primitiveResize:near32
primitiveDoublePrecisionFloatAt EQU ?primitiveDoublePrecisionFloatAt@Interpreter@@CIPAIXZ
extern ?primitiveDoublePrecisionFloatAt@Interpreter@@CIPAIXZ:near32
primitiveDoublePrecisionFloatAtPut EQU ?primitiveDoublePrecisionFloatAtPut@Interpreter@@CIPAIXZ
extern ?primitiveDoublePrecisionFloatAtPut@Interpreter@@CIPAIXZ:near32
primitiveLongDoubleAt EQU ?primitiveLongDoubleAt@Interpreter@@CIPAIXZ
extern primitiveLongDoubleAt:near32
primitiveSinglePrecisionFloatAt EQU ?primitiveSinglePrecisionFloatAt@Interpreter@@CIPAIXZ
extern primitiveSinglePrecisionFloatAt:near32
primitiveSinglePrecisionFloatAtPut EQU ?primitiveSinglePrecisionFloatAtPut@Interpreter@@CIPAIXZ
extern primitiveSinglePrecisionFloatAtPut:near32
primitiveNextIndexOfFromTo EQU ?primitiveNextIndexOfFromTo@Interpreter@@CIPAIXZ
extern primitiveNextIndexOfFromTo:near32
primitiveDeQBereavement EQU ?primitiveDeQBereavement@Interpreter@@CIPAIXZ
extern primitiveDeQBereavement:near32
primitiveHookWindowCreate EQU ?primitiveHookWindowCreate@Interpreter@@CIPAIXZ
extern primitiveHookWindowCreate:near32

primitiveSmallIntegerPrintString EQU ?primitiveSmallIntegerPrintString@Interpreter@@CIPAIXZ
extern primitiveSmallIntegerPrintString:near32

primitiveNewInitializedObject EQU ?primitiveNewInitializedObject@Interpreter@@CIPAIAAVCompiledMethod@ST@@I@Z
extern primitiveNewInitializedObject:near32
primitiveNewFromStack EQU ?primitiveNewFromStack@Interpreter@@CIPAIXZ
extern primitiveNewFromStack:near32

primitiveLargeIntegerDivide EQU ?primitiveLargeIntegerDivide@Interpreter@@CIPAIXZ
extern primitiveLargeIntegerDivide:near32
primitiveLargeIntegerDiv EQU ?primitiveLargeIntegerDiv@Interpreter@@CIPAIXZ
extern primitiveLargeIntegerDiv:near32
primitiveLargeIntegerMod EQU ?primitiveLargeIntegerMod@Interpreter@@CIPAIXZ
extern primitiveLargeIntegerMod:near32
primitiveLargeIntegerQuoAndRem EQU ?primitiveLargeIntegerQuoAndRem@Interpreter@@CIPAIXZ
extern primitiveLargeIntegerQuoAndRem:near32
primitiveLargeIntegerBitShift EQU ?primitiveLargeIntegerBitShift@Interpreter@@CIPAIXZ
extern primitiveLargeIntegerBitShift:near32

primitiveLargeIntegerGreaterThan EQU ?primitiveLargeIntegerGreaterThan@Interpreter@@CIPAIXZ
extern primitiveLargeIntegerGreaterThan:near32
primitiveLargeIntegerLessThan EQU ?primitiveLargeIntegerLessThan@Interpreter@@CIPAIXZ
extern primitiveLargeIntegerLessThan:near32
primitiveLargeIntegerGreaterOrEqual EQU ?primitiveLargeIntegerGreaterOrEqual@Interpreter@@CIPAIXZ
extern primitiveLargeIntegerGreaterOrEqual:near32
primitiveLargeIntegerLessOrEqual EQU ?primitiveLargeIntegerLessOrEqual@Interpreter@@CIPAIXZ
extern primitiveLargeIntegerLessOrEqual:near32
primitiveLargeIntegerEqual EQU ?primitiveLargeIntegerEqual@Interpreter@@CIPAIXZ
extern primitiveLargeIntegerEqual:near32

primitiveLargeIntegerAsFloat EQU ?primitiveLargeIntegerAsFloat@Interpreter@@CIPAIXZ
extern primitiveLargeIntegerAsFloat:near32

primitiveAsyncDLL32Call EQU ?primitiveAsyncDLL32Call@Interpreter@@CIPAIAAVCompiledMethod@ST@@I@Z
extern primitiveAsyncDLL32Call:near32

primitiveAllReferences EQU ?primitiveAllReferences@Interpreter@@CIPAIAAVCompiledMethod@ST@@I@Z
extern primitiveAllReferences:near32

IFDEF _DEBUG
	extern ?checkReferences@ObjectMemory@@SIXXZ:near32
ENDIF

; Other C++ method imports
NEWPOINTEROBJECT		EQU	?newPointerObject@ObjectMemory@@SIPAV?$TOTE@VVariantObject@ST@@@@PAV?$TOTE@VBehavior@ST@@@@I@Z
extern NEWPOINTEROBJECT:near32
NEWBYTEOBJECT			EQU	?newByteObject@ObjectMemory@@SIPAV?$TOTE@VVariantByteObject@ST@@@@PAV?$TOTE@VBehavior@ST@@@@I@Z
extern NEWBYTEOBJECT:near32
ALLOCATEBYTESNOZERO		EQU	?newUninitializedByteObject@ObjectMemory@@SIPAV?$TOTE@VVariantByteObject@ST@@@@PAV?$TOTE@VBehavior@ST@@@@I@Z
extern ALLOCATEBYTESNOZERO:near32

DQFORFINALIZATION EQU ?dequeueForFinalization@Interpreter@@CIPAV?$TOTE@VObject@ST@@@@XZ
extern DQFORFINALIZATION:near32

INSTANCESOF EQU ?instancesOf@ObjectMemory@@SIPAV?$TOTE@VArray@ST@@@@PAV?$TOTE@VBehavior@ST@@@@@Z
extern INSTANCESOF:near32
SUBINSTANCESOF EQU ?subinstancesOf@ObjectMemory@@SIPAV?$TOTE@VArray@ST@@@@PAV?$TOTE@VBehavior@ST@@@@@Z
extern SUBINSTANCESOF:near32
INSTANCECOUNTS EQU ?instanceCounts@ObjectMemory@@SIPAV?$TOTE@VArray@ST@@@@PAV2@@Z
extern INSTANCECOUNTS:near32

QUEUEINTERRUPT EQU ?queueInterrupt@Interpreter@@SGXPAV?$TOTE@VProcess@ST@@@@II@Z
extern QUEUEINTERRUPT:near32
ONEWAYBECOME EQU ?oneWayBecome@ObjectMemory@@SIXPAV?$TOTE@VObject@ST@@@@0@Z
extern ONEWAYBECOME:near32
SHALLOWCOPY EQU ?shallowCopy@ObjectMemory@@SIPAV?$TOTE@VObject@ST@@@@PAV2@@Z
extern SHALLOWCOPY:near32

OOPSUSED EQU ?OopsUsed@ObjectMemory@@SIHXZ
extern OOPSUSED:near32

YIELD EQU ?yield@Interpreter@@CIHXZ
extern YIELD:near32												; See process.cpp

LOOKUPMETHOD EQU ?lookupMethod@Interpreter@@SIPAV?$TOTE@VCompiledMethod@ST@@@@PAV?$TOTE@VBehavior@ST@@@@PAV?$TOTE@VSymbol@ST@@@@@Z
extern LOOKUPMETHOD:near32

PRIMSTRINGSEARCH EQU ?primitiveStringSearch@Interpreter@@CIPAIXZ
extern PRIMSTRINGSEARCH:near32

primitiveStringNextIndexOfFromTo EQU ?primitiveStringNextIndexOfFromTo@Interpreter@@CIPAIXZ
extern primitiveStringNextIndexOfFromTo:near32

; Note this function returns 'bool', i.e. single byte in al; doesn't necessarily set whole of eax
DISABLEINTERRUPTS EQU ?disableInterrupts@Interpreter@@SI_N_N@Z
extern DISABLEINTERRUPTS:near32

primitiveStackAtPut EQU ?primitiveStackAtPut@Interpreter@@CIPAIAAVCompiledMethod@ST@@I@Z
extern primitiveStackAtPut:near32

primitiveMillisecondClockValue EQU  ?primitiveMillisecondClockValue@Interpreter@@CIPAIXZ
extern primitiveMillisecondClockValue:near32

primitiveMicrosecondClockValue EQU  ?primitiveMicrosecondClockValue@Interpreter@@CIPAIXZ
extern primitiveMicrosecondClockValue:near32

primitiveBasicIdentityHash EQU ?primitiveBasicIdentityHash@Interpreter@@CIPAIXZ
extern primitiveBasicIdentityHash:near32
primitiveIdentityHash EQU ?primitiveIdentityHash@Interpreter@@CIPAIXZ
extern primitiveIdentityHash:near32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Constants
;; Table of primitives for normal primitive dispatching
.DATA
ALIGN 16
_primitivesTable DD			primitiveActivateMethod			; case 0
DWORD		primitiveReturnSelf								; case 1
DWORD		primitiveReturnTrue								; case 2	
DWORD		primitiveReturnFalse							; case 3
DWORD		primitiveReturnNil								; case 4	
DWORD		primitiveReturnLiteralZero						; case 5
DWORD		primitiveReturnInstVar							; case 6
DWORD		primitiveSetInstVar								; case 7
DWORD		primitiveReturnStaticZero						; case 8	Was SmallInteger>>~= (redundant)
DWORD		primitiveMultiply								; case 9
DWORD		primitiveDivide									; case 10
DWORD		primitiveMod									; case 11
DWORD		primitiveDiv									; case 12
DWORD		primitiveQuoAndRem								; case 13
DWORD		primitiveSubtract								; case 14
DWORD		primitiveAdd									; case 15
DWORD		primitiveEqual									; case 16
DWORD		primitiveGreaterOrEqual							; case 17
DWORD		primitiveLessThan								; case 18	Number>>#@
DWORD		primitiveGreaterThan							; case 19	Not Used in Smalltalk-80
DWORD		primitiveLessOrEqual							; case 20	Not used in Smalltalk-80
DWORD		primitiveLargeIntegerAdd						; case 21	LargeInteger>>#+
DWORD		primitiveLargeIntegerSub						; case 22	LargeInteger>>#-
DWORD		primitiveLargeIntegerLessThan					; case 23	LargeInteger>>#<
DWORD		primitiveLargeIntegerGreaterThan				; case 24	LargeInteger>>#>
DWORD		primitiveLargeIntegerLessOrEqual				; case 25	LargeInteger>>#<=
DWORD		primitiveLargeIntegerGreaterOrEqual				; case 26	LargeInteger>>#>=
DWORD		primitiveLargeIntegerEqual						; case 27	LargeInteger>>#=
DWORD		primitiveLargeIntegerNormalize					; case 28	LargeInteger>>normalize. LargeInteger>>#~= in Smalltalk-80 (redundant)
DWORD		primitiveLargeIntegerMul						; case 29	LargeInteger>>#*
DWORD		primitiveLargeIntegerDivide						; case 30	LargeInteger>>#/
DWORD		primitiveLargeIntegerMod						; case 31	LargeInteger>>#\\
DWORD		primitiveLargeIntegerDiv						; case 32	LargeInteger>>#//
DWORD		primitiveLargeIntegerQuoAndRem					; case 33	Was LargeInteger>>#quo:
DWORD		primitiveLargeIntegerBitAnd						; case 34	LargeInteger>>#bitAnd:
DWORD		primitiveLargeIntegerBitOr						; case 35	LargeInteger>>#bitOr:
DWORD		primitiveLargeIntegerBitXor						; case 36	LargeInteger>>#bitXor:
DWORD		primitiveLargeIntegerBitShift					; case 37	LargeInteger>>#bitShift
DWORD		primitiveLargeIntegerBitInvert					; case 38	Not used in Smalltalk-80
DWORD		primitiveLargeIntegerNegate						; case 39	Not used in Smalltalk-80
DWORD		primitiveBitAnd									; case 40	SmallInteger>>asFloat
DWORD		primitiveBitOr									; case 41	Float>>#+
DWORD		primitiveBitXor									; case 42	Float>>#-
DWORD		primitiveBitShift								; case 43	Float>>#<
DWORD		primitiveSmallIntegerPrintString				; case 44	Float>>#> in Smalltalk-80
DWORD		primitiveFloatGT								; case 45	Float>>#<= in Smalltalk-80
DWORD		unusedPrimitive									; case 46	Float>>#>= in Smalltalk-80
DWORD		unusedPrimitive									; case 47	Float>>#= in Smalltalk-80
DWORD		primitiveAsyncDLL32CallThunk					; case 48	Float>>#~= in Smalltalk-80
DWORD		primitiveBasicAt								; case 49	Float>>#* in Smalltalk-80
DWORD		primitiveBasicAtPut								; case 50	Float>>#/ in Smalltalk-80
DWORD		primitiveStringCollates							; case 51	Float>>#truncated
DWORD		primitiveStringNextIndexOfFromTo								; case 52	Float>>#fractionPart in Smalltalk-80
DWORD		primitiveQuo									; case 53	Float>>#exponent in Smalltalk-80
DWORD		primitiveHighBit								; case 54	Float>>#timesTwoPower: in Smalltalk-80
DWORD		primitiveStringCompare							; case 55	Not used in Smalltalk-80
DWORD		primitiveStringCollate							; case 56
DWORD		primitiveIsKindOf								; case 57	Not used in Smalltalk-80
DWORD		primitiveAllSubinstances						; case 58	Not used in Smalltalk-80
DWORD		primitiveNextIndexOfFromTo						; case 59	Not used in Smalltalk-80
DWORD		primitiveAtCached								; case 60	LargeInteger>>#digitAt: and Object>>#at:
DWORD		primitiveAtPutCached							; case 61	
DWORD		primitiveSize									; case 62	LargeInteger>>#digitLength
DWORD		primitiveStringAt								; case 63	
DWORD		primitiveStringAtPut							; case 64
DWORD		primitiveNext									; case 65	
DWORD		primitiveNextPut								; case 66
DWORD		primitiveAtEnd									; case 67
DWORD		primitiveReturnFromInterrupt					; case 68	Was CompiledMethod>>#objectAt: (reserve for upTo:)
DWORD		primitiveSetSpecialBehavior						; case 69	Was CompiledMethod>>#objectAt:put:
DWORD		primitiveNew									; case 70	
DWORD		primitiveNewWithArg								; case 71
DWORD		primitiveBecome									; case 72
DWORD		primitiveInstVarAt								; case 73
DWORD		primitiveInstVarAtPut							; case 74
DWORD		primitiveBasicIdentityHash						; case 75	Object>>basicIdentityHash
DWORD		primitiveNewWithArg								; case 76	Will be primitiveNewFixed:
DWORD		primitiveAllInstances							; case 77	was Behavior>>someInstance
DWORD		primitiveReturn									; case 78	was Object>>nextInstance
DWORD		primitiveValueOnUnwind							; case 79	CompiledMethod class>>newMethod:header:
DWORD		primitiveVirtualCall							; case 80	Was ContextPart>>blockCopy:
DWORD		primitiveValue									; case 81
DWORD		primitiveValueWithArgsThunk						; case 82
DWORD		primitivePerformThunk							; case 83
DWORD		primitivePerformWithArgsThunk					; case 84
DWORD		primitiveSignalThunk							; case 85
DWORD		primitiveWaitThunk								; case 86	N.B. DON'T CHANGE, ref'd from signalSemaphore() in process.cpp 
DWORD		primitiveResumeThunk							; case 87
DWORD		primitiveSuspendThunk							; case 88
DWORD		primitiveFlushCache								; case 89	Behavior>>flushCache
DWORD		primitiveNewVirtual								; case 90	Was InputSensor>>primMousePt, InputState>>primMousePt
DWORD		primitiveTerminateThunk							; case 91	Was InputState>>primCursorLocPut:, InputState>>primCursorLocPutAgain:
DWORD		primitiveProcessPriorityThunk					; case 92	Was Cursor class>>cursorLink:
DWORD		primitiveInputSemaphore							; case 93	Is InputState>>primInputSemaphore:
DWORD		primitiveSampleInterval							; case 94	Is InputState>>primSampleInterval:
DWORD		primitiveEnableInterrupts						; case 95	Was InputState>>primInputWord
DWORD		primitiveDLL32Call								; case 96	Was BitBlt>>copyBits
DWORD		primitiveSnapshot								; case 97	Is SystemDictionary>>snapshotPrimitive
DWORD		primitiveQueueInterrupt							; case 98	Was Time class>>secondClockInto:
DWORD		primitiveSetSignalsThunk						; case 99	Was Time class>>millisecondClockInto:
DWORD		primitiveSignalAtTickThunk						; case 100	Is ProcessorScheduler>>signal:atMilliseconds:
DWORD		primitiveResize									; case 101	Was Cursor>>beCursor
DWORD		primitiveChangeBehavior							; case 102	Was DisplayScreen>>beDisplay
DWORD		primitiveAddressOf								; case 103	Was CharacterScanner>>scanCharactersFrom:to:in:rightX:stopConditions:di_SPlaying:
DWORD		primitiveReturnFromCallback						; case 104	Was BitBlt drawLoopX:Y:
DWORD		primitiveSingleStepThunk						; case 105
DWORD		primitiveHashBytes								; case 106	Not used in Smalltalk-80
DWORD		primitiveUnwindCallback							; case 107	ProcessorScheduler>>primUnwindCallback
DWORD		primitiveHookWindowCreate						; case 108	Not used in Smalltalk-80
DWORD		primitiveIsSuperclassOf							; case 109	Not used in Smalltalk-80
DWORD		primitiveEquivalent								; case 110	Character =, Object ==
DWORD		primitiveClass									; case 111	Object class
DWORD		primitiveCoreLeftThunk							; case 112	Was SystemDictionary>>coreLeft - This is now the basic, non-compacting, incremental, garbage collect
DWORD		primitiveQuit									; case 113	SystemDictionary>>quitPrimitive
DWORD		primitivePerformWithArgsAtThunk					; case 114	SystemDictionary>>exitToDebugger
DWORD		primitiveOopsLeftThunk							; case 115	SystemDictionary>>oopsLeft - Use this for a compacting garbage collect
DWORD		primitivePerformMethodThunk						; case 116	This was primitiveSignalAtOopsLeftWordsLeft (low memory signal)
DWORD		primitiveValueWithArgsAtThunk					; case 117	Not used in Smalltalk-80
DWORD		primitiveDeQForFinalize							; case 118	Not used in Smalltalk-80 - Dequeue an object from the VM's finalization queue
DWORD		primitiveDeQBereavement							; case 119	Not used in Smalltalk-80 - Dequeue a weak object which has new Corpses and notify it
DWORD		primitiveDWORDAt								; case 120	Not used in Smalltalk-80
DWORD		primitiveDWORDAtPut								; case 121	Not used in Smalltalk-80
DWORD		primitiveSDWORDAt								; case 122	Not used in Smalltalk-80
DWORD		primitiveSDWORDAtPut							; case 123	Not used in Smalltalk-80
DWORD		primitiveWORDAt									; case 124	Not used in Smalltalk-80
DWORD		primitiveWORDAtPut								; case 125	Not used in Smalltalk-80
DWORD		primitiveSWORDAt								; case 126	Not used in Smalltalk-80
DWORD		primitiveSWORDAtPut								; case 127	Not used in Smalltalk-80

;; Smalltalk-80 used 7-bits for primitive numbers, so last was 127

DWORD		primitiveDoublePrecisionFloatAt					; case 128
DWORD		primitiveDoublePrecisionFloatAtPut				; case 129
DWORD		primitiveSinglePrecisionFloatAt					; case 130
DWORD		primitiveSinglePrecisionFloatAtPut				; case 131
DWORD		primitiveByteAtAddress							; case 132
DWORD		primitiveByteAtAddressPut						; case 133
DWORD		primitiveIndirectDWORDAt						; case 134
DWORD		primitiveIndirectDWORDAtPut						; case 135
DWORD		primitiveIndirectSDWORDAt						; case 136
DWORD		primitiveIndirectSDWORDAtPut					; case 137
DWORD		primitiveIndirectWORDAt							; case 138
DWORD		primitiveIndirectWORDAtPut						; case 139
DWORD		primitiveIndirectSWORDAt						; case 140
DWORD		primitiveIndirectSWORDAtPut						; case 141
DWORD		primitiveReplaceBytes							; case 142
DWORD		primitiveIndirectReplaceBytes					; case 143
DWORD		primitiveNextSDWORD								; case 144
DWORD		primitiveAnyMask								; case 145
DWORD		primitiveAllMask								; case 146
DWORD		primitiveIdentityHash							; case 147
DWORD		primitiveLookupMethod							; case 148
DWORD		PRIMSTRINGSEARCH								; case 149
DWORD		primitiveUnwindInterruptThunk					; case 150
DWORD		primitiveExtraInstanceSpec						; case 151
DWORD		primitiveLowBit									; case 152
DWORD		primitiveAllReferences							; case 153
DWORD		primitiveOneWayBecome							; case 154
DWORD		primitiveShallowCopy							; case 155
DWORD		primitiveYield									; case 156
DWORD		primitiveNewInitializedObject					; case 157
DWORD		primitiveSmallIntegerAt							; case 158
DWORD		primitiveLongDoubleAt							; case 159
DWORD		primitiveFloatAdd								; case 160
DWORD		primitiveFloatSub								; case 161
DWORD		primitiveFloatLT								; case 162
DWORD		primitiveFloatEQ								; case 163
DWORD		primitiveFloatMul								; case 164
DWORD		primitiveFloatDiv								; case 165
DWORD		primitiveTruncated								; case 166
DWORD		primitiveLargeIntegerAsFloat					; case 167
DWORD		primitiveAsFloat								; case 168
DWORD		primitiveObjectCount							; case 169
DWORD		primitiveStructureIsNull						; case 170
DWORD		primitiveBytesIsNull							; case 171
DWORD		primitiveVariantValue							; case 172
DWORD		primitiveNextPutAll								; case 173
DWORD		primitiveMillisecondClockValue					; case 174
DWORD		primitiveIndexOfSP								; case 175
DWORD		primitiveStackAtPut								; case 176
DWORD		primitiveGetImmutable							; case 177
DWORD		primitiveSetImmutable							; case 178
DWORD		primitiveInstanceCounts							; case 179
DWORD		primitiveDWORDAt								; case 180	Will be primitiveUIntPtrAt
DWORD		primitiveDWORDAtPut								; case 181	Will be primitiveUIntPtrAtPut
DWORD		primitiveSDWORDAt								; case 182	Will be primitiveIntPtrAt
DWORD		primitiveSDWORDAtPut							; case 183	Will be primitiveIntPtrAtPut
DWORD		primitiveIndirectDWORDAt						; case 184  Will be primitiveIndirectUIntPtrAt
DWORD		primitiveIndirectDWORDAtPut						; case 185  Will be primitiveIndirectUIntPtrAtPut
DWORD		primitiveIndirectSDWORDAt						; case 186  Will be primitiveIndirectIntPtrAt
DWORD		primitiveIndirectSDWORDAtPut					; case 187  Will be primitiveIndirectIntPtrAtPut
DWORD		primitiveReplacePointers						; case 188
DWORD		primitiveMicrosecondClockValue					; case 189
DWORD		primitiveNewFromStack							; case 190
DWORD		unusedPrimitive									; case 191
DWORD		unusedPrimitive									; case 192

IFDEF _DEBUG
	_primitiveCounters DD	256 DUP (0)
	public _primitiveCounters
ENDIF

.CODE PRIM_SEG
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Procedures

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; System Primitives

;  BOOL __fastcall Interpreter::primitiveNew()
;
; ObjectMemory::allocateObject() no longer counts up the class of an object when 
; instantiating it. This is a little more error prone, but (if we are careful) we
; can substantially speed up the instantiation of new objects from Smalltalk code
; because the class reference on the stack is removed at the same time as the class
; becomes referenced from the new object. Consequently no actual ref. counting
; operations need be performed at all by these primitives (the ref. count of the
; new object is forced to 1).
;
BEGINPRIMITIVE primitiveNew
	mov		ecx, [_SP]						; Load receiver class at stack top
	mov		edx, (OTE PTR[ecx]).m_location

	; Are instances of the class indexable
	mov		edx, (Behavior PTR[edx]).m_instanceSpec
	test    edx, MASK m_indexable

	jnz		localPrimitiveFailure0			; Yes, require a size argument
				     	
	; Mask out all but inst size bits (including SmallInteger flag)
	and		edx, MASK m_fixedFields
	shr		edx, 1							

	call	NEWPOINTEROBJECT				; Allocate the object

	mov		[_SP], eax						; Overwrite receiver with new object
	AddToZctNoSP <a>
	mov		eax, _SP						; primitiveSuccess(0)
	ret

LocalPrimitiveFailure 0

ENDPRIMITIVE primitiveNew

;  BOOL __fastcall Interpreter::primitiveNewWithArg()
;
BEGINPRIMITIVE primitiveNewWithArg
	mov		eax, [_SP]						; Load argument at stack top
	mov		ecx, [_SP-OOPSIZE]				; Load receiver class under argument
	ASSUME	ecx:PTR OTE
	sar		eax, 1
	jnc		localPrimitiveFailure0		; Need integer size (SmallInteger bit would be shifted into carry flag)
	mov		edx, [ecx].m_location
	ASSUME	edx:PTR Behavior
	js		localPrimitiveFailure1		; Size must be >= 0

   	; Are instances of the class indexable
	mov		edx, [edx].m_instanceSpec
	ASSUME	edx:DWORD
	test    edx, MASK m_indexable
	jz		localPrimitiveFailure2				; No, must use #new, not #new:

   	; Do instances of the class contain pointers?
	test    edx, MASK m_pointers
	jz		newByteObject					; skip pointer object handling

	and		edx, MASK m_fixedFields			; Mask out all but inst size
	sar		edx, 1							; Convert from SmallInteger

	add		edx, eax						; edx now contains complete object size in oops
	call	NEWPOINTEROBJECT				; Allocate the object

	mov		[_SP-OOPSIZE], eax				; Overwrite receiver with new object
	AddToZct <a>
	lea		eax, [_SP-OOPSIZE]				; primitiveSuccess(1)
	ret

newByteObject:
	mov		edx, eax						; edx now contains complete object size in bytes (excluding any null terminator)
	ASSUME	ecx:PTR OTE						; ECX still contains pointer to class
	call	NEWBYTEOBJECT					; Allocate the object

	mov		[_SP-OOPSIZE], eax				; Overwrite receiver with new object
	AddToZct <a>
	lea		eax, [_SP-OOPSIZE]				; primitiveSuccess(1)
	ret

	ASSUME	eax:NOTHING

LocalPrimitiveFailure 0
LocalPrimitiveFailure 1
LocalPrimitiveFailure 2

ENDPRIMITIVE primitiveNewWithArg

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;  int __fastcall Interpreter::primitiveEquivalent()
;
;	Receiver != Arg is probably the more common case, so the condition
;	is organised so that the conditional jump is taken when Receiver==Arg
;	since not taking a jump is cheaper (1 cycle vs 3 cycles)
;
;	This primitive does not fail, so leaves the pointer value in
;	eax (which will not be 0), SO LIKE WIN32 FUNCTIONS, DO NOT 
;	COMPARE FOR EQUALITY WITH TRUE!
;
;	N.B. This primitive is not used unless #== is performed, because #== is inlined
;	by the compiler for performance reasons.
;
BEGINPRIMITIVE primitiveEquivalent
	mov		eax, [_SP]							; Load argument ...
	mov		edx, [oteTrue]						; Load oteTrue (default answer)
	mov		ecx, [_SP-OOPSIZE]					; Load receiver into ecx
	.IF ecx != eax								; receiver == arg?
		add		edx, OTENTRYSIZE				; No, load oteFalse
	.ENDIF
	mov		[_SP-OOPSIZE], edx					; Overwrite the receiver with true/false
	lea		eax, [_SP-OOPSIZE]					; primitiveSuccess(1)
	ret
ENDPRIMITIVE primitiveEquivalent

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;  int __fastcall Interpreter::primitiveClass()
;
BEGINPRIMITIVE primitiveClass
	mov		ecx, [_SP]							; Load receiver into ecx
	mov		eax, _SP							; primitiveSuccess(0)
	test	cl, 1								; SmallInteger?
	jne		smallInteger

	mov		ecx, (OTE PTR[ecx]).m_oteClass		; No, get class Oop	from Object into eax
	mov		[_SP], ecx
	ret

smallInteger:
	mov		ecx, [Pointers.ClassSmallInteger]
	mov		[_SP], ecx
	ret
ENDPRIMITIVE primitiveClass


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;  int __fastcall Interpreter::primitiveIsSuperclassOf()
;
; Double dispatched from Behavior, so we know receiver and args are correct types
;
BEGINPRIMITIVE primitiveIsSuperclassOf
	mov		eax, [_SP]									; Load argument ...

	; We ASSUME that the argument is indeed a Class object (because of a double dispatch)
	mov		ecx, [_SP-OOPSIZE]							; Load receiver into ecx
	mov		edx, [oteFalse]								; Default answer is false

	;; Now we have the class of the object in ECX, and the class we're looking for in EAX
	.WHILE (eax != ecx)
		mov		eax, (OTE PTR[eax]).m_location
		mov		eax, (Behavior PTR[eax]).m_superclass
		cmp		eax, [oteNil]							; Top of superclass chain?
		je		@F										; Yes, answer false
	.ENDW
	mov			edx, [oteTrue]

@@:
	mov			[_SP-OOPSIZE], edx						; overwrite receiver on stack

	lea			eax, [_SP-OOPSIZE]						; primitiveSuccess(1)
	ret
ENDPRIMITIVE primitiveIsSuperclassOf

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;  int __fastcall Interpreter::primitiveIsKindOf()
;
;	Primitive to speed up #isKindOf: (so we don't have to implement too many #isXXXXX methods, 
;	which are nasty, requiring a change to Object for each).
;
BEGINPRIMITIVE primitiveIsKindOf
	mov		eax, [_SP]									; Load argument ...
	test	al, 1
	jnz		answerFalse									; Nothing is a kind of SmallInteger instance

	cmp		eax, [oteNil]
	je		answerTrue									; everything is a type of nil

	mov		ecx, [_SP-OOPSIZE]								; Load receiver into ecx

	.IF (cl & 1)
		mov	ecx, [Pointers.ClassSmallInteger]
	.ELSE
		mov ecx, (OTE PTR[ecx]).m_oteClass
	.ENDIF
	
	;; Now we have the class of the object in ECX, and the class we're looking for in EAX
	.WHILE (ecx != eax)
		mov		ecx, (OTE PTR[ecx]).m_location
		mov		ecx, (Behavior PTR[ecx]).m_superclass
		cmp		ecx, [oteNil]							; Top of superclass chain?
		je		answerFalse								; Yes, answer false
	.ENDW

answerTrue:
	mov			ecx, [oteTrue]							; Use EAX register so non-zero on exit
	lea			eax, [_SP-OOPSIZE]						; primitiveSuccess(1)
	mov			[_SP-OOPSIZE], ecx						; overwrite on stack

	ret

answerFalse:
	mov			ecx, [oteFalse]
	lea			eax, [_SP-OOPSIZE]						; primitiveSuccess(1)
	mov			[_SP-OOPSIZE], ecx						; overwrite on stack

	ret
ENDPRIMITIVE primitiveIsKindOf

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;  int __fastcall Interpreter::primitiveLookupMethod()
;
;	Primitive to duplicate the VM's method lookup. Useful for fast #respondsTo:/
;	#canUnderstand:. Uses, but does not update, the method cache.
;
BEGINPRIMITIVE primitiveLookupMethod
	mov		edx, [_SP]								; Load selector arg into EDX
	mov		ecx, [_SP-OOPSIZE]						; Load receiver into ECX
	test	dl, 1
	jnz		localPrimitiveFailure1					; Immediate selectors not permitted

	call	LOOKUPMETHOD
	; eax contains method Oop, or nil

	mov		[_SP-OOPSIZE], eax						; Store back result
	lea		eax, [_SP-OOPSIZE]						; primitiveSuccess(1)

	ret

LocalPrimitiveFailure 1

ENDPRIMITIVE primitiveLookupMethod

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;  int __fastcall Interpreter::primitiveSize()
;
;	This primitive is unusual (like primitiveClass) in that it cannot fail
;	The primitive ASSUMES it is never called for SmallIntegers.
;	Essentially same code as shortSpecialSendBasicSize
;
BEGINPRIMITIVE primitiveSize
	mov		ecx, [_SP]								; Load receiver into ecx
	ASSUME	ecx:PTR OTE								; ecx points at receiver OTE

	mov		eax, [ecx].m_size						; Load size into eax

	test	[ecx].m_flags, MASK m_pointer			; ote->isPointers?
	jz		isBytes

	;; Calculate the length of the indexed part of a pointer object
	mov		edx, [ecx].m_oteClass					; Get class Oop	from OTE into edx
	ASSUME	edx:PTR OTE								; edx now points at class OTE
	
	and		eax, 7fffffffh							; Mask out the immutability bit

	mov		edx, [edx].m_location					; Load address of class object into edx
	ASSUME	edx:PTR Behavior						; edx now points at class object

	mov		edx, [edx].m_instanceSpec				; Load InstanceSpecification into edx
	ASSUME	edx:NOTHING
	and		edx, MASK m_fixedFields
	
	add		edx, edx								; Convert to byte size (already *2 since SmallInteger)
	sub		eax, edx								; Calculate length of variable part in bytes
	
	shr		eax, 1									; Divide byte size by 2 to get MWORD size as SmallInteger
	or		eax, 1									; Add SmallInteger flag
	mov		[_SP], eax								; Replace stack top

	mov		eax, _SP								; primitiveSuccess(0)
	ret

isBytes:
	lea		ecx, [eax+eax+1]						; Convert to SmallInteger
	mov		eax, _SP								; primitiveSuccess(0)
	mov		[_SP], ecx								; Replace stack top
	ret

	ASSUME	edx:NOTHING
	ASSUME	ecx:NOTHING
ENDPRIMITIVE primitiveSize

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  BOOL __fastcall Interpreter::primitiveAtCached()
;;
;; Primitive for getting elements of indexed objects using the AtCache
;; Not that this is organized so as to be optimal when the array is not in
;; the cache, which is expected to be the normal case (otherwise the at: bytecode
;; should have been able to do the job).
;;
BEGINPRIMITIVE primitiveAtCached
	mov		eax, DWORD PTR [_SP-OOPSIZE]	; Load receiver OTE from stack into EAX
	ASSUME	eax:PTR OTE

	mov		edx, DWORD PTR [_SP]			; Load argument into EDX

	mov		ecx, eax						; Get receiver Oop into ECX (where it remains)
	ASSUME	ecx:PTR OTE
	and		eax, AtCacheMask				; Mask off index to AtCache size (must be power of 2)
	ASSUME	eax:DWORD						; EAX is now an offset into the AtCache
											; This simple because sizeof(OTE) != sizeof(AtCacheEntry)

	sar		edx, 1
	jnc		localPrimitiveFailure0			; Index not an integer

	sub		edx, 1							; Convert 1 based index to zero based offset
	js		localPrimitiveFailure0			; Index out of bounds (<= 0)

	; Is the array already in the AtCache?
	; Note that we don't need to scale eax at all because it is an Oop and OTEs are 16-bytes,
	; the same size as an AtCacheEntry
	cmp	_AtCache[eax].oteArray, ecx
	
	je	accessCachedObject					; If not in cache, must set up before can access entry

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Object not in cache, so put it there

	ASSUME	eax:DWORD		; EAX is the offset into the AtCache
	ASSUME	ecx:PTR OTE		; ECX is the receiver
	ASSUME	edx:DWORD		; EDX is the requested zero-based offset (which we musn't overwrite)

	push	edi									; preserve edi
	push	ebx									; and ebx

	mov		ebx, [ecx].m_size
	ASSUME	ebx:DWORD							; EBX is now byte size of object
	
	mov		edi, [ecx].m_location				; Get pointer to object into edi
	ASSUME edi:PTR Object
	
	and		ebx, 7fffffffh						; Mask out the immutability bit

	test	[ecx].m_flags, MASK m_pointer		; Test pointer bit of object table entry
	jz		updateAtCacheForByteArray

updateAtCacheForPointerObject:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ASSUME	eax:DWORD		; EAX is the offset into the AtCache
	ASSUME	ecx:PTR OTE		; ECX is the Oop of the receiver
	ASSUME	edx:DWORD		; EDX is the requested zero-based offset (which we musn't overwrite)
	ASSUME	ebx:DWORD		; EBX is the byte size of the object
	ASSUME	edi:PTR Object	; EDI points to the body of the receiver

	mov		ecx, [ecx].m_oteClass				; Get class of object into ecx (need to know number of named inst vars)
	ASSUME	ecx:PTR OTE							;

	shr		ebx, 2								; Adjust byte size to word size

	mov		ecx, [ecx].m_location
	ASSUME	ecx:PTR Behavior

	lea		eax, _AtCache[eax]
	ASSUME	eax:PTR AtCacheEntry				; EAX now points at the AtCacheEntry to populate

	mov		ecx, [ecx].m_instanceSpec			; Load Instancespecification into ecx
	ASSUME	ecx:DWORD

	and		ecx, MASK m_fixedFields				; Mask off flags
	shr		ecx, 1								; Convert from SmallInteger

	sub		ebx, ecx							; EBX = max zero-based word subscript

	; Don't want to update the cache in any way if its going to fail, so first check in bounds
	cmp		edx, ebx							; Below upper bound?
	jge		localPrimitiveFailure1WithPop		; N.B. Comparing zero-based offset against max one-based index

	; Get base address of indexable part of object into edi
	lea		edi, DWORD PTR [edi+ecx*4]
	mov		ecx, DWORD PTR [_SP-OOPSIZE]		; Reload receiver OTE from stack into ECX

	mov		[eax].maxIndex, ebx					; Save down the maximum index
	xor		ebx, ebx
	mov		[eax].elemType, ebx					; AtCachePointers = 0
	mov		[eax].oteArray, ecx					; Store OTE into AtCache entry's first slot

	pop		ebx									; Restore ebx

	; Store address of elements into AtCache entry
	mov		[eax].pElements, edi

	mov		eax, [edi+edx*OOPSIZE]				; Get the Oop to push
	ASSUME	eax:DWORD

	pop		edi

	; Overwrite the receiver
	mov		[_SP-OOPSIZE], eax
	lea		eax, [_SP-OOPSIZE]					; primitiveSuccess(1)

	ret

LocalPrimitiveFailure 0

updateAtCacheForByteArray:
	ASSUME	eax:DWORD		; EAX is the offset into the AtCache
	ASSUME	ecx:PTR OTE		; ECX is the Oop of the receiver
	ASSUME	edx:DWORD		; EDX is the requested zero-based offset (which we musn't overwrite)
	ASSUME	ebx:DWORD		; EBX is the byte size of the object
	ASSUME	edi:PTR Object	; EDI points to the body of the receiver

	; Don't want to update the cache in any way if its going to fail, so first check in bounds
	cmp		edx, ebx							; Below upper bound?
	jge		localPrimitiveFailure1WithPop		; N.B. Comparing zero-based offset against max one-based index		

	; Note that we don't need to scale eax at all because it is an Oop and OTEs are 16-bytes,
	; the same size as an AtCacheEntry
	mov		_AtCache[eax].maxIndex, ebx

	mov		ebx, AtCacheBytes
	
	mov		_AtCache[eax].oteArray, ecx			; Store OTE into AtCache entry's first slot
	mov		_AtCache[eax].elemType, ebx
	; Store address of elements into AtCache entry
	mov		_AtCache[eax].pElements, edi

	movzx	ecx, BYTE PTR[edi+edx]				; Load required byte, zero extending
	
	pop		ebx									; Restore ebx
	pop		edi									; Restore edi

	lea		ecx, [ecx+ecx+1]					; Convert to SmallInteger
	lea		eax, [_SP-OOPSIZE]					; primitiveSuccess(1)

	; Overwrite the receiver in the stack
	mov		[_SP-OOPSIZE], ecx

	ret

accessCachedObject:

	; index greater than upper bound?
	cmp		edx, _AtCache[eax].maxIndex			; Below upper bound?
	jge		localPrimitiveFailure1				; N.B. Comparing zero-based offset against max one-based index		

	; Is it pointers?
	cmp		_AtCache[eax].elemType, AtCacheBytes
	mov		eax, _AtCache[eax].pElements
	ASSUME	eax:NOTHING							; Got pointer to elements (as yet unknown type) in EAX
	jge		byteObjectAtCached					; Contains bytes? Yes, skip to byte access code

	ASSUME	eax:PTR Oop

	mov		eax, [eax+edx*OOPSIZE]
	ASSUME	eax:Oop

	; Overwrite the receiver
	mov		[_SP-OOPSIZE], eax
	lea		eax, [_SP-OOPSIZE]					; primitiveSuccess(1)

	ret

localPrimitiveFailure1WithPop:
	pop		ebx									; Restore ebx
	pop		edi									; Restore edi

LocalPrimitiveFailure 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
byteObjectAtCached:
	ASSUME eax:PTR BYTE
	ASSUME ecx:PTR OTE							; ECX is the receiver

IFDEF _DEBUG
	jg		stringAt
ENDIF

	movzx	ecx, BYTE PTR[eax+edx]				; Load required byte, zero extending
	lea		eax, [_SP-OOPSIZE]					; primitiveSuccess(1)
	lea		ecx, [ecx+ecx+1]					; Convert to SmallInteger
	mov		[_SP-OOPSIZE], ecx					; Overwrite the receiver

	ret

IFDEF _DEBUG
stringAt:
	; Should not get here
	int 3
	xor		eax, eax
	ret
ENDIF

ENDPRIMITIVE primitiveAtCached

	
BEGINPRIMITIVE primitiveAtPutCached
	mov		eax, DWORD PTR [_SP-OOPSIZE*2]	; Load receiver OTE from stack into EAX
	ASSUME	eax:PTR OTE

	mov		edx, DWORD PTR [_SP-OOPSIZE]	; Load index argument into EDX

	mov		ecx, eax						; Get receiver Oop into ECX (where it remains)
	and		eax, AtCacheMask				; Mask off index to AtCache size (must be power of 2)

	sar		edx, 1
	jnc		localPrimitiveFailure0			; Index not an integer
	
	sub		edx, 1							; Convert 1 based index to zero based offset
	js		localPrimitiveFailure0			; Index out of bounds (<= 0)

	; Is the array already in the AtPutCache?
	cmp	_AtPutCache[eax].oteArray, ecx
	je	accessCachedObject					; If not in cache, must set up before can access entry

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Object not in cache, so put it there
	; EAX is the offset into the AtCache
	; ECX is the receiver
	; EDX is the requested zero-based offset (which we musn't overwrite)

	; Get pointer flag from OTE
	ASSUME ecx:PTR OTE

	push	edi									; preserve edi
	push	ebx									; and ebx

	test	[ecx].m_flags, MASK m_pointer		; Test pointer bit of object table entry

	mov		ebx, [ecx].m_size					; Load size into ebx
												; N.B. The immutability bit is NOT masked out

	mov		edi, [ecx].m_location				; Get pointer to object into edi
	ASSUME edi:PTR Object

	jz		updateAtPutCacheForByteArray

updateAtPutCacheForPointerObject:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; EAX is the offset into the AtCache
	; ECX is the Oop of the receiver
		ASSUME	ecx:PTR OTE
	; EDX is the requested zero-based offset (which we musn't overwrite)
	; EBX is the byte size of the object
	; EDI points to the body of the receiver
		ASSUME edi:PTR Object

	mov		ecx, [ecx].m_oteClass				; Get class of object into ecx (need to know number of named inst vars)

	sar		ebx, 2								; Adjust byte size to word size

	mov		ecx, [ecx].m_location
	ASSUME	ecx:PTR Behavior

	lea		eax, _AtPutCache[eax]
	ASSUME	eax:PTR AtCacheEntry

	mov		ecx, [ecx].m_instanceSpec			; Load Instancespecification into ecx
	ASSUME	ecx:DWORD

	and		ecx, MASK m_fixedFields				; Mask off flags
	shr		ecx, 1								; Convert from SmallInteger

	sub		ebx, ecx							; EBX = max zero-based word subscript

	; Don't want to update the cache in any way if its going to fail, so first check in bounds
	cmp		edx, ebx							; Below upper bound?
	jge		localPrimitiveFailure1WithPop		; N.B. Comparing zero-based offset against max one-based index

	; Get base address of indexable part of object into edi
	lea		edi, DWORD PTR [edi+ecx*4]
	mov		ecx, DWORD PTR [_SP-OOPSIZE*2]		; Reload receiver OTE from stack into ECX

	mov		[eax].maxIndex, ebx					; Save down the maximum index
	xor		ebx, ebx
	mov		[eax].elemType, ebx					; AtCachePointers = 0
	mov		[eax].oteArray, ecx					; Store OTE into AtCache entry's first slot

	mov		ebx, ecx							; Preserve receiver for later

	; Store address of elements into AtCache entry
	mov		[eax].pElements, edi

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Now do the xchg of the new Oop argument and the existing element at the address
	;	EDI = pointer to elements	(needs to be popped yet)
	;	EAX = pointer into AtPutCache
	;	EBX = OTE of receiver
	;	ECX = OTE of receiver
	;	EDX is the requested zero-based offset (still)

	; Load old value into eax (in order to adjust ref. count)
	mov		ecx, [edi+edx*OOPSIZE]				; Load overwritten value into ECX
	mov		eax, [_SP]							; Reload new value from stack top
	mov		[edi+edx*OOPSIZE], eax				; Overwrite
	CountUpOopIn <a>
	mov		edi, eax							; Preserve argument for later 

	CountDownOopIn <c>							; Count down overwritten value, potentially moving into Zct
	
	; count down destroys eax, ecx, and edx, but not edi(arg) and ebx(receiver)
	
	mov		eax, edi							; Reload new value into eax

	pop		ebx									; Restore ebx to value on entry
	pop		edi									; Ditto edi

	mov		[_SP-OOPSIZE*2], eax				; And overwrite receiver in stack with new value
	lea		eax, [_SP-OOPSIZE*2]				; primitiveSuccess(2)

	ret	

LocalPrimitiveFailure 0

updateAtPutCacheForByteArray:
	ASSUME	edx:DWORD							; The desired index
	ASSUME	ebx:DWORD							; The size
	ASSUME	edi:PTR ByteArray					; Pointer to the object being accessed
	ASSUME	ecx:PTR OTE							; The receiver

	; Don't want to update the cache in any way if its going to fail, so first check in bounds
	cmp		edx, ebx							; Below upper bound?
	jge		localPrimitiveFailure1WithPop		; N.B. Comparing zero-based offset against max one-based index		

	mov		_AtPutCache[eax].maxIndex, ebx
	ASSUME	ebx:NOTHING							; ebx no longer needed

	mov		ebx, [_SP]							; Load new value into EBX

	mov		_AtPutCache[eax].oteArray, ecx		; Store OTE into AtCache entry's first slot

	mov		_AtPutCache[eax].elemType, AtCacheBytes
	; Store address of elements into AtCache entry
	mov		_AtPutCache[eax].pElements, edi

	mov		eax, ebx							; Load SmallInteger argument in ebx

	; Argument tests can unfortunately fail after updating cache (but should be very rare)
	sar		eax, 1								; Convert to real integer value
	jnc		localPrimitiveFailure2WithPop		; Not a SmallInteger

	cmp		eax, 0FFh
	ja		localPrimitiveFailure2WithPop		; Used unsigned comparison for 0<=ecx<=255

	; Write down the actual byte value
	mov		BYTE PTR[edi+edx], al
	
	mov		eax, ebx

	pop		ebx
	pop		edi

	mov		[_SP-OOPSIZE*2], eax				; And overwrite receiver in stack with new value
	lea		eax, [_SP-OOPSIZE*2]				; primitiveSuccess(2)

	ret	

localPrimitiveFailure1WithPop:
	pop		ebx
	pop		edi

LocalPrimitiveFailure 1

localPrimitiveFailure2WithPop:
	pop		ebx
	pop		edi

LocalPrimitiveFailure 2

accessCachedObject:
	; Note that we won't normally get here unless the primitive methods is #perform:'d, since
	; the at bytecode handler will handle all cases where the target is already in the cache
	; Because of this it doesn't matter quite so much that these be highly optimized

	; index greater than upper bound?
	cmp		edx, _AtPutCache[eax].maxIndex	; Below upper bound?
	jge		localPrimitiveFailure1				; N.B. Comparing zero-based offset against max one-based index		

	; Is it pointers?
	cmp		_AtPutCache[eax].elemType, AtCacheBytes
	mov		eax, _AtPutCache[eax].pElements
	ASSUME	eax:NOTHING							; Got pointer to elements (as yet unknown type) in EAX
	jge		cachedByteObjectAtPut				; Contains bytes? Yes, skip to byte access code

	ASSUME	eax:PTR Oop
	
	lea		edx, [eax+edx*OOPSIZE]				; Get pointer to element into edx

	; Now do the xchg of the new Oop argument and the existing element at the address

	mov		ecx, [_SP]							; Reload value to write
	ASSUME	ecx:PTR OTE

	mov		eax, [edx]							; Get old element value
	mov		[edx], ecx							; Store new element value 
	
	CountDownOopIn <a>							; Count down overwritten value (destroys registers)

	; count down destroys eax, ecx, and edx
	mov		eax, [_SP]							; Reload new value into eax
	mov		ecx, [_SP-OOPSIZE*2]				; Reload receiver into ecx

	CountUpOopIn <a>							; Because arg stored into a heap object, count goes up by one
	mov		[_SP-OOPSIZE*2], eax				; And overwrite receiver in stack with new value
	lea		eax, [_SP-OOPSIZE*2]				; primitiveSuccess(2)

	ret	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
cachedByteObjectAtPut:
	ASSUME eax:PTR BYTE							; 
	ASSUME ecx:PTR OTE							; ECX is the receiver
	ASSUME edx:DWORD							; EDX is offset

	IFDEF _DEBUG
		jg		cachedStringAtPut
	ENDIF

	add		eax, edx							; Make eax a pointer to the byte to be overwritten
	mov		edx, [_SP]							; Load SmallInteger argument into edx

	sar		edx, 1								; Convert to real integer value
	jnc		localPrimitiveFailure2				; Not a SmallInteger

	cmp		edx, 0FFh
	ja		localPrimitiveFailure2				; Used unsigned comparison for 0<=ecx<=255

	; Write down the actual byte value
	mov		BYTE PTR[eax], dl
	
	lea		eax, [edx+edx+1]					; Regenerate SmallInteger argument

	mov		[_SP-OOPSIZE*2], eax				; And overwrite receiver in stack with new value
	lea		eax, [_SP-OOPSIZE*2]				; primitiveSuccess(2)

	ret	

IFDEF _DEBUG
cachedStringAtPut:
	; Should not get here
	int 3
	xor		eax, eax
	ret
ENDIF

ENDPRIMITIVE primitiveAtPutCached

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; String/variable byte objects primitives

;  BOOL __fastcall Interpreter::primitiveStringAt()
;
; Primitive for accessing character elements of Strings. Does not check
; that the receiver is a string, as does not expect to be used in incorrect
; classes.
;
BEGINPRIMITIVE primitiveStringAt
	mov		eax, DWORD PTR [_SP-OOPSIZE]	; Load receiver OTE from stack into EAX
	ASSUME	eax:PTR OTE

	mov		edx, DWORD PTR [_SP]			; Load argument into EDX

	mov		ecx, eax						; Get receiver Oop into ECX (where it remains)
	and		eax, AtCacheMask				; Mask off index to AtCache size (must be power of 2)

	sar		edx, 1
	jnc		localPrimitiveFailure0			; Index not an integer

	sub		edx, 1							; Convert 1 based index to zero based offset
	js		localPrimitiveFailure1			; Index out of bounds (<= 0)

	; Is the string already in the AtCache?
	cmp		_AtCache[eax].oteArray, ecx
	je		accessCachedObject				; If not in cache, must set up before can access entry

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Object not in cache, so update the cache with its details. Note that we do
	; this (optimistically) before checking the index, etc
	;	EAX is the offset into the AtCache
	;	ECX is the receiver
	;	EDX is the requested zero-based offset (which we musn't overwrite)

	mov		_AtCache[eax].oteArray, ecx				; Store OTE into AtCache entry's first slot

	push	ebx										; preserve ebx

	mov		ebx, [ecx].m_size						; Load size of string into ECX
	and		ebx, 7fffffffh							; Mask out the immutability bit
	mov		_AtCache[eax].maxIndex, ebx				; And store that into AtCache as maxIndex
	mov		ebx, [ecx].m_location					; Get pointer to string into edi
	ASSUME ebx:PTR String
	mov		_AtCache[eax].elemType, AtCacheString	; Mark the entry as a string entry
	mov		_AtCache[eax].pElements, ebx			; Store address of chars into AtCache entry
	
	pop		ebx										; Restore ebx

accessCachedObject:

	; index greater than upper bound?
	cmp		edx, _AtCache[eax].maxIndex			; Below upper bound?
	mov		eax, _AtCache[eax].pElements		; Preload EAX to point at chars in anticipation of being in bounds
	ASSUME	eax:PTR BYTE						; 
	jge		localPrimitiveFailure1				; N.B. Comparing zero-based offset against max one-based index		

	ASSUME ecx:NOTHING							; ECX is the receiver, but no longer needed

	movzx	edx, BYTE PTR[eax+edx]				; Load the character value from the string
	mov		eax, [OBJECTTABLE]

	shl		edx, 4								; Multiply edx by OTENTRYSIZE (16) (unfortunately not a valid scale value for LEA)
	add		eax, FIRSTCHAROFFSET
	add		eax, edx

	; Overwrite the receiver with the accessed character
	mov		[_SP-OOPSIZE], eax
	lea		eax, [_SP-OOPSIZE*1]				; primitiveSuccess(1)

	ret

LocalPrimitiveFailure 0
LocalPrimitiveFailure 1

ENDPRIMITIVE primitiveStringAt


;  BOOL __fastcall Interpreter::primitiveStringAtPut()
;
; Primitive for storing characters into Strings
;
BEGINPRIMITIVE primitiveStringAtPut
	mov		ecx, [_SP-OOPSIZE*2]				; Access receiver under arguments
	ASSUME	ecx:PTR OTE
	mov		edx, [_SP-OOPSIZE]					; Load index argument from stack
	sar		edx, 1								; Argument is a SmallInteger?
	jnc		localPrimitiveFailure0				; No, primitive failure

	sub		edx, 1								; Convert 1 based index to zero based offset
	js		localPrimitiveFailure1				; Index out of bounds (<= 0)

	mov		eax, [ecx].m_location				; Load object address into eax

	cmp		edx, [ecx].m_size					; Compare offset with object size (if immutable size < 0, so will fail)
	jge		localPrimitiveFailure1				; Index out of bounds (>= size)

	add		eax, edx							; eax now contains pointer to destination

	mov		ecx, [_SP]							; Load value argument receiver into ecx
	test	cl, 1
	jnz		localPrimitiveFailure2				; Value is SmallInteger - fail primitive
	ASSUME	ecx:PTR OTE							; Value is an object (need to check if Character or not)

	mov		edx, [ecx].m_oteClass				; Get class oop into EDX from OTE
	ASSUME	edx:PTR OTE
	mov		ecx, [ecx].m_location				; Get address of value into
	ASSUME	ecx:PTR Character

	cmp		edx, [Pointers.ClassCharacter]		; Is it a character?
	jne		localPrimitiveFailure2				; Not a char, fail the primitive

	; Rather than use codePoint in char, could work entirely with the Oop by deducting
	; an appropriate offset in the OT, but this will also work for 16-bit or larger character encodings
	
	mov		ecx, [ecx].m_asciiValue				; Load first (and only) Oop of object
	ASSUME	ecx:DWORD							; ecx now contains SmallInteger code pointer of character

	shr		ecx, 1								; Convert codePoint from SmallInteger
	mov		BYTE PTR [eax], cl					; to give 0 based code

	mov		eax, [_SP]							; Relod char (not ref. counted)
	mov		[_SP-OOPSIZE*2], eax				; ...and overwrite with value for return
	lea		eax, [_SP-OOPSIZE*2]				; primitiveSuccess(2)
	ret

LocalPrimitiveFailure 0
LocalPrimitiveFailure 1
LocalPrimitiveFailure 2

ENDPRIMITIVE primitiveStringAtPut


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  BOOL __fastcall Interpreter::primitiveBasicAt()
;;
;; Primitive for getting elements of indexed objects without using AtCache
;;
;; The receiver MUST not be a SmallInteger, or a crash will result when attempting
;; the line marked with a '*'
;;
BEGINPRIMITIVE primitiveBasicAt
	mov		ecx, [_SP-OOPSIZE]					; Access receiver under argument
	mov		edx, [_SP]							; Load argument from stack
   	ASSUME	ecx:PTR OTE							; ecx is pointer to receiver for rest of primitive

	sar		edx, 1								; Argument is a SmallInteger?
	jnc		localPrimitiveFailure0				; Arg not a SmallInteger, primitive failure 0

	sub		edx, 1								; Convert 1 based index to zero based offset

	mov		eax, [ecx].m_oteClass				; Get class Oop from OTE into EAX for later use
	ASSUME	eax:PTR OTE

	js		localPrimitiveFailure1				; Index out of bounds (<= 0)
	     	
	test	[ecx].m_flags, MASK m_pointer		; Test pointer bit of object table entry
	jz		byteObjectAt						; Contains bytes? Yes, skip to byte access code

pointerAt:
	; ASSUME ecx:PTR OTE						; ECX is receiver Oop
	; ASSUME eax:PTR OTE						; EAX is class Oop
	; ASSUEM edx:DWORD							; EDX is offset

	; Array of pointers?

	mov		ecx, [ecx].m_size					; Load size into ecx (not overwriting receiver Oop)
	ASSUME	ecx:DWORD

	mov		eax, [eax].m_location				; Load address of class object into eax from OTE at eax
	ASSUME	eax:PTR Behavior
	
	and		ecx, 7fffffffh						; Mask out the immutability bit
	shr		ecx, 2								; ecx = total Oop size
	
	mov		eax, [eax].m_instanceSpec			; Load Instancespecification into edx
	ASSUME	eax:DWORD

	and		eax, MASK m_fixedFields				; Mask off flags
	shr		eax, 1								; Convert from SmallInteger
	add		edx, eax							; Add fixed offset for inst vars

	cmp		edx, ecx							; Index <= size (still in ecx)?

	mov		ecx, [_SP-OOPSIZE]					; Reload receiver into ecx
	ASSUME 	ecx:PTR OTE

	jae		localPrimitiveFailure1					; No, out of bounds

	mov		eax, [ecx].m_location				; Reload address of receiver into eax
	
	mov		eax, [eax+edx*OOPSIZE]				; Load Oop of element at required index
	mov		[_SP-OOPSIZE], eax					; And overwrite receiver in stack with it
	lea		eax, [_SP-OOPSIZE]					; primitiveSuccess(1)

	ret

LocalPrimitiveFailure 0
LocalPrimitiveFailure 1

ENDPRIMITIVE primitiveBasicAt

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
ALIGN 4		; Sufficient to align on 4 byte boundary as first instruction is only 2 bytes
byteObjectAt PROC
	ASSUME	ecx:PTR OTE							; ECX is Oop of receiver, but not needed
	ASSUME	edx:DWORD							; EDX is the index
	ASSUME	eax:PTR OTE							; EAX is the Oop of the receiver's class

	mov		eax, [ecx].m_location				; Load object address into eax
	ASSUME	eax:PTR ByteArray					; EAX points at receiver

	mov		ecx, [ecx].m_size					
	and		ecx, 7fffffffh						; Mask out the immutability bit
	
	cmp		edx, ecx							; Index out of bounds (>= size) ?
	jae		localPrimitiveFailure1				; 
	
	movzx	ecx, BYTE PTR[eax+edx]				; Load required byte, zero extending

	lea		eax, [_SP-OOPSIZE]					; primitiveSuccess(1)
	lea		ecx, [ecx+ecx+1]					; Convert to SmallInteger
	mov		[_SP-OOPSIZE], ecx					; Overwrite receiver with result. No need to count as SmallInteger

	; eax now contains a SmallInteger, so it cannot be zero (i.e. success indication is returned)
	ret

LocalPrimitiveFailure 1

byteObjectAt ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; BOOL __fastcall Interpreter::primitiveInstVarAt()
;;
;; Primitive for getting elements of objects
;;
BEGINPRIMITIVE primitiveInstVarAt
	mov		ecx, [_SP-OOPSIZE]					; Access receiver under argument
	mov		edx, [_SP]							; Load argument from stack
	sar		edx, 1								; Argument is a SmallInteger?
   	ASSUME	ecx:PTR OTE							; ecx is pointer to receiver for rest of primitive
	jnc		localPrimitiveFailure0				; Arg not a SmallInteger, primitive failure 0

	sub		edx, 1								; Convert 1 based index to zero based offset
	mov		eax, [ecx].m_location				; Load object address into eax *Will fail if receiver is SmallInteger*
	ASSUME	eax:PTR VariantObject
	js		localPrimitiveFailure1				; Index out of bounds (<= 0)
				     	
	test	[ecx].m_flags, MASK m_pointer		; Test pointer bit of object table entry
	jz		byteObjectAt						; Contains pointers? No, skip to byte access code

	; Array of pointers?
	mov		ecx, [ecx].m_size					; Load byte size into ECX
	and		ecx, 7fffffffh						; Mask out immutability (sign) bit
	shr		ecx, 2								; Div 4 gives pointer count
	cmp		edx, ecx							; offset < size?
	jae		localPrimitiveFailure1				; No, out of bounds (>=)

	mov		ecx, [eax].m_elements[edx*OOPSIZE]	; Load Oop from inst var
	lea		eax, [_SP-OOPSIZE]					; primitiveSuccess(1)
	mov		[_SP-OOPSIZE], ecx					; Overwrite receiver with inst var value

	ret

LocalPrimitiveFailure 0
LocalPrimitiveFailure 1

ENDPRIMITIVE primitiveInstVarAt

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	BOOL __fastcall Interpreter::primitiveBasicAtPut()
;;
;; Primitive for setting elements of indexed objects without using AtPutCache
;; This primitive answers its value argument, so it moves it down
;; the stack, overwriting the receiver. The other argument must be a
;; SmallInteger for the primitive to succeed.
;;
BEGINPRIMITIVE primitiveBasicAtPut
	mov		edx, [_SP-OOPSIZE]					; Load index argument from stack
	mov		ecx, [_SP-OOPSIZE*2]				; Access receiver under arguments
	ASSUME	ecx:PTR OTE

	sar		edx, 1								; Argument is a SmallInteger?
	jnc		localPrimitiveFailure0 				; No, primitive failure

	sub		edx, 1								; Convert 1 based index to zero based offset

	js		localPrimitiveFailure1				; Index out of bounds (<= 0)

	test	[ecx].m_flags, MASK m_pointer		; Pointer object?
	mov		eax, [ecx].m_location				; Load object address into eax
	jz		byteObjectAtPut						; No, skip to code for storing bytes

	mov		eax, [ecx].m_oteClass				; Get class Oop	from OTE into eax
	ASSUME	eax:PTR OTE

	mov		ecx, [ecx].m_size					; Load size into ecx (negative if immutable)
	ASSUME	ecx:DWORD
	sar		ecx, 2								; ecx = total Oop size

	mov		eax, [eax].m_location				; Load address of class object into eax
	ASSUME	eax:PTR Behavior

	mov		eax, [eax].m_instanceSpec			; Load Instancespecification flags into edx
	ASSUME	eax:DWORD

	and		eax, MASK m_fixedFields				; Mask off flags
	shr		eax, 1								; Convert from SmallInteger
	add		edx, eax							; Add fixed offset for inst vars to offset argument

	cmp		edx, ecx							; Index <= size (still in ecx)?
	ASSUME	edx:NOTHING							; edx no longer needed for index
	
	mov		ecx, [_SP-OOPSIZE*2]				; Reload receiver into ecx for later
	ASSUME	ecx:PTR OTE

	jge		localPrimitiveFailure1				; No, out of bounds
	
	mov		eax, [ecx].m_location				; Reload address of receiver into eax
	ASSUME	eax:PTR VariantObject
	
	lea		eax, [eax+edx*OOPSIZE]	
	mov		edx, [_SP]							; Reload value to write

	mov		ecx, [eax]				 			; Load value to overwrite into ECX
	mov		[eax], edx							; and overwrite with new value in edx
	CountDownOopIn <c>							; Count down overwritten value

	; count down destroys eax, ecx, and edx
	mov		eax, [_SP]							; Reload new value into eax again
	mov		ecx, [_SP-OOPSIZE*2]				; Reload receiver (again)
	mov		[_SP-OOPSIZE*2], eax				; And overwrite receiver in stack with new value

	CountUpOopIn <a>							; Must count up argument because written into a heap object
	lea		eax, [_SP-OOPSIZE*2]				; primitiveSuccess(2)
	ret

LocalPrimitiveFailure 0
LocalPrimitiveFailure 1
LocalPrimitiveFailure 2

ENDPRIMITIVE primitiveBasicAtPut

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Helper

ALIGN 8
byteObjectAtPut PROC
	ASSUME	ecx:PTR OTE						; ECX is byte object Oop
	ASSUME	edx:DWORD						; EDX is index
	ASSUME	eax:PTR ByteArray				; EAX is point to byte object

	cmp		edx, [ecx].m_size				; Compare offset+HEADERSIZE with object size (latter -ve if immutable)
	jge		localPrimitiveFailure1			; Index out of bounds (>= size)

	add		eax, edx
	ASSUME	eax:PTR BYTE
	ASSUME	edx:NOTHING						; EDX is now free

	mov		edx, [_SP]						; Load value to store from stack top
	ASSUME	edx:DWORD

	sar		edx, 1							; Convert to real integer value
	jnc		localPrimitiveFailure2			; Not a SmallInteger

	cmp		edx, 0FFh						; Too large?
	ja		localPrimitiveFailure2			; Used unsigned comparison for 0<=ecx<=255

	mov		[eax], dl						; Store byte into receiver
	ASSUME	eax:NOTHING

	mov		ecx, [_SP]						; Reload value to store from stack top
	lea		eax, [_SP-OOPSIZE*2]			; primitiveSuccess(2)
	mov		[_SP-OOPSIZE*2], ecx			; ...and overwrite with value for return (still in EAX)

	ret

LocalPrimitiveFailure 1
LocalPrimitiveFailure 2

byteObjectAtPut ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	BOOL __fastcall Interpreter::primitiveInstVarAtPut()
;;
;; Primitive for setting elements of any object
;;
BEGINPRIMITIVE primitiveInstVarAtPut
	mov		edx, [_SP-OOPSIZE]					; Load index argument from stack
	mov		ecx, [_SP-OOPSIZE*2]				; Access receiver under arguments
	ASSUME	ecx:PTR OTE

	sar		edx, 1								; Argument is a SmallInteger?
	jnc		localPrimitiveFailure0				; No, primitive failure

	sub		edx, 1								; Convert 1 based index to zero based offset
	mov		eax, [ecx].m_location				; Load object address into eax
	js		localPrimitiveFailure1				; Index out of bounds (<= 0)

	test	[ecx].m_flags, MASK m_pointer
	jz		byteObjectAtPut						; Skip to code for storing bytes

	; Array of pointers
	ASSUME	eax:PTR VariantObject

	mov		ecx, [ecx].m_size					; Load size into ecx (-ve if immutable)
	sar		ecx, 2								; ecx = total Oop size

	cmp		edx, ecx							; Index <= size (still in ecx)?
	jge		localPrimitiveFailure1				; No, out of bounds
	
	lea		eax, [eax].m_elements[edx*OOPSIZE]

	mov		edx, [_SP]							; Load value to write
	mov		ecx, [eax]							; Exchange Oop of overwritten value with new value
	mov		[eax], edx
	ASSUME	eax:NOTHING
	CountDownOopIn <c>							; Count down overwritten value

	; count down destroys eax, ecx, and edx
	mov		ecx, [_SP-OOPSIZE*2]				; Reload receiver
	mov		eax, [_SP]							; Reload new value into eax
	mov		[_SP-OOPSIZE*2], eax				; And overwrite receiver in stack with new value

	; Must count up arg, because written into a heap object
	CountUpOopIn <a>

	lea		eax, [_SP-OOPSIZE*2]				; primitiveSuccess(2)
	ret

LocalPrimitiveFailure 0
LocalPrimitiveFailure 1

ENDPRIMITIVE primitiveInstVarAtPut

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
BEGINPRIMITIVE primitiveShallowCopy
	mov		ecx, [_SP]
	CANTBEINTEGEROBJECT <ecx>
	call	SHALLOWCOPY
	mov		[_SP], eax						; Overwrite receiver with new object
	AddToZctNoSP <a>
	mov		eax, _SP						; primitiveSuccess(0)
	ret
ENDPRIMITIVE primitiveShallowCopy

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; There is a small performance advantage in using this instead of directly 
; calling lstrcmpi from Smalltalk but it is so small that the only real point 
; in having this primitive is in order to win on a benchmark!
;
BEGINPRIMITIVE primitiveStringCollate
	mov		ecx, [_SP-OOPSIZE]
	ASSUME	ecx:PTR OTE
	mov		edx, [_SP]

	test	dl, 1								; Arg is SmallInteger?
	jnz		localPrimitiveFailure0
	ASSUME	edx:PTR OTE

	xor		eax, eax							; Set 0 as default (i.e. equal)
	cmp		ecx, edx
	je		@F									; If identical, can short cut as must be =

	test	[edx].m_flags, MASK m_weakOrZ		; Arg object is null terminated?
	mov		ecx, [ecx].m_location				; Preload ptr to receiver string
	ASSUME	ecx:PTR StringA
	jz		localPrimitiveFailure0				; Arg not a null termianted object
	
	mov		edx, [edx].m_location
	ASSUME	edx:PTR StringA

	INVOKE	lstrcmpi, ecx, edx

	add		eax, eax					; Shift lstrcmpi result to make SmallInteger
@@:
	or		eax, 1						; Add SmallInteger flag
	mov		[_SP-OOPSIZE], eax			; Store back the SmallInteger result over receiver
	lea		eax, [_SP-OOPSIZE*1]		; primitiveSuccess(1)
	ret

LocalPrimitiveFailure 0

ENDPRIMITIVE primitiveStringCollate

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
BEGINPRIMITIVE primitiveStringCollates
	mov		ecx, [_SP-OOPSIZE]
	ASSUME	ecx:PTR OTE
	mov		edx, [_SP]

	xor		eax, eax							; Set 0 as default (i.e. equal)
	cmp		ecx, edx
	je		@F									; If identical, can short cut as must be =

	test	dl, 1								; Arg is SmallInteger?
	jnz		localPrimitiveFailure0
	ASSUME	edx:PTR OTE

	test	[edx].m_flags, MASK m_weakOrZ		; Arg object is null terminated?
	mov		ecx, [ecx].m_location				; Preload ptr to receiver string
	ASSUME	ecx:PTR StringA
	jz		localPrimitiveFailure0				; Arg not a null termianted object
	
	mov		edx, [edx].m_location
	ASSUME	edx:PTR StringA

	INVOKE	lstrcmp, ecx, edx

	add		eax, eax							; Shift to make SmallInteger

@@:
	or		eax, 1								; Add SmallInteger flag
	mov		[_SP-OOPSIZE], eax					; Store SmallInteger result over receiver
	lea		eax, [_SP-OOPSIZE*1]				; primitiveSuccess(1)
	ret

LocalPrimitiveFailure 0

ENDPRIMITIVE primitiveStringCollates

BEGINPRIMITIVE primitiveStringCompare
	mov		eax, [_SP-OOPSIZE]				; eax holds receiver Oop
	ASSUME	eax:PTR OTE
	mov		edx, [_SP]

	cmp		eax, edx
	jne		notIdentical

	mov		ecx, [oteTrue]					; Identical
	lea		eax, [_SP-OOPSIZE]				; primitiveSuccess(1)
	mov		[_SP-OOPSIZE], ecx
	ret

notIdentical:
	test	dl, 1
	jnz		localPrimitiveFailure0
	ASSUME	edx:PTR OTE

	mov		ecx, [eax].m_oteClass			; Load ecx with receiver class
	cmp		ecx, [edx].m_oteClass			; receiver class == arg class?
	jne		localPrimitiveFailure0				; Same class? If not fail it

	push	esi								; Save esi for temp store
	mov		ecx, [eax].m_size				; Load ecx with size of both objects
	mov		esi, [edx].m_size				; Same size? (Note can ignore null term, since same class)
	and		ecx, 7fffffffh
	and		esi, 7fffffffh
	cmp		ecx, esi
	je		@F

	pop		esi

	mov		ecx, [oteFalse]					; Different sizes, therefore cannot be equal
	lea		eax, [_SP-OOPSIZE]				; primitiveSuccess(1)
	mov		[_SP-OOPSIZE], ecx
	ret

@@:
	mov		esi, [eax].m_location			
	ASSUME	esi:PTR StringA					; esi points at receiver string contents
	ASSUME	eax:NOTHING						; Arg Oop no longer needed
	push	edi								; Save edi for temp store
	mov		edi, [edx].m_location			
	ASSUME	edi:PTR StringA					; edi points at receiver string contents
	
	mov		edx, ecx						; Copy size into edx
	ASSUME	edx:DWORD

	shr		ecx, 2							; Calc dwords in objects

	mov		eax, [oteFalse]					; Let the default result be false
	
	; Perform the memcmp, first by comparing the DWORDs
	repe	cmpsd
	jne		@F								; If not equal, skip to answer false

	mov		ecx, edx						; Reload byte size
	and		ecx, 3							; compare the remaining bytes
	repe	cmpsb

	jne		@F								; If not equal, skip to answer false

	sub		eax, OTENTRYSIZE				; true is Oop before false

	ASSUME	esi:NOTHING
	ASSUME	edi:NOTHING
@@:
	pop		edi
	ASSUME	_IP:PTR Byte
	pop		esi								; We're using ESI for _SP, so must restore before going to stack
	ASSUME	_SP:PTR Oop

	mov		[_SP-OOPSIZE], eax
	lea		eax, [_SP-OOPSIZE]				; primitiveSuccess(1)
	ret

LocalPrimitiveFailure 0

ENDPRIMITIVE primitiveStringCompare

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; _declspec(naked) unsigned long __stdcall hashBytes(const BYTE* chars, int len)
;
; On entry ECX contains pointer to string, and EDX the length
; Here we keep top 24 bits of _BP 0 to avoid expensive MOVZX (3 cycles)
; Hash value answered in EAX
;
HashBytes:								; cdecl entry point
	mov		ecx, [ESP+4]
	mov		edx, [ESP+8]
	test	ecx, ecx
	jnz		hashBytes
	xor		eax, eax
	ret

hashBytes PPROC
	push    ebx
	xor		ebx, ebx					; We need top 24 bits clear
	xor     eax, eax					; Initial hash value is zero
hashStringRepeat:
	or	    edx, edx					; No Bytes remaining?
	jle     hashStringRet				; Yes, return value
	shl     eax, 4						; hashVal << 4
	mov		bl, byte ptr [ecx]			; Character into bl
	add     eax, ebx					; (hashVal<<4) += char
	test	eax, 0f0000000h				; Carry into top nibble ?
	jz      hashStringNoCarry			; No carry into top nibble

	; 6 instructions, 13 bytes, 6 cycles
	bswap	eax								; Reverse ordering to put top byte in al
	mov		bl, al							; top byte into bl
	and		bl, 0f0h						; save top nibble in bl
	and		al, 0fh							; mask out top nibble in al
	bswap	eax								; revert to normal ordering, top nibble masked out
	xor		al, bl							; xor the top nibble into the top nibble of the first byte

	; 5 instructions, 15 bytes, 6 cycles
	;mov		ebx, eax
	;shr		ebx, 24						; Has effect of clearing top 24 bits too
	;and		bl, 0f0h					; Mask in former top nibble
	;xor		al, bl						; And xor it into the bottom
	;and		eax, 0fffffffh				; Mask out the former top nibble

hashStringNoCarry:
	inc		ecx
	dec     edx
	jnz     hashStringRepeat
hashStringRet:
	pop		ebx
	ret
hashBytes ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  int __fastcall Interpreter::primitiveHashBytes()
;
; Should not fail as long as has not been called for a non-byte object (i.e. somebody 
; has put the primitive in a method of a non-byte class). The only other 
; possibility for failure is a VM bug which results in the stack pointer being out for
; some reason. This will be trapped in the debug system only.
;
BEGINPRIMITIVE primitiveHashBytes
	mov		ecx, [_SP]						; Access receiver at stack top
	ASSUME	ecx:PTR OTE

	ASSERTISBYTES <ecx>

	mov		edx, [ecx].m_size
	and		edx, 7fffffffh					; Mask out immutability (sign) bit
	ASSUME	edx:DWORD

	mov		ecx, [ecx].m_location
	ASSUME	ecx:PTR Object

	call	hashBytes
	lea		ecx, [eax+eax+1]					; Convert to SmallInteger
	mov		eax, _SP							; primitiveSuccess(0)
	mov		[_SP], ecx
	ret
ENDPRIMITIVE primitiveHashBytes


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Raise a special exception caught by the callback entry point routine - the result will still be on top
; of the stack
BEGINPRIMITIVE primitiveReturnFromCallback
	mov		eax, [_SP]								; Pop off the VM's callback cookie
	mov		ecx, [ACTIVEPROCESS]
	ASSUME	ecx:PTR Process

	mov		ecx, [ecx].m_callbackDepth				; Don't want to do anything if callbackDepth = 0
	cmp		ecx, 1									; Zero callbacks?
	je		fail									; Yes, then just fail the prim (no retry)

	cmp		eax, [CURRENTCALLBACK]					; Is it current callback?
	jne		@F										; No, skip longjmp

	PopStack										; Pop off the jmp_buf pointer
	xor		eax, 1									; Convert from a SmallInteger
	pushd	SE_VMCALLBACKEXIT						; Return SE_VMCALLBACKEXIT code as the setjmp retval
	StoreInterpreterRegisters						; Store down IP/SP for C++ we're about to jump back to
	
	pushd	eax										; &jmp_buf
	call	longjmp									; jump out back to C++ - cannot return here

@@:
	cmp		eax, SMALLINTZERO						; Passed zero?
	jne		failRetry								; No, then not current callback so need to retry it

	; Raise SE_VMCALLBACKEXIT exception
	PopStack
	pushd	eax										; Build "Array" of args on stack
	pushd	esp										; Push address of arg array
	pushd	1										; One argument (the VM's cookie)
	StoreInterpreterRegisters
	pushd	0										; No flags
	pushd	SE_VMCALLBACKEXIT						; User defined exception code
	call 	RaiseException

	; Push the cookie argument back on the stack
	pop		[_SP+OOPSIZE]
	add		_SP, OOPSIZE

	; The exception filter will specify continued execution if the current active process is not the
	; process active when the last callback was entered, so we fail the primitive. The backup Smalltalk
	; will yield and recursively try again
failRetry:
	inc		[CALLBACKSPENDING]						; VM needs to know callbacks waiting to exit
fail:
	xor		eax, eax
	ret
ENDPRIMITIVE primitiveReturnFromCallback


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Raise a special exception caught by the callback entry point routine and propagate
BEGINPRIMITIVE primitiveUnwindCallback
	mov		eax, [_SP]								; Pop off the VM's callback cookie
	mov		ecx, [ACTIVEPROCESS]
	ASSUME	ecx:PTR Process
	
	mov		ecx, [ecx].m_callbackDepth
	cmp		ecx, 1									; Zero callbacks?
	je		fail									; Yes, then just fail the prim (no retry)

	cmp		eax, [CURRENTCALLBACK]					; Otherwise only if current callback
	je		@F										; 
	cmp		eax, SMALLINTZERO
	jne		failRetry								; Not zero or current callback, so retry later

@@:
	PopStack										; Cookie is an Oop (actually SmallInteger _address_), but must NOT be ref. counted
	pushd	eax										; Build "Array" of args on stack
	pushd	esp										; Push address of arg array
	pushd	1										; One argument (the VM's cookie)
	StoreInterpreterRegisters						; We must save down _SP as used by exception handler, _IP needed if unwinding callbacks on termination
	pushd	0										; No flags
	pushd	20000001h								; User defined exception code for unwind
	call 	RaiseException
	
	; Note that the exception handler never executes handler, but may return here (if not continues search)

	; Push the cookie argument back on the stack
	pop		[_SP+OOPSIZE]
	add		_SP, OOPSIZE

	; The exception filter will specify continued execution if the current active process is not the
	; process active when the last callback was entered, so we fail the primitive. The backup Smalltalk
	; will yield and recursively try again
failRetry:
	inc		[CALLBACKSPENDING]						; VM needs to know callbacks waiting to exit
fail:
	xor		eax, eax
	ret
ENDPRIMITIVE primitiveUnwindCallback

BEGINPRIMITIVE primitiveReturnFromInterrupt
	mov		edx, [_SP-OOPSIZE]					; Get return frame offset
	mov		ecx, [_SP]							; Get as return value suspendingList (may want to restore)

	sar		edx, 1								; Frame offset is a SmallInteger?
	jnc		localPrimitiveFailure0				; No - primitive failure 0

	add		edx, [ACTIVEPROCESS]				; Add offset back to active proc. base address to get frame address in edx
	sub		_SP, OOPSIZE*3						; Pop args
	or		edx, 1								; Convert to SmallInteger (addresses aligned on 4-byte boundary)

	call	shortReturn							; Return to interrupted frame (returning the suspendingList at the time of the interrupt)

	PopOopInto <ecx>							; Pop suspendingList (returned) into ECX...

	;; State of Process (especially stack) should now be the same as on entry to the interrupt, assuming
	;; that the image's handler for it didn't have any nasty side effects

	cmp		ecx, [oteNil]						; Was it waiting on a list?
	jne		@F

	mov		eax, _SP							; Process was active, succeed and continue
	ret
@@:
	; The interrupted process was waiting/suspended
	StoreInterpreterRegisters

	;; VM Interrupt mechanism sends a suspending list argument of SmallInteger Zero
	;; if the process is suspended, rather than waiting on a list, so we must test
	;; for this case specially (in fact we just look for any SmallInteger).
	test	cl, 1								; Is the "suspendingList" a SmallInteger?
	jz		@F									; No, skip so "suspend on list"
	call	RESCHEDULE							; Just resuspend the process and schedule another
	LoadInterpreterRegisters
	mov		eax, _SP							; primitiveSuccess(0)
	ret
		
@@:
	call	RESUSPENDACTIVEON
	LoadInterpreterRegisters
	mov		eax, _SP							; primitiveSuccess(0)
	ret

LocalPrimitiveFailure 0

ENDPRIMITIVE primitiveReturnFromInterrupt
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ALIGNPRIMITIVE
@callPrimitiveValue@8 PROC
	push	_SP									; Mustn't destroy for C++ caller
	push	_IP									; Ditto _IP
	push	_BP									; and _BP
	LoadInterpreterRegisters
	call	primitiveValue
	mov		[STACKPOINTER], eax	
	pop		_BP									; Restore callers registers
	StoreIPRegister
	pop		_IP
	pop		_SP
	ret
@callPrimitiveValue@8 ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; int __fastcall Interpreter::primitiveValue(CompiledMethod&, unsigned argCount)
;
BEGINPRIMITIVE primitiveValue
	mov		eax, edx								; Get argument count into EAX
	neg		edx
	push	_BP
	lea		_BP, [_SP+edx*OOPSIZE]
	mov		ecx, [_BP]								; Load receiver (hopefully a block, we don't check) into ECX

	CANTBEINTEGEROBJECT<ecx>
	ASSUME	ecx:PTR OTE

	mov		edx, [ecx].m_location					; Load pointer to receiver
	ASSUME	edx:PTR BlockClosure

	cmp		al, [edx].m_info.argumentCount			; Compare arg counts
	jne		localPrimitiveFailure0					; No
	ASSUME	eax:NOTHING								; EAX no longer needed

	pop		eax										; Discard saved _BP which we no longer need

	mov		eax, [edx].m_receiver
	mov		[_BP], eax								; Overwrite receiving block with block receiver (!)

	; Leave SP point at TOS, BP to point at [receiver+1],  ECX contains receiver Oop, EDX pointer to block body
	add		_BP, OOPSIZE

	call	activateBlock							; Pass control to block activation routine in byteasm.asm. Expects ECX=OTE* & EDX = *block
	mov		eax, _SP								; primitiveSuccess(0)
	ret

localPrimitiveFailure0:
	pop	_BP											; Restore saved base pointer
	PrimitiveFailureCode 0

ENDPRIMITIVE primitiveValue

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; The entry validation is a copy of that from primitiveValue.
; The sender MUST be a MethodContext for this to work (i.e. pHome must point at the sender)
;
BEGINPRIMITIVE primitiveValueOnUnwind
	mov		ecx, [_SP-OOPSIZE]					; Load receiver (under the unwind block)
	CANTBEINTEGEROBJECT <ecx>					; Context not a real object (Blocks should always be objects)!!
	mov		edx, [ecx].m_location				; Load address of receiver into eax
	ASSUME	edx:PTR BlockClosure

	cmp		[edx].m_info.argumentCount, 0		; Must be a zero arg block ...
	jne		localPrimitiveFailure0				; ... if not fail it

	;; Past this point, the primitive is guaranteed to succeed
	;; Make room for the closure receiver on top of the unwind block for activateBlock 
	;; leaving the unwind block and the guarded receiver block on the stack of the caller
	add		_SP, OOPSIZE

	;; Replace the receiver of the calling method context with the special mark object
	;; The receiver's ref. count remains the same because it will be stored into the m_environment
	;; slot of the new stack frame by activateBlock.
	;; There are no arguments to move, because our receiver is a zero arg block
	mov		eax, [Pointers.MarkedBlock]
	push	[ACTIVEFRAME]
	mov		[_BP-OOPSIZE], eax					; Overwrite receiver of calling frame with mark block
	
	lea		_BP, [_SP+OOPSIZE]					; Set up BP for new frame

	; ECX mut be block Oop
	; EDX must be pointer to block body
	; _SP points at TOS
	; _BP points at [receiver+1] (i.e. already set up correctly)

	call	activateBlock
	pop		eax
	ASSUME eax:PStackFrame
	sub		[eax].m_sp, OOPSIZE*2
	mov		eax, _SP							; primitiveSuccess(0)
	ret

LocalPrimitiveFailure 0

ENDPRIMITIVE primitiveValueOnUnwind


IF 0
;; Under construction
?primitivePerformInterpreter@@CIPAIAAVCompiledMethod@ST@@I@Z:
	mov		eax, [MESSAGE]							; Load current message selector (#perform:???) ...
	push	eax										; ... and save in case need to restore
	lea		eax, [edx*4]
	neg		eax
	mov		ecx, [_SP+eax]							; Load receiver from stack
	mov		ecx, (OTE PTR[ecx]).m_location
	mov		ecx, (Object PTR[ecx]).m_class
	mov		eax, [_SP+eax+OOPSIZE]					; Load selector from stack
	mov		[MESSAGE], eax							; Store down as new message selector
	StoreSPRegister									; Save down stack pointer (in case of DNU)
	push	dl										; Save the arg count (0.255)
	call	FINDMETHODINCLASS
	pop		dl										; Pop off the saved arg count ...
	dec		dl										; ... and deduct 1 for the selector
	mov		_SP, [STACKPOINTER]						; Restore stack pointer (in case of does not understand)
	mov		ecx, (OTE PTR[eax]).m_location			; Load address of new method object into eax
	cmp		dl, (CompiledMethod PTR[ecx]).m_header.m_argumentCount	; Arg counts match ?
	je		@F										; Yes, ok to perform it
	mov		ecx, [MESSAGE]
	cmp		ecx, [Pointers.DoesNotUnderstandSelector]
	je		@F										; We also allow any doesNotUnderstand: to continue
	jmp		failPrimitivePerform					; Fail the primitive due to arg count mismatch
@@:
	;; So now we know the perform can proceed
	pop		ecx										; Pop off the #perform:??? selector

	;; We must reduce the arg count of the selector, because we're going
	;; to shuffle the args down over the top of it
	;; We can safely count down the selector by a simple decrement, since
	;; we know it can't go away (its a Symbol).
	mov		ecx, [MESSAGE]
	cmp		(OTE PTR[ecx]).m_count, 0ffh			; Overflowed - very unlikely?
	je		@F										; Yes, skip the decrement
	dec		(OTE PTR[ecx]).m_count
@@:
	;; Now we can shuffle the args down over the selector


failPrimitivePerform:
	pop		eax										; Pop off current message selector (#perform: or similar)
	mov		[MESSAGE], eax							; Restore old message selector into global
	xor		eax, eax								; Return FALSE
	ret

ENDIF


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  BOOL __fastcall Interpreter::primitiveAllInstances()
;
BEGINPRIMITIVE primitiveAllInstances
	mov		ecx, [_SP]						; Load receiver class at stack top
	call	INSTANCESOF
	mov		[_SP], eax						; Overwrite receiver with new object
	AddToZctNoSP <a>
	mov		eax, _SP						; primitiveSuccess(0)
	ret
ENDPRIMITIVE primitiveAllInstances

BEGINPRIMITIVE primitiveInstanceCounts
	mov		ecx, [_SP]						; Load arg stack top
	test	cl, 1
	jnz		localPrimitiveFailure0
	ASSUME	ecx:PTR OTE	
	cmp		ecx, [Pointers.Nil]
	je		@F
	mov		edx, [Pointers.ClassArray]
	cmp		[ecx].m_oteClass, edx
	jne		localPrimitiveFailure0
@@:	
	call	INSTANCECOUNTS
	mov		[_SP-OOPSIZE], eax						; Overwrite receiver with new object
	AddToZct <a>
	lea		eax, [_SP-OOPSIZE]						; primitiveSuccess(1)
	ret

LocalPrimitiveFailure 0

ENDPRIMITIVE primitiveInstanceCounts

;  BOOL __fastcall Interpreter::primitiveAllInstances()
;
BEGINPRIMITIVE primitiveAllSubinstances
	mov		ecx, [_SP]						; Load receiver class at stack top
	call	SUBINSTANCESOF
	mov		[_SP], eax						; Overwrite receiver with new object
	AddToZctNoSP <a>
	mov		eax, _SP						; primitiveSuccess(0)
	ret
ENDPRIMITIVE primitiveAllSubinstances


;  BOOL __fastcall Interpreter::primitiveObjectCount()
;
BEGINPRIMITIVE primitiveObjectCount
	call	OOPSUSED
	lea		ecx, [eax+eax+1]				; Convert result to SmallInteger
	mov		eax, _SP						; primitiveSuccess(0)
	mov		[_SP], ecx						; Overwrite receiver class with new object
	ret
ENDPRIMITIVE primitiveObjectCount

BEGINPRIMITIVE primitiveExtraInstanceSpec
	mov		ecx, [_SP]						; Load receiver class at stack top
	mov		edx, (OTE PTR[ecx]).m_location
	ASSUME	edx:PTR Behavior

	mov		ecx, [edx].m_instanceSpec
	shr		ecx, 15							; Shift to get the high 16 bits
	or		ecx, 1							; Set SmallInteger flag
	mov		eax, _SP						; primitiveSuccess(0)
	mov		[_SP], ecx						; Overwrite receiver class with new object (receiver's ref. count remains same)
	ret
ENDPRIMITIVE primitiveExtraInstanceSpec

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Set the special behavior bits of an object according to the mask
; Takes a SmallInteger argument, of which only the low order word is significant.
; The high order byte of the low order word specifies the AND mask, used to mask out bits,
; The low order byte of the low order word specifies the OR mask, used to mask in bits.
; The current value of the special behavior bits is then answered.
; The primitive ensures that the current values of bits which may affect the stability of the
; system cannot be modified.
; To query the current value of the special bits, pass in 16rFF00.
BEGINPRIMITIVE primitiveSetSpecialBehavior
	mov		edx, [_SP]							; Load integer mask argument
	sar		edx, 1								; Get the integer value
	jnc		localPrimitiveFailure0						; Not a SmallInteger
	
	; No other failures after this point
	mov		ecx, [_SP-OOPSIZE]					; Load Oop of receiver
	
	test	cl, 1
	jnz		localPrimitiveFailure1				; SmallIntegers can't have special behavior
	ASSUME ecx:PTR OTE							; ECX is now an Oop

	; Ensure the masks cannot affect the critical bits of the flags
	; dh, the AND mask, must have the pointer, mark, and free bits set, to keep these bits
	; dl, the OR mask, must have those bits reset so as not to add them
	or		dh, (MASK m_pointer OR MASK m_mark OR MASK m_free OR MASK m_space)
	and		dl, NOT (MASK m_pointer OR MASK m_mark OR MASK m_free OR MASK m_space)

	xor		eax, eax
	mov		al, [ecx].m_flags
	push	eax									; Save for later
	and		al, dh								; Mask out the desired bits
	or		al, dl								; Mask in the desired bits
	mov		[ecx].m_flags, al
	ASSUME	ecx:NOTHING
	pop		ecx
	lea		eax, [_SP-OOPSIZE]					; primitiveSuccess(1)
	lea		ecx, [ecx+ecx+1]					; Convert old mask to SmallInteger
	mov		[_SP-OOPSIZE], ecx					; Store old mask as return value

	ret

LocalPrimitiveFailure 0
LocalPrimitiveFailure 1

ENDPRIMITIVE primitiveSetSpecialBehavior


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  BOOL __fastcall Interpreter::primitiveChangeBehavior()
;
; Receiver becomes an instance of the class specified as the argument - neither
; receiver or arg may be SmallIntegers, and the shape of the receivers current class
; must be identical to its new class.
;
BEGINPRIMITIVE primitiveChangeBehavior
	mov		edx, [_SP]								; Load arg Oop into edx
	test	dl, 1									; Is it a SmallInteger
	jnz		localPrimitiveFailure0					; Yes, fail it (must be a Class object)
	
	ASSUME	edx:PTR OTE								; Its an object

	; We must determine if the argument is a Class - get the head strap out and
	; then remember:
	;	A class' class is an instance of Metaclass (e.g. if we send #class to
	;	to Object, then we get the Metaclass instance 'Object class') THEREFORE
	; The class of the class of a Class is Metaclass!
	; Because of our use of an Object table, we've got 5 indirections here!
	
	mov		ecx, [edx].m_oteClass					; Load class Oop of new class into ecx
	ASSUME	ecx:PTR OTE

	mov		edx, (OTE PTR[edx]).m_location
	ASSUME	edx:PTR Behavior						; EDX is now pointer to new class object

	mov		ecx, [ecx].m_oteClass					; Load new Oop of class' class' class
	cmp		ecx, [Pointers.ClassMetaclass]			; Is the new class argument a class? (i.e. it's an instance of Metaclass)
	jne		localPrimitiveFailure1					; No not a class, fail the primitive

	; We have established that the argument is indeed a Class object, now
	; lets examine the receiver
	mov		eax, [_SP-OOPSIZE]						; Access receiver under class arg
	test	al, 1									; Receiver is a SmallInteger?
	jz		@F										; No, skip to normal object mutation

	; The receiver is a SmallInteger, and can be mutated to a variable byte object
	; which we have to allocate
	
	; Do instances of the new class contain pointers
	test    [edx].m_instanceSpec, MASK m_pointers
	jnz		localPrimitiveFailure2					; Yes, fail the primitive

	ASSUME	edx:NOTHING

	PopOopInto	<ecx>						; Reload Oop of new class
	ASSUME	ecx:DWORD
	
	mov		edx, SIZEOF DWORD				; 4-byte integer (32 bits)
	ASSUME	edx:DWORD

	call	ALLOCATEBYTESNOZERO
	ASSUME	eax:PTR OTE
	mov		edx, [_SP]						; Reload SmallInteger receiver before overwritten
	mov		[_SP], eax						; Replace SmallInteger at ToS receiver with new object
	mov		ecx, [eax].m_location			; Load address of new object
	ASSUME	ecx:PTR DWORDBytes
	sar		edx, 1							; Convert receiver to real integer value
	mov		[ecx].m_value, edx				; Save receivers integer value into new object
	AddToZct <a>
	mov		eax, _SP						; primitiveSuccess(0)
	ret
	ASSUME	eax:NOTHING

LocalPrimitiveFailure 0
LocalPrimitiveFailure 1

@@:
	;; The receiver is a non-immediate object

	ASSUME	edx:PTR Behavior					; EDX is still pointer to new class object
	ASSUME	eax:PTR OTE							; EAX is OTE of receiver

	;; The receiver is not a SmallInteger, check class shapes the same
	
	mov		ecx, [eax].m_oteClass				; Load class Oop of receiver into ecx
	ASSUME	ecx:PTR OTE

	mov		ecx, [ecx].m_location				; Load address of receiver's class into ecx
	ASSUME	ecx:PTR Behavior					; ECX is now pointer to the receiver's class

	; Compare instance _SPec. of receivers class with that of new class
	mov		ecx, [ecx].m_instanceSpec
	ASSUME	ecx:DWORD
	xor		ecx, [edx].m_instanceSpec			; Get shape differences into ecx

	test	ecx, SHAPEMASK						; Test to see if any significant bits differ
	jnz		localPrimitiveFailure2				; Some significant bits differenct, fail the primitive

	PopOopInto <edx>							; Reload the new class Oop
	mov		ecx, [eax].m_oteClass				; Save current class Oop of receiver in ecx (ready for count down)
	mov		[eax].m_oteClass, edx				; Set new class of receiver (which is left on top of stack)
	
	; We must reduce the count on the class, since it has been overwritten in the object, and count up the new class
	CountUpObjectIn <d>
	CountDownObjectIn <c>
	
	mov		eax, _SP							; primitiveSuccess(0)

	ret

LocalPrimitiveFailure 2

ENDPRIMITIVE primitiveChangeBehavior

ASSUME	eax:NOTHING
ASSUME	edx:NOTHING

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BEGINPRIMITIVE primitiveBecome
	mov		ecx, [_SP]
	mov		eax, [OBJECTTABLE]
	test	cl, 1
	jnz		localPrimitiveFailure0				; Can't swap SmallIntegers
	ASSUME	ecx:PTR OTE

	add		eax, FIRSTCHAROFFSET+256*OTENTRYSIZE
	cmp		ecx, eax
	jl		localPrimitiveFailure0

	mov		edx, [_SP-OOPSIZE]
	test	dl, 1
	jnz		localPrimitiveFailure0
	ASSUME	edx:PTR OTE

	cmp		edx, eax
	jl		localPrimitiveFailure0

	; THIS MUST BE CHANGED IF OTE LAYOUT CHANGED.
	; Note that we swap the location pointer (obviously), the class pointer (as we
	; aren't swapping the class), and flags. All belong with the object.
	; We don't swap the identity hash or count, as these belong with the pointer (identity)

	push	ebx

	; We must flush both from At(Put) caches as any cached information will be invalidated
	mov		eax, ecx
	xor		ebx, ebx
	and		eax, AtCacheMask
	mov		_AtCache[eax].oteArray, ebx
	mov		_AtPutCache[eax].oteArray, ebx
	mov		eax, edx
	and		eax, AtCacheMask
	mov		_AtCache[eax].oteArray, ebx
	mov		_AtPutCache[eax].oteArray, ebx

	; Exchange body pointers
	mov		ebx, [ecx].m_location
	mov		eax, [edx].m_location
	mov		[ecx].m_location, eax
	mov		[edx].m_location, ebx

	; Exchange class pointers
	mov		ebx, [ecx].m_oteClass
	mov		eax, [edx].m_oteClass
	mov		[ecx].m_oteClass, eax
	mov		[edx].m_oteClass, ebx

	; Exchange object sizes (I think it is right to swap immutability bit over too?)
	mov		ebx, [ecx].m_size
	mov		eax, [edx].m_size
	mov		[ecx].m_size, eax
	mov		[edx].m_size, ebx
	
	; Exchange first 8 bits of flags (exclude identityHash and ref. count)
	mov		bl, [ecx].m_flags
	mov		al, [edx].m_flags
	mov		[ecx].m_flags, al
	mov		[edx].m_flags, bl

	pop		ebx

	lea		eax, [_SP-OOPSIZE]				; primitiveSuccess(1)
	ret

LocalPrimitiveFailure 0

ENDPRIMITIVE primitiveBecome

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BEGINPRIMITIVE primitiveOneWayBecome
	mov		ecx, [_SP-OOPSIZE]
	mov		edx, [_SP]
	mov		eax, [OBJECTTABLE]
	test	cl, 1
	lea		eax, [eax+FIRSTCHAROFFSET+256*OTENTRYSIZE]
	jnz		localPrimitiveFailure0
	cmp		ecx, eax
	jl		localPrimitiveFailure0

	; oneWayBecome deallocates the become'd object, which flushes it from the at(put) caches
	call	ONEWAYBECOME

	lea		eax, [_SP-OOPSIZE]				; primitiveSuccess(1)
	ret

LocalPrimitiveFailure 0

ENDPRIMITIVE primitiveOneWayBecome


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Dequeue an entry from the finalization queue, and answer it. Answers nil if the queue is empty
BEGINPRIMITIVE primitiveDeQForFinalize
	call	DQFORFINALIZATION							; Answers nil, or an Oop with raised ref.count
	mov		[_SP], eax									; Overwrite TOS with answer, and count it down
	CountDownObjectIn <a>								; Remove the ref from the queue - will probably place object in the Zct
	mov		eax, _SP									; primitiveSuccess(0)
	ret
ENDPRIMITIVE primitiveDeQForFinalize

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Queue an aysnchronous interrupt to the receiving process
BEGINPRIMITIVE primitiveQueueInterrupt
	mov		ecx, [_SP-OOPSIZE*2]				; Load Oop of receiver
	mov		edx, [_SP-OOPSIZE]					; Load interrupt number

	test	dl, 1								; 
	jz		localPrimitiveFailure0				; Not a SmallInteger

	mov		eax, (OTE PTR[ecx]).m_location
	mov		eax, (Process PTR[eax]).m_suspendedFrame
	cmp		eax, [oteNil]						; suspended context is nil if terminated
	mov		eax, [_SP]							; Load TOS (extra arg). Doesn't affect flags
	je		localPrimitiveFailure1

	push	eax									; ARG 3: opaque argument passed on the stack
	push	edx									; ARG 2: Interrupt number
	push	ecx									; ARG 1: Process Oop

	call	QUEUEINTERRUPT

	lea		eax, [_SP-OOPSIZE*2]				; primitiveSuccess(2)
	ret

LocalPrimitiveFailure 0
LocalPrimitiveFailure 1

ENDPRIMITIVE primitiveQueueInterrupt

BEGINPRIMITIVE primitiveEnableInterrupts
	mov		eax, [_SP]							; Access argument
	xor		ecx, ecx
	sub		eax, [oteTrue]
	jz		@F

	cmp		eax, OTENTRYSIZE
	jne		localPrimitiveFailure0				; Non-boolean arg
	
	mov		ecx, 1								; arg=false, so disable interrupts

@@:
	call	DISABLEINTERRUPTS
	; N.B. Returns bool, so only AL will be set, not whole of EAX
	test	al, al								; Interrupts not previously disabled?
	je		@F									; Yes, answer true

	mov		ecx, [oteFalse]
	lea		eax, [_SP-OOPSIZE]					; primitiveSuccess(1)
	mov		[_SP-OOPSIZE], ecx
	ret

@@:
	mov		ecx, [oteTrue]
	lea		eax, [_SP-OOPSIZE]					; primitiveSuccess(1)
	mov		[_SP-OOPSIZE], ecx
	ret

LocalPrimitiveFailure 0

ENDPRIMITIVE primitiveEnableInterrupts

BEGINPRIMITIVE primitiveYield
	call	YIELD
	
	; LoadInterpreterRegisters
	mov		eax, [STACKPOINTER]					; primitiveSuccess(0)
	LoadIPRegister
	LoadBPRegister

	ret
ENDPRIMITIVE primitiveYield

BEGINPRIMITIVE primitiveStructureIsNull
	mov		ecx, [_SP]								; Access argument
	ASSUME	ecx:PTR OTE
	mov		eax, [oteFalse]							; Use EAX for true/false so is non-zero on exit from primitive

	; Ok, it might still be an object whose first inst var might be an address
	mov		edx, [ecx].m_location					; Ptr to object now in edx
	ASSUME	edx:PTR ExternalStructure

	mov		edx, [edx].m_contents					; OK, so lets see if first inst var is the 'address' we seek
	sar		edx, 1									; First of all, is it a SmallInteger
	jc		zeroTest								; Yes, test to see if that is zero

	ASSUME	edx:PTR OTE								; No, its an object
	sal		edx, 1									; so revert to OTE
	test	[edx].m_flags, MASK m_pointer			; Is it bytes?
	je		@F

	mov		eax, [oteTrue]
	cmp		edx, [oteNil]
	jne		localPrimitiveFailure0					; Not nil, a SmallInteger, nor a byte object, so invalid
	jmp		answer									; Answer true (nil is null)
	
@@:
	mov		eax, [edx].m_oteClass					; Get oop of class of bytes into eax
	ASSUME	eax:PTR OTE

	mov		edx, [edx].m_location					; Get ptr to byte object into edx
	ASSUME	edx:PTR ByteArray						; We know we've got a byte object now

	mov		eax, [eax].m_location					; eax is ptr to class of object
	ASSUME	eax:PTR Behavior

	test	[eax].m_instanceSpec, MASK m_indirect	; Is it an indirection class?
	mov		eax, [oteFalse]
	jz		answer									; No, can't be null then

	ASSUME	edx:PTR ExternalAddress
	
	; Otherwise drop through and test the address to see if it is zero
	mov		edx, [edx].m_pointer					; Preload address value

zeroTest:
	ASSUME	edx:DWORD								; Integer pointer value
	ASSUME	ecx:PTR OTE								; Expected to contain pre-loaded "true"

	cmp		edx, 0
	jne		answer
	sub		eax, OTENTRYSIZE						; True immediately preceeds False in the OT

answer:
	mov		[_SP], eax
	mov		eax, _SP								; primitiveSuccess(0)
	ret

LocalPrimitiveFailure 0

ENDPRIMITIVE primitiveStructureIsNull

BEGINPRIMITIVE primitiveBytesIsNull
	mov		eax, [_SP]								; Access argument
	ASSUME	eax:PTR OTE
	mov		ecx, [oteFalse]							; Load ECX with default answer (false)

	mov		edx, [eax].m_size
	and		edx, 7fffffffh							; Mask out immutability bit
	cmp		edx, SIZEOF DWORD						; Must be exactly 4 bytes (excluding any header)

	jne		localPrimitiveFailure0					; If not 32-bits, fail the primitive

	mov		edx, [eax].m_location					; Ptr to object now in edx
	ASSUME	edx:PTR ByteArray						; We know we've got a byte object now

	mov		eax, _SP								; primitiveSuccess(0)

	.IF (DWORD PTR([edx].m_elements[0]) == 0)
		sub		ecx, OTENTRYSIZE					; True immediately preceeds False in the OT
	.ENDIF
	
	mov		[_SP], ecx
	ret

LocalPrimitiveFailure 0

ENDPRIMITIVE primitiveBytesIsNull

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; LargeInteger primitives
;;
.CODE LIPRIM_SEG

;; Macro for operations for which the result is the receiver if the operand is zero
LIARITHMPRIMR MACRO Op 
	li&Op&Single EQU ?li&Op&Single@@YGIPAV?$TOTE@VLargeInteger@ST@@@@H@Z
	extern li&Op&Single:near32

	li&Op EQU ?li&Op&@@YGIPAV?$TOTE@VLargeInteger@ST@@@@0@Z
	extern li&Op&:near32

	BEGINPRIMITIVE primitiveLargeInteger&Op
		mov		eax, [_SP]
		mov		ecx, [_SP-OOPSIZE]							; Load receiver (under argument)
		ASSUME	ecx:PTR OTE

		.IF	(al & 1)										; SmallInteger?
			ASSUME	eax:Oop
			sar		eax, 1
			jz		noOp									; Operand is zero? - result is receiver
			push	eax
			push	ecx
			; N.B. SP not saved down here, so assumed not used by routine (which is independent)
			call	li&Op&Single
		.ELSE
			ASSUME	eax:PTR OTE

			mov		edx, [eax].m_oteClass
			cmp		edx, [Pointers.ClassLargeInteger]
			jne		localPrimitiveFailure0

			push	eax
			push	ecx
			call	li&Op
		.ENDIF

		; Normalize and return
		push	eax
		call	normalizeIntermediateResult
		test	al, 1
		mov		[_SP-OOPSIZE], eax						; Overwrite receiver class with new object
		jnz		noOp
		AddToZct <a>

	noOp:
		lea		eax, [_SP-OOPSIZE]						; primitiveSuccess(0)
		ret
		
	LocalPrimitiveFailure 0

	ENDPRIMITIVE primitiveLargeInteger&Op
ENDM

;; Macro for operations for which the result is zero if the operand is zero
LIARITHMPRIMZ MACRO Op 
	li&Op&Single EQU ?li&Op&Single@@YGIPAV?$TOTE@VLargeInteger@ST@@@@H@Z
	extern li&Op&Single:near32

	li&Op EQU ?li&Op&@@YGIPAV?$TOTE@VLargeInteger@ST@@@@0@Z
	extern li&Op&:near32

	BEGINPRIMITIVE primitiveLargeInteger&Op
		mov		eax, [_SP]
		mov		ecx, [_SP-OOPSIZE]							; Load receiver (under argument)
		ASSUME	ecx:PTR OTE

		.IF	(al & 1)										; SmallInteger?
			ASSUME	eax:Oop
			sar		eax, 1
			jz		zero
			push	eax
			push	ecx
			; N.B. SP not saved down here, so assumed not used by routine (which is independent)
			call	li&Op&Single
		.ELSE
			ASSUME	eax:PTR OTE

			mov		edx, [eax].m_oteClass
			cmp		edx, [Pointers.ClassLargeInteger]
			jne		localPrimitiveFailure0

			push	eax
			push	ecx
			call	li&Op
		.ENDIF

		; Normalize and return
		push	eax
		call	normalizeIntermediateResult
		test	al, 1
		mov		[_SP-OOPSIZE], eax						; Overwrite receiver class with new object
		jnz		@F
		AddToZct <a>
	@@:
		lea		eax, [_SP-OOPSIZE]						; primitiveSuccess(1)
		ret

	zero:
		lea		eax, [_SP-OOPSIZE]						; primitiveSuccess(1)
		mov		[_SP-OOPSIZE], SMALLINTZERO
		ret
		
	LocalPrimitiveFailure 0

	ENDPRIMITIVE primitiveLargeInteger&Op
ENDM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
LIARITHMPRIMR Add

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
LIARITHMPRIMR Sub

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
LIARITHMPRIMZ Mul

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
LIARITHMPRIMZ BitAnd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
LIARITHMPRIMR BitOr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
LIARITHMPRIMR BitXor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BEGINPRIMITIVE primitiveLargeIntegerNormalize
	mov		eax, [_SP]
	push	eax
	call	liNormalize
	test	al, 1
	mov		[_SP], eax					; Overwrite stack top with new Oop
	jnz		@F	
	AddToZctNoSP <a>
@@:
	mov		eax, _SP					; primitiveSuccess(0)
	ret
ENDPRIMITIVE primitiveLargeIntegerNormalize	

BEGINPRIMITIVE primitiveLargeIntegerBitInvert
	mov		eax, [_SP]

	ASSUME	eax:PTR OTE
	push	eax
	call	liBitInvert
	test	al, 1
	mov		[_SP], eax					; Overwrite stack top with new Oop
	jnz		@F	
	AddToZctNoSP <a>
@@:
	mov		eax, _SP					; primitiveSuccess(0)
	ret
ENDPRIMITIVE primitiveLargeIntegerBitInvert


BEGINPRIMITIVE primitiveLargeIntegerNegate
	mov		eax, [_SP]

	ASSUME	eax:PTR OTE
	push	eax
	call	liNegate
	test	al, 1
	mov		[_SP], eax					; Overwrite stack top with new Oop
	jnz		@F	
	AddToZctNoSP <a>
@@:
	mov		eax, _SP					; primitiveSuccess(0)
	ret
ENDPRIMITIVE primitiveLargeIntegerNegate

.CODE PRIM_SEG

; Note that the failure code is not set.
BEGINPRIMITIVE unusedPrimitive
	xor		eax, eax
	ret
ENDPRIMITIVE unusedPrimitive

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; C++ Primitive Thunks
;; Thunks for control (context switching) primitives
;; Other C++ primitives no longer need thunks (the convention is to return the
;; adjusted stack pointer on success, or NULL on failure)

BEGINPRIMITIVE primitiveAsyncDLL32CallThunk
	CallContextPrim <primitiveAsyncDLL32Call>
ENDPRIMITIVE primitiveAsyncDLL32CallThunk

BEGINPRIMITIVE primitiveValueWithArgsThunk
	CallContextPrim <primitiveValueWithArgs>
ENDPRIMITIVE primitiveValueWithArgsThunk

BEGINPRIMITIVE primitivePerformThunk
	CallContextPrim <primitivePerform>
ENDPRIMITIVE primitivePerformThunk

BEGINPRIMITIVE primitivePerformWithArgsThunk
	CallContextPrim <primitivePerformWithArgs>
ENDPRIMITIVE primitivePerformWithArgsThunk

BEGINPRIMITIVE primitivePerformWithArgsAtThunk
	CallContextPrim <primitivePerformWithArgsAt>
ENDPRIMITIVE primitivePerformWithArgsAtThunk

BEGINPRIMITIVE primitivePerformMethodThunk
	CallContextPrim <primitivePerformMethod>
ENDPRIMITIVE primitivePerformMethodThunk

BEGINPRIMITIVE primitiveValueWithArgsAtThunk
	CallContextPrim <primitiveValueWithArgsAt>
ENDPRIMITIVE primitiveValueWithArgsAtThunk

BEGINPRIMITIVE primitiveSignalThunk
	CallContextPrim <primitiveSignal>
ENDPRIMITIVE primitiveSignalThunk

BEGINPRIMITIVE primitiveSingleStepThunk
	CallContextPrim	<PRIMITIVESINGLESTEP>
ENDPRIMITIVE primitiveSingleStepThunk

BEGINPRIMITIVE primitiveResumeThunk
	CallContextPrim	<PRIMITIVERESUME>
ENDPRIMITIVE primitiveResumeThunk

BEGINPRIMITIVE primitiveWaitThunk
	CallContextPrim <PRIMITIVEWAIT>
ENDPRIMITIVE primitiveWaitThunk

BEGINPRIMITIVE primitiveSuspendThunk
	CallContextPrim <?primitiveSuspend@Interpreter@@CIPAIXZ>
ENDPRIMITIVE primitiveSuspendThunk

BEGINPRIMITIVE primitiveTerminateThunk
	CallContextPrim <?primitiveTerminateProcess@Interpreter@@CIPAIXZ>
ENDPRIMITIVE primitiveTerminateThunk

BEGINPRIMITIVE primitiveSetSignalsThunk
	CallContextPrim <?primitiveSetSignals@Interpreter@@CIPAIXZ>
ENDPRIMITIVE primitiveSetSignalsThunk

BEGINPRIMITIVE primitiveProcessPriorityThunk
	CallContextPrim <?primitiveProcessPriority@Interpreter@@CIPAIXZ>
ENDPRIMITIVE primitiveProcessPriorityThunk

BEGINPRIMITIVE primitiveUnwindInterruptThunk
	CallContextPrim <PRIMUNWINDINTERRUPT>
ENDPRIMITIVE primitiveUnwindInterruptThunk

;; The specification primitiveSignalAtTick requires that it immediately signal
;; the specified semaphore if the time has already passed, so we must call
;; it as potentially context switching primitive
BEGINPRIMITIVE primitiveSignalAtTickThunk
	CallContextPrim <primitiveSignalAtTick>
ENDPRIMITIVE primitiveSignalAtTickThunk

BEGINPRIMITIVE primitiveIndexOfSP
	mov	ecx, [_SP-OOPSIZE]				; Receiver
	mov	eax, [_SP]						; Frame Oop (i.e. frame address + 1)
	test al, 1
	jz	 localPrimitiveFailure0
	
	sub	eax, OFFSET Process.m_stack
	mov	edx, (OTE PTR[ecx]).m_location	; Load address of object
	sub	eax, edx
	shr	eax, 1							; Only div byte offset by 2 as need a SmallInteger
	add	eax, 3							; Add 1 (to convert zero-based offset to 1 based index) and flag as SmallInteger
	mov	[_SP-OOPSIZE], eax
	lea	eax, [_SP - OOPSIZE]			; primitiveSuccess(1)
	ret
	
LocalPrimitiveFailure 0
	
ENDPRIMITIVE primitiveIndexOfSP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;

;; This is actually the GC primitive, and it may switch contexts
;; because is synchronously signals a Semaphore (sometimes)
BEGINPRIMITIVE primitiveCoreLeftThunk
	CallContextPrim <primitiveCoreLeft>
ENDPRIMITIVE primitiveCoreLeftThunk

;; This is actually a GC primitive, and it may switch contexts
;; because is synchronously signals a Semaphore (sometimes)
BEGINPRIMITIVE primitiveOopsLeftThunk
	CallContextPrim <?primitiveOopsLeft@Interpreter@@CIPAIXZ>
ENDPRIMITIVE primitiveOopsLeftThunk

BEGINPRIMITIVE primitiveGetImmutable
	mov		eax, [_SP]								; Load receiver into eax
	mov		ecx, [oteTrue]
	test	al, 1
	jnz		@F
	
	ASSUME	ecx:PTR OTE								; ecx points at receiver OTE
	cmp		[eax].m_size, 0							; size < 0 ?
	jl		@F
	add		ecx, OTENTRYSIZE
@@:
	mov		[_SP], ecx								; Replace stack top with true/false

	mov		eax, _SP								; primitiveSuccess(0)
	ret

	ASSUME	ecx:NOTHING
ENDPRIMITIVE primitiveGetImmutable

BEGINPRIMITIVE primitiveSetImmutable
	mov		eax, [_SP-OOPSIZE]				; Receiver
	mov		ecx, [_SP]						; Boolean arg
	
	cmp	ecx, [oteTrue]
	jne	@F

	.IF (!(al & 1))
		ASSUME	eax:PTR OTE						; ecx points at receiver OTE

		or		[eax].m_size, 80000000h
		and		eax, AtCacheMask
		mov		_AtPutCache[eax].oteArray, 0
	.ENDIF

	lea		eax, [_SP - OOPSIZE]				; primitiveSuccess(1)
	ret

@@:
	; Marking object as mutable - cannot do this for SmallIntegers as these are always immutable
	test	al, 1
	jnz		localPrimitiveFailure0
	
	ASSUME	eax:PTR OTE							; ecx points at receiver OTE
	and		[eax].m_size, 7FFFFFFFh		
	
	lea		eax, [_SP-OOPSIZE]					; primitiveSuccess(1)
	ret											; eax is non-zero so will succeed
	
	ASSUME	eax:NOTHING
	
LocalPrimitiveFailure 0

ENDPRIMITIVE primitiveSetImmutable

END
