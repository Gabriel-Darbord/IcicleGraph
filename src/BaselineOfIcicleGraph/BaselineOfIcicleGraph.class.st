Class {
	#name : 'BaselineOfIcicleGraph',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfIcicleGraph',
	#package : 'BaselineOfIcicleGraph'
}

{ #category : 'baselines' }
BaselineOfIcicleGraph >> baseline: spec [

	<baseline>
	spec for: #common do: [
		spec baseline: 'ScopeoExecutionRecorder' with: [
			spec repository:
				'github://scopeo-project/scopeo-execution-recorder:main/src' ].

		spec package: 'IcicleGraph' ]
]
