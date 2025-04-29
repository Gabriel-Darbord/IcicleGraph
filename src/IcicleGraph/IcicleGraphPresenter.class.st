"
### Example
```st
transcriptExec := ScpExecutionRecorder 
	recordBlock: [ Transcript open ]
	as: ScpExecutionRecordTree.
(IcicleGraphPresenter on: transcriptExec) open.
```
"
Class {
	#name : 'IcicleGraphPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'model',
		'builder',
		'graphMorph',
		'scrollablePresenter'
	],
	#category : 'IcicleGraph',
	#package : 'IcicleGraph'
}

{ #category : 'layout' }
IcicleGraphPresenter >> defaultLayout [

	^ SpScrollableLayout with: scrollablePresenter
]

{ #category : 'initialization' }
IcicleGraphPresenter >> initializePresenters [

	| width height presenter horizontalLayout verticalLayout |
	builder := IcicleGraph new.
	builder graphWidth: (width := 800).
	builder graphHeight: (height := 400).

	verticalLayout := SpBoxLayout newTopToBottom.
	scrollablePresenter := SpPresenter new.
	scrollablePresenter layout: verticalLayout.

	horizontalLayout := SpBoxLayout newLeftToRight.
	presenter := SpPresenter new.
	presenter layout: horizontalLayout.
	verticalLayout add: presenter withConstraints: [ :constraints |
		constraints
			width: width;
			height: height ].

	graphMorph := self newMorph.
	graphMorph morph: (model isCollection
			 ifTrue: [ builder fromMethods: model ]
			 ifFalse: [ builder fromExecution: model ]).
	horizontalLayout add: graphMorph withConstraints: [ :constraints |
		constraints
			width: width;
			height: height ]
]

{ #category : 'initialization' }
IcicleGraphPresenter >> initializeWindow: aWindowPresenter [

	aWindowPresenter
		title: 'Scopeo execution record trace icicle graph';
		initialExtent: 810 @ 433
]

{ #category : 'accessing - model' }
IcicleGraphPresenter >> setModelBeforeInitialization: aDomainObject [

	model := aDomainObject
]
