Class {
	#name : 'NodeMorph',
	#superclass : 'StringMorph',
	#category : 'IcicleGraph',
	#package : 'IcicleGraph'
}

{ #category : 'drawing' }
NodeMorph >> drawOn: aCanvas [
	"Also draw the border!"

	aCanvas

		fillRectangle: self bounds
		fillStyle: self backgroundColor
		borderStyle: self borderStyle;

		drawString: self contents
		in: self stringBounds
		font: self fontToUse
		color: self stringColor
		underline: (emphasis bitAnd: 2r100) ~~ 0
		underlineColor: self underlineColor
		strikethrough: (emphasis bitAnd: 2r10000) ~~ 0
		strikethroughColor: self strikethroughColor
]
