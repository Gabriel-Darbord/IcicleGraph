"
An interactive icicle graph to visualize an execution trace.

Click on a node to ""zoom"" into it, setting it as the view root.
Ctrl/Cmd+Click to browse the method.
Alt/Opt+Click to inspect the trace.

### Example
```st
transcriptExec := ScpExecutionRecorder 
	recordBlock: [ Transcript open ]
	as: ScpExecutionRecordTree.

graph := IcicleGraph new.
graph graphHeight: World height / 2.
graph graphWidth: World width / 2.
morph := graph fromExecution: transcriptExec.

morph position: World width * 63 / 128 @ (World height / 4).
morph openInWorld.
```

### TODO
- Indication when message sent is different from executed method (DNU).
- Minimum node height? There can be too many layers for the text to be visible.
- Meaningful method colors? Currently used for distinction and has no semantics.
"
Class {
	#name : 'IcicleGraph',
	#superclass : 'Object',
	#instVars : [
		'graphHeight',
		'graphWidth',
		'colorIndex',
		'nodeHeight',
		'rootMorph',
		'minimumNodeWidth',
		'rootHistory',
		'weightCache',
		'weightFactor',
		'colorPalette',
		'currentRoots',
		'nodesWithZoom'
	],
	#classVars : [
		'CacheGlobalThreshold',
		'CacheLocalThreshold'
	],
	#category : 'IcicleGraph',
	#package : 'IcicleGraph'
}

{ #category : 'colors' }
IcicleGraph class >> candyColors [

	^ {
		  (Color fromHexString: 'AECBFA'). "Light Blue"
		  (Color fromHexString: 'A7F3D0'). "Mint Green"
		  (Color fromHexString: 'FEF9C3'). "Lemon Yellow"
		  (Color fromHexString: 'FBCFE8'). "Peach"
		  (Color fromHexString: 'FECACA') "Soft Red" }
]

{ #category : 'colors' }
IcicleGraph class >> flameColors [

	^ {
		  (Color fromHexString: 'B90F24'). "cadmium purple"
		  (Color fromHexString: 'E62524'). "lust"
		  (Color fromHexString: 'EE6C20'). "vivid tangelo"
		  (Color fromHexString: 'F4A41F'). "marigold"
		  (Color fromHexString: 'F6D729') "dandelion" }
]

{ #category : 'colors' }
IcicleGraph class >> forestColors [

	^ {
		  (Color fromHexString: '137547'). "dark spring green"
		  (Color fromHexString: '2A9134'). "forest green"
		  (Color fromHexString: '3FA34D'). "pigment green"
		  (Color fromHexString: '5BBA6F'). "emerald green"
		  (Color fromHexString: '32CD32') "lime green" }
]

{ #category : 'colors' }
IcicleGraph class >> icyColors [

	^ {
		  (Color fromHexString: '#00838F'). "cold steel"
		  (Color fromHexString: '#00ACC1'). "deep ice blue"
		  (Color fromHexString: '#26C6DA'). "frozen teal"
		  (Color fromHexString: '#80DEEA'). "soft aqua"
		  (Color fromHexString: '#B2EBF2') "pale turquoise" }
]

{ #category : 'class initialization' }
IcicleGraph class >> initialize [
	"Arbitrary values to try and get a comfortable caching density.
	The ideal solution would be dynamic thresholds :)"

	CacheLocalThreshold := 50.
	CacheGlobalThreshold := 1000
]

{ #category : 'colors' }
IcicleGraph class >> jellybeanColors [

	^ {
		  (Color fromHexString: 'D6BCFA'). "Soft Purple"
		  (Color fromHexString: 'AFE1AF'). "Celadon"
		  (Color fromHexString: 'FBD38D'). "Light Orange"
		  (Color fromHexString: 'FEB2B2'). "Baby Pink"
		  (Color fromHexString: '90CDF4') "Sky Blue" }
]

{ #category : 'colors' }
IcicleGraph class >> neonColors [

	^ {
		  (Color fromHexString: '001EFF'). "blue overdose"
		  (Color fromHexString: '00FFEF'). "turquoise blue"
		  (Color fromHexString: 'FFE700'). "yellow"
		  (Color fromHexString: '74EE15'). "hypnotic green"
		  (Color fromHexString: 'F000FF') "electric violet" }
]

{ #category : 'colors' }
IcicleGraph class >> pastelColors [

	^ {
		  (Color fromHexString: 'B2CEFE'). "columbia blue"
		  (Color fromHexString: 'BAED91'). "sulu green"
		  (Color fromHexString: 'FAF884'). "honeysuckle yellow"
		  (Color fromHexString: 'F8B88B'). "Manhattan orange"
		  (Color fromHexString: 'FEA3AA') "pastel pink" }
]

{ #category : 'colors' }
IcicleGraph class >> rainbowColors [

	^ {
		  (Color fromHexString: '8888FF').
		  (Color fromHexString: '88FFFF').
		  (Color fromHexString: '88FF88').
		  (Color fromHexString: 'FFFF88').
		  (Color fromHexString: 'FFAF0F').
		  (Color fromHexString: 'FF8888').
		  (Color fromHexString: 'FF88FF') }
]

{ #category : 'colors' }
IcicleGraph class >> randomColors [

	^ self perform: (self class selectors select: [ :selector |
			   selector ~= #randomColors and: [ selector endsWith: 'Colors' ] ])
			  atRandom
]

{ #category : 'colors' }
IcicleGraph class >> skyColors [

	^ {
		  (Color fromHexString: '963484'). "plum"
		  (Color fromHexString: '3066be'). "true blue"
		  (Color fromHexString: '60afff'). "argentinian blue"
		  (Color fromHexString: '28c2ff'). "deep sky blue"
		  (Color fromHexString: '2af5ff') "aqua" }
]

{ #category : 'utilities' }
IcicleGraph >> ancestorOf: methodTrace among: ancestors [
	"Returns the ancestor of a method trace associated with its distance.
	There can be a distance of 0 when the trace is one of the ancestors.
	This happens when zooming on one of the root nodes."

	| ancestor distance |
	ancestor := methodTrace.
	distance := 0.
	[ ancestor isNil or: [ ancestors includes: ancestor ] ] whileFalse: [
		ancestor := ancestor parent parent. "message then parent method"
		distance := distance + 1 ].
	^ { ancestor. distance }
]

{ #category : 'building - graph' }
IcicleGraph >> buildHistoryHeader [
	"Build nodes to go to the previous and root views"

	rootHistory size = 1 ifTrue: [ "no root if it is also the previous"
		^ (self createHistoryNode: currentRoots first)
			  extent: graphWidth @ nodeHeight;
			  position: rootMorph position ].
	self
		distributeLength: graphWidth
		among: #( 1 2 )
		do: [ :index :x :width |
			index = 1
				ifTrue: [
					(self createHistoryNode: currentRoots first)
						extent: width @ nodeHeight;
						position: rootMorph position ]
				ifFalse: [
					(self createHomeNode: currentRoots first)
						extent: width @ nodeHeight;
						position: x + rootMorph position x @ rootMorph position y ] ]
]

{ #category : 'accessing' }
IcicleGraph >> colorPalette [

	^ colorPalette
]

{ #category : 'accessing' }
IcicleGraph >> colorPalette: colorCollection [

	colorPalette := colorCollection
]

{ #category : 'instance creation' }
IcicleGraph >> createDefaultNode [
	"Basic way all nodes are first created.
	Do not use TextMorph because:
	- its minimum extent can go against the graph layout
	- the cursor goes into text mode when hovering"

	^ NodeMorph new
]

{ #category : 'instance creation' }
IcicleGraph >> createHistoryNode: methodTrace [
	"Allows going back to the previous view, with an ancestor node as the root."

	| pair distance ancestor text morph |
	pair := self ancestorOf: methodTrace among: rootHistory top.
	ancestor := pair at: 1.
	distance := pair at: 2.

	text := String streamContents: [ :s |
		        s << ' [last] ' << ancestor node compiledMethod name << ' ('.
		        self print: distance pluralize: 'send' on: s.
		        s nextPut: $) ].

	morph := self createDefaultNode.
	morph backgroundColor: Color lightGray.
	morph privateSetContents: text.
	morph setBalloonText: 'Click to return to' , text.
	morph eventHandler: (MorphicEventHandler new
			 on: #mouseDown
			 send: #rebuildFromHistory
			 to: self).
	rootMorph addMorph: morph.
	^ morph
]

{ #category : 'instance creation' }
IcicleGraph >> createHomeNode: methodTrace [
	"Allows going back to the initial view, at the root node."

	| pair ancestor distance text morph |
	pair := self ancestorOf: methodTrace among: rootHistory last.
	ancestor := pair at: 1.
	distance := pair at: 2.

	text := String streamContents: [ :s |
		        s << ' [root] ' << ancestor node compiledMethod name << ' ('.
		        self print: rootHistory size pluralize: 'frame' on: s.
		        s nextPutAll: ', '.
		        self print: distance pluralize: 'send' on: s.
		        s nextPut: $) ].

	morph := self createDefaultNode.
	morph backgroundColor: Color veryLightGray.
	morph privateSetContents: text.
	morph setBalloonText: 'Click to return to' , text.
	morph eventHandler: (MorphicEventHandler new
			 on: #mouseDown
			 send: #rebuildFromRoot
			 to: self).
	rootMorph addMorph: morph.
	^ morph
]

{ #category : 'instance creation' }
IcicleGraph >> createMethodNode: methodTrace [
	"Allows going to a new view, with a successor node as the root."

	| morph |
	morph := self createDefaultNode.
	morph backgroundColor: self nextColor.
	morph privateSetContents:
		(methodTrace node selector copyWithFirst: Character space).

	(currentRoots size = 1 and: [ currentRoots includes: methodTrace ])
		ifTrue: [ "singular root nodes are not interactive"
			morph setBalloonText: methodTrace node compiledMethod name ]
		ifFalse: [
			morph setBalloonText: (String streamContents: [ :s |
					 s << 'Click to zoom into '
					 << methodTrace node compiledMethod name << ' ('.
					 self print: (self weightOf: methodTrace) pluralize: 'send' on: s.
					 s nextPut: $) ]) ].

	morph eventHandler: (MorphicEventHandler new
			 on: #mouseDown
			 send: #whenMethodClicked:event:morph:
			 to: self
			 withValue: methodTrace).

	rootMorph addMorph: morph.
	^ morph
]

{ #category : 'instance creation' }
IcicleGraph >> createZoomNode: methodTrace [
	"Means there are too many children to view correctly.
	Allows going to a new view, with the children nodes as the root."

	| text morph |
	text := String streamContents: [ :s |
		        self
			        print: (self weightOf: methodTrace) - 1
			        pluralize: 'send'
			        on: s ].

	morph := self createDefaultNode.
	morph privateSetContents: (text copyWithFirst: Character space).
	morph setBalloonText: (String streamContents: [ :s |
			 s << 'Click to view children of '
			 << methodTrace node compiledMethod name << ' (' << text << ')' ]).
	morph eventHandler:
		(MorphicEventHandler new on: #mouseDown send: #value to: [
			 rootHistory push: currentRoots.
			 self rebuildFromMethods: (methodTrace children
					  select: [ :m | m isMessage ]
					  thenCollect: [ :m | m children first ]) ]).
	rootMorph addMorph: morph.
	^ morph
]

{ #category : 'utilities' }
IcicleGraph >> distributeLength: totalLength among: children do: aBlock [
	"Morph works with ints but we can get floats.
	This would result in extra space between some nodes.
	Reclaim this space by converting it into node width."

	| n baseLength remainder offset |
	n := children size.
	remainder := totalLength \\ n. "Pixels to distribute"
	offset := 0.

	"Fast path: perfectly divisible"
	(n = 1 or: [ remainder = 0 ]) ifTrue: [
		baseLength := totalLength / n.
		children do: [ :child |
			aBlock value: child value: offset value: baseLength.
			offset := offset + baseLength ].
		^ self ].

	"Slow path: need to distribute remaining pixels"
	baseLength := totalLength // n.
	children withIndexDo: [ :child :i |
		| childLength |
		childLength := baseLength + (i <= remainder
			                ifTrue: [ 1 ]
			                ifFalse: [ 0 ]).
		aBlock value: child value: offset value: childLength.
		offset := offset + childLength ]
]

{ #category : 'utilities' }
IcicleGraph >> distributeLength: totalLength weightedAmong: children do: aBlock [
	"See comment of #distributeLength:among:do:
	This method does not distribute the length evenly, but weights it.
	The weight of a node corresponds to its total number of children.
	The size difference between nodes of min and max weight is configurable with weightFactor:"

	| n availableLength minWeight maxWeight normalizedWeights totalWeight intLengths remainder offset sortedIndexes |
	n := children size.
	n = 0 ifTrue: [ ^ self ].
	n = 1 ifTrue: [
		^ aBlock value: children first value: 0 value: totalLength ].
	availableLength := totalLength - (n - 1). "Gap between nodes"

	"Step 1: Collect weights and compute min/max"
	normalizedWeights := Array new: n.
	minWeight := maxWeight := self weightOf: children first.
	normalizedWeights at: 1 put: minWeight.
	2 to: n do: [ :i |
		| w |
		w := self weightOf: (children at: i).
		normalizedWeights at: i put: w.
		minWeight := minWeight min: w.
		maxWeight := maxWeight max: w ].

	"Step 2: Normalize weights to [min, weightFactor*min] and compute totalWeight"
	totalWeight := 0.0.
	1 to: n do: [ :i |
		| w ratio normalized |
		w := normalizedWeights at: i.
		ratio := w - minWeight / (maxWeight - minWeight max: 1e-6).
		normalized := minWeight
		              + (ratio * (minWeight * (self weightFactor - 1))).
		normalizedWeights at: i put: normalized.
		totalWeight := totalWeight + normalized ].

	"Step 3: Compute base int lengths and remainder"
	intLengths := Array new: n.
	remainder := availableLength.
	1 to: n do: [ :i |
		| exact truncated |
		exact := (normalizedWeights at: i) / totalWeight * availableLength.
		truncated := exact truncated.
		intLengths at: i put: truncated.
		remainder := remainder - truncated ].

	"Step 4: Sort indexes by normalized weight descending"
	sortedIndexes := (1 to: n) asArray sort: [ :i :j |
		                 (normalizedWeights at: i)
		                 >= (normalizedWeights at: j) ].

	"Step 5: Add 1 to first `remainder` lengths to reclaim pixels lost to rounding"
	1 to: remainder do: [ :r |
		| i |
		i := sortedIndexes at: r.
		intLengths at: i put: (intLengths at: i) + 1 ].

	"Step 6: Emit lengths in original order, with a gap between nodes"
	offset := 0.
	1 to: n do: [ :i |
		| length |
		length := intLengths at: i.
		aBlock value: (children at: i) value: offset value: length.
		offset := offset + length + (i < n
			           ifTrue: [ "gap" 1 ]
			           ifFalse: [ 0 ]) ]
]

{ #category : 'building - graph' }
IcicleGraph >> fromExecution: aScpExecutionRecordTree [

	^ self fromMethods: aScpExecutionRecordTree methods
]

{ #category : 'building - graph' }
IcicleGraph >> fromMethods: methodTraces [

	rootMorph := Morph new.
	rootMorph color: Color white.
	rootMorph extent: graphWidth @ graphHeight.

	self privateBuildFromMethods: methodTraces.

	^ rootMorph
]

{ #category : 'accessing' }
IcicleGraph >> graphHeight [

	^ graphHeight
]

{ #category : 'accessing' }
IcicleGraph >> graphHeight: anInteger [

	graphHeight := anInteger
]

{ #category : 'accessing' }
IcicleGraph >> graphWidth [

	^ graphWidth
]

{ #category : 'accessing' }
IcicleGraph >> graphWidth: anInteger [

	graphWidth := anInteger
]

{ #category : 'initialization' }
IcicleGraph >> initialize [

	colorIndex := 0.
	rootHistory := Stack new.
	weightCache := IdentityDictionary new.
	colorPalette := self class pastelColors
]

{ #category : 'measuring' }
IcicleGraph >> measure [
	"Compute how many node layers can fit and set node height"

	| depth maxDepth |
	nodesWithZoom := Dictionary new.
	depth := rootHistory isEmpty
		         ifTrue: [ 1 ]
		         ifFalse: [ 2 ].
	maxDepth := depth.

	self
		distributeLength: graphWidth
		weightedAmong: currentRoots
		do: [ :child :childX :childWidth |
			self
				measure: child
				atDepth: depth
				posX: childX
				width: childWidth
				updatingMaxDepth: [ :d | maxDepth := maxDepth max: d ] ].

	"`maxDepth` layers with `maxDepth-1` inter-node gaps"
	nodeHeight := graphHeight - (maxDepth - 1) // maxDepth.

	self measureZoomWeights
]

{ #category : 'measuring' }
IcicleGraph >> measure: methodTrace atDepth: depth posX: posX width: width updatingMaxDepth: maxDepthBlock [

	| children |
	children := methodTrace children
		            select: [ :m | m isMessage ]
		            thenCollect: [ :m | m children first ].
	children ifEmpty: [ "Leaf node" ^ maxDepthBlock value: depth ].

	width / children size < self minimumNodeWidth ifTrue: [ "
		Cannot distribute width without going below minimum.
		Zoom node goes one level deeper but doesn't recurse."
		nodesWithZoom at: methodTrace put: nil.
		^ maxDepthBlock value: depth + 1 ].

	self
		distributeLength: width
		weightedAmong: children
		do: [ :child :childX :childWidth |
			self
				measure: child
				atDepth: depth + 1
				posX: posX + childX
				width: childWidth
				updatingMaxDepth: maxDepthBlock ]
]

{ #category : 'measuring' }
IcicleGraph >> measureZoomWeights [

	| nodes minWeight maxWeight |
	nodesWithZoom ifEmpty: [ ^ self ].
	nodes := nodesWithZoom keys.

	"Compute min and max weights"
	minWeight := maxWeight := self weightOf: nodes first.
	2 to: nodes size do: [ :i |
		| w |
		w := self weightOf: (nodes at: i).
		minWeight := minWeight min: w.
		maxWeight := maxWeight max: w ].

	"Assign colors based on weights"
	nodes do: [ :node |
		| weight ratio grayLevel color |
		weight := self weightOf: node.
		ratio := weight - minWeight / (maxWeight - minWeight max: 1e-6). "avoid /0"
		grayLevel := 0.95 - (0.45 * ratio). "light gray (0.95) to darker (0.5)"
		grayLevel := grayLevel clampBetween: 0.2 and: 0.9.
		color := Color gray: grayLevel.

		nodesWithZoom at: node put: color ]
]

{ #category : 'accessing' }
IcicleGraph >> minimumNodeWidth [
	"Arbitrary default value that allows seeing at least one character"

	^ minimumNodeWidth ifNil: [ minimumNodeWidth := 10 ]
]

{ #category : 'accessing' }
IcicleGraph >> minimumNodeWidth: anInteger [

	minimumNodeWidth := anInteger
]

{ #category : 'utilities' }
IcicleGraph >> nextColor [

	colorIndex := colorIndex + 1.
	^ colorPalette at: colorIndex - 1 \\ colorPalette size + 1
]

{ #category : 'paint' }
IcicleGraph >> paintWith: colorCollection [

	self colorPalette: colorCollection.
	self repaint
]

{ #category : 'printing' }
IcicleGraph >> print: number pluralize: word on: stream [

	number printOn: stream.
	stream space nextPutAll: word.
	number = 1 ifFalse: [ stream nextPut: $s ]
]

{ #category : 'building - graph' }
IcicleGraph >> privateBuildFromMethods: methodTraces [

	currentRoots := methodTraces.
	self measure.
	rootHistory ifNotEmpty: [ self buildHistoryHeader ].

	self
		distributeLength: graphWidth
		weightedAmong: methodTraces
		do: [ :child :childX :childWidth |
			self
				visitMethodTrace: child
				atDepth: (rootHistory ifEmpty: [ 0 ] ifNotEmpty: [ 1 ])
				posX: childX
				width: childWidth ]
]

{ #category : 'building - graph' }
IcicleGraph >> rebuildFromHistory [

	self rebuildFromMethods: rootHistory pop
]

{ #category : 'building - graph' }
IcicleGraph >> rebuildFromMethods: methodTraces [

	colorIndex := 0.
	rootMorph submorphsDo: [ :m | m delete ].
	self privateBuildFromMethods: methodTraces
]

{ #category : 'building - graph' }
IcicleGraph >> rebuildFromRoot [

	| origin |
	origin := rootHistory last.
	rootHistory removeAll.
	self rebuildFromMethods: origin
]

{ #category : 'paint' }
IcicleGraph >> repaint [

	colorIndex := 0.
	rootMorph submorphsReverseDo: [ :morph | "iterate in original order"
		| firstChar |
		firstChar := morph contents at: 2.
		(firstChar == $[ or: [ firstChar isDigit ]) ifFalse: [ "only method nodes"
			morph backgroundColor: self nextColor ] ].
	rootMorph changed
]

{ #category : 'initialization' }
IcicleGraph >> reset [

	colorIndex := 0.
	nodesWithZoom := nil.
	rootHistory removeAll.
	weightCache := weightCache copyEmpty.
	nodesWithZoom := nil.
	rootMorph ifNotNil: [
		rootMorph delete.
		rootMorph := nil ]
]

{ #category : 'building - graph' }
IcicleGraph >> visitMethodTrace: methodTrace atDepth: depth posX: posX width: width [

	| posY node children |
	posY := depth * (nodeHeight + 1). "1 for inter-row spacing"
	(node := self createMethodNode: methodTrace)
		extent: width @ nodeHeight;
		position: rootMorph position + (posX @ posY).

	methodTrace parent ifNotNil: [ :send |
		methodTrace node selector = send node selector ifFalse: [ "
			Message sent is different from executed method!"
			node
				borderWidth: 1;
				borderColor: Color red ] ].

	nodesWithZoom at: methodTrace ifPresent: [ :color | "
		Cannot distribute width without going below minimum"
		^ (self createZoomNode: methodTrace)
			  backgroundColor: color;
			  extent: width @ nodeHeight;
			  position: rootMorph position + (posX @ (posY + nodeHeight + 1)) ].

	children := methodTrace children
		            select: [ :m | m isMessage ]
		            thenCollect: [ :m | m children first ].
	children ifEmpty: [ ^ self ].

	self
		distributeLength: width
		weightedAmong: children
		do: [ :child :childX :childWidth |
			self
				visitMethodTrace: child
				atDepth: depth + 1
				posX: posX + childX
				width: childWidth ]
]

{ #category : 'accessing' }
IcicleGraph >> weightFactor [
	"Factor for size between nodes of min and max weight.
	A factor of 2 means the max will be *two times* the size of the min."

	^ weightFactor ifNil: [ weightFactor := 8 ]
]

{ #category : 'accessing' }
IcicleGraph >> weightFactor: aNumber [

	weightFactor := aNumber
]

{ #category : 'utilities' }
IcicleGraph >> weightOf: methodTrace [
	"Node weight is its total number of children"

	^ (self weightOf: methodTrace cachingThreshold: CacheLocalThreshold)
		  at: 1
]

{ #category : 'utilities' }
IcicleGraph >> weightOf: methodTrace cachingThreshold: cachingThreshold [
	"Compute weight of descendant nodes with a caching threshold.
	There can easily be more than 1M nodes, caching needs to be efficient.
	The visit goes bottom-to-top and returns `{weight. weightSinceCache}`.
	Caching occurs when weightSinceCache goes above the threshold."

	| weight weightSinceCache |
	weightCache at: methodTrace ifPresent: [ :w | ^ { w. 0 } ].

	weight := 1.
	weightSinceCache := 1.
	methodTrace children do: [ :m |
		m isMessage ifTrue: [
			| weights |
			weights := self
				           weightOf: m children first
				           cachingThreshold: CacheGlobalThreshold.
			weight := weight + (weights at: 1).
			weightSinceCache := weightSinceCache + (weights at: 2) ] ].

	weightSinceCache >= cachingThreshold ifTrue: [
		weightCache at: methodTrace put: weight.
		^ { weight. 0 } ].
	^ { weight. weightSinceCache }
]

{ #category : 'event handling' }
IcicleGraph >> whenMethodClicked: methodTrace event: event morph: morph [
	"Handle the click event on a method node"

	event redButtonPressed ifTrue: [ "left click"
		(event commandKeyPressed or: [ event controlKeyPressed ]) ifTrue: [
			^ methodTrace node compiledMethod browse ].
		(event optionKeyPressed or: [ event altKeyPressed ]) ifTrue: [
			^ methodTrace inspect ].

		(currentRoots size = 1 and: [ currentRoots includes: methodTrace ])
			ifFalse: [ "singular root node cannot be zoomed into"
				rootHistory push: currentRoots.
				self rebuildFromMethods: { methodTrace } ].
		^ self ].

	event yellowButtonPressed ifTrue: [ "right click"
		SpMenuPresenter new
			addItem: [ :item |
				item
					name: 'Browse (Ctrl/Cmd+Click)';
					action: [ methodTrace node compiledMethod browse ] ];
			addItem: [ :item |
				item
					name: 'Inspect (Alt/Opt+Click)';
					action: [ methodTrace inspect ] ];
			openWithSpecAtPointer ]
]
