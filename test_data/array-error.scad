union() {
sphere(d=30);
cube(size=[10,20,30]);
}

/*
This test should error - if Name is not a list, nothing else should be.
<json>
    {
        "Name": "Variable",
        "Desc": ["Desc 1"],
        "LowKeyword": ["Lost 1", "Lost 2"],
        "HighKeyword": ["Printed1", "Printed2", "Printed 3", "Printed 4"],
        "varBase": "VarBase1",
        "minDefault": 0.1,
        "maxDefault": [1, 2, 3],
        "minDefaultND": "0.5 * nozzleDiameter",
        "maxDefaultND": "5 * nozzleDiameter",
        "cameraData": "-2.28,2.59,6.06,59.9,0,13.8,113.4",
        "sortOrder": [3, 2, 1],
		"instanceCount": 10
    }
</json>
*/