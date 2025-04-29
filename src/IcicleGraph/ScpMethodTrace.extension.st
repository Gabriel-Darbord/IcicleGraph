Extension { #name : 'ScpMethodTrace' }

{ #category : '*IcicleGraph' }
ScpMethodTrace >> inspectorPresenterForCallstack [

	<inspectorPresentationOrder: 10 title: 'Trace graph'>
	^ IcicleGraphPresenter on: { self }
]
