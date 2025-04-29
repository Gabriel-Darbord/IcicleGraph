# IcicleGraph

Interactive icicle graph to visualize execution traces from [Scopeo](https://github.com/Scopeo-Project).

## Installing

```st
Metacello new
  githubUser: 'Gabriel-Darbord' project: 'IcicleGraph' commitish: 'main' path: 'src';
  baseline: 'IcicleGraph';
  load
```

## Example

```st
"Obtain traces using Scopeo"
exec := ScpExecutionRecorder 
	recordBlock: [ Transcript open ]
	as: ScpExecutionRecordTree.

"Build and display the graph"
(IcicleGraphPresenter on: exec) open.
```
![graph](https://github.com/user-attachments/assets/d711d309-2932-46a9-9156-a55eaf2e72fa)
