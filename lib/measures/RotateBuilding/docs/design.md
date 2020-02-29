## Rotate Building Relative to Current Orientation

### Description

Rotate your building relative to its current orientation. This will not rotate site shading objects.

### Modeler Description

Get the North Axis field for the  OS:Building object and adjusted it based on the user specified value. If the starting value is 20 degrees and the user value is 5 degrees, then the resulting value is 25 degrees.

### Use Case Types

New, Calibration

### Arguments

Number of degrees to rotate building - positive is clockwise (Double) 90

### Initial Condition

Report the initial building rotation.

### Final Condition

Report the final building rotation.

### Not Applicable

If user value is 0 then the model will not be changed.

### Information

Show how many degrees the building was rotated.

### Warning

If user entered a number greater 360 or less than -360 then let them know what the actual angle was.
Alert user if there are site shading objects. They will not be rotated.

### Error

na

### Code Outline

- Add arguments
- Issue warning if necessary
- Report initial condition
- Determine desired building rotation
- Rotate building
- Info if site shading objects found
- Report final condition

## COST CONSIDERATIONS

This measure will have no impact on capital costs.