﻿"Filed out from Dolphin Smalltalk"!

External.Structure
	subclass: #'OS.ODBCTIMESTAMP'
	instanceVariableNames: ''
	classVariableNames: ''
	imports: #()
	classInstanceVariableNames: ''
	classConstants: {
			'_ODBCTIMESTAMP_Size' -> 16r10.
			'_OffsetOf_day' -> 16r4.
			'_OffsetOf_fraction' -> 16rC.
			'_OffsetOf_hour' -> 16r6.
			'_OffsetOf_minute' -> 16r8.
			'_OffsetOf_month' -> 16r2.
			'_OffsetOf_second' -> 16rA.
			'_OffsetOf_year' -> 16r0
		}!
OS.ODBCTIMESTAMP guid: (Core.GUID fromString: '{87b4c599-026e-11d3-9fd7-00a0cc3e4a32}')!
OS.ODBCTIMESTAMP comment: 'ODBCTIMESTAMP is a representation of the same named Win32 ODBC structure.

The fraction field is the number of billionths of a second, i.e. a value of 1,000,000 is one millisecond.'!
!OS.ODBCTIMESTAMP categoriesForClass!External-Data-Structured-ODBC!ODBC Interface! !
!OS.ODBCTIMESTAMP methodsFor!

asDateAndTime
	"Answers a DateAndTime which represents the receiver."

	^DateAndTime year: self year month: self month day: self day hour: self hour minute: self minute second: self second + (self fraction / 1e9)!

dateAndTime: aDateAndTime
	"Set the receiver's field values from the <DateAndTime> argument."

	^aDateAndTime dayMonthYearDo: 
			[:d :m :y |
			self
				day: d;
				month: m;
				year: y;
				hour: aDateAndTime hour;
				minute: aDateAndTime minute;
				second: aDateAndTime second truncated;
				fraction: aDateAndTime nanosecond truncated]!

day
	"Answer the <Integer> value of the receiver's 'day' field."

	^bytes uint16AtOffset: _OffsetOf_day!

day: anInteger
	"Set the receiver's 'day' field to the value of the argument, anInteger"

	bytes uint16AtOffset: _OffsetOf_day put: anInteger!

fraction
	"Answer the <Integer> value of the receiver's 'fraction' field."

	^bytes uint32AtOffset: _OffsetOf_fraction!

fraction: anInteger
	"Set the receiver's 'fraction' field to the value of the argument, anInteger"

	bytes uint32AtOffset: _OffsetOf_fraction put: anInteger!

hour
	"Answer the <Integer> value of the receiver's 'hour' field."

	^bytes uint16AtOffset: _OffsetOf_hour!

hour: anInteger
	"Set the receiver's 'hour' field to the value of the argument, anInteger"

	bytes uint16AtOffset: _OffsetOf_hour put: anInteger!

milliseconds
	"Answer the number of whole milliseconds in the fraction part of
	the receiver."

	^self fraction // 1000000!

minute
	"Answer the <Integer> value of the receiver's 'minute' field."

	^bytes uint16AtOffset: _OffsetOf_minute!

minute: anInteger
	"Set the receiver's 'minute' field to the value of the argument, anInteger"

	bytes uint16AtOffset: _OffsetOf_minute put: anInteger!

month
	"Answer the <Integer> value of the receiver's 'month' field."

	^bytes uint16AtOffset: _OffsetOf_month!

month: anInteger
	"Set the receiver's 'month' field to the value of the argument, anInteger"

	bytes uint16AtOffset: _OffsetOf_month put: anInteger!

second
	"Answer the <Integer> value of the receiver's 'second' field."

	^bytes uint16AtOffset: _OffsetOf_second!

second: anInteger
	"Set the receiver's 'second' field to the value of the argument, anInteger"

	bytes uint16AtOffset: _OffsetOf_second put: anInteger!

year
	"Answer the <Integer> value of the receiver's 'year' field."

	^bytes int16AtOffset: _OffsetOf_year!

year: anInteger
	"Set the receiver's 'year' field to the value of the argument, anInteger"

	bytes int16AtOffset: _OffsetOf_year put: anInteger! !
!OS.ODBCTIMESTAMP categoriesForMethods!
asDateAndTime!converting!public! !
dateAndTime:!accessing!public! !
day!**compiled accessors**!public! !
day:!**compiled accessors**!public! !
fraction!**compiled accessors**!public! !
fraction:!**compiled accessors**!public! !
hour!**compiled accessors**!public! !
hour:!**compiled accessors**!public! !
milliseconds!accessing!public! !
minute!**compiled accessors**!public! !
minute:!**compiled accessors**!public! !
month!**compiled accessors**!public! !
month:!**compiled accessors**!public! !
second!**compiled accessors**!public! !
second:!**compiled accessors**!public! !
year!**compiled accessors**!public! !
year:!**compiled accessors**!public! !
!

!OS.ODBCTIMESTAMP class methodsFor!

byteSize
	^_ODBCTIMESTAMP_Size!

defineFields
	"Define the fields of the ODBC TIMESTAMP structure
		self compileDefinition

	typedef struct tagTIMESTAMP_STRUCT
	{
		SQLSMALLINT    year;
		SQLUSMALLINT   month;
		SQLUSMALLINT   day;
		SQLUSMALLINT   hour;
		SQLUSMALLINT   minute;
		SQLUSMALLINT   second;
		SQLUINTEGER    fraction;
	} TIMESTAMP_STRUCT;"

	self
		defineField: #year type: Int16Field new;
		defineField: #month type: UInt16Field new;
		defineField: #day type: UInt16Field new;
		defineField: #hour type: UInt16Field new;
		defineField: #minute type: UInt16Field new;
		defineField: #second type: UInt16Field new;
		defineField: #fraction type: UInt32Field new!

fromDateAndTime: aDateAndTime
	"Answer an instance of the receiver representing the same local time as the <DateAndTime> argument."

	^self new
		dateAndTime: aDateAndTime;
		yourself!

getFieldNames
	^#(#year #month #day #hour #minute #second #fraction)! !
!OS.ODBCTIMESTAMP class categoriesForMethods!
byteSize!**compiled accessors**!constants!public! !
defineFields!public!template definition! !
fromDateAndTime:!instance creation!public! !
getFieldNames!**compiled accessors**!constants!private! !
!

