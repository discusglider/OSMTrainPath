
WARNING: This is a prototype which is still under development.

TODO: See source

# Required packages

    - LightOSM.jl
    - LightXML.jl
    - Graphs.jl
    - Cairo.jl
    - MetaGraphs.jl
    - HTTP.jl
    - Plots.jl
    - GraphPlot.jl
    - GraphRecipes.jl
    - Fontconfiq.jl
    - Compose.jl
    - YAML.jl

# Usage and Contributing

    If there is an urgent usecase, here is a very short instruction:
    Start the OSMTrainPath or DataGraph-class.
    1.) Use the "addRelation(id)"/"addWay(id)"-function to download data from overpass.
    2.) After you completed all downloads call the "createGraph()"-function.
    3.) To see the data call "plotGraph()" and search for the "Buffer.pdf"-file in which the plot will be saved.
    4.) Use "filterOnedirectional(startpoint-id, destinationpoint-id)"-function to get one specific directed graph.
    5.) Plot again to see the filtered path.
    6.) If there are maxspeeds "UNKNOWN" you must correct them with the "changeWaySpeed(way-id, newspeed)"-function.
    7.) If there are more possible ways than one for your whished export, you must remove one way so there is no other possible way.
        Therefore use the "removeWay(way-id)"-function.
    8.) After you completed all maxspeeds and only one possibly way, you can export data to a YAML-file.
        Therefore use the exportPathToYAML(description, filename, startpoint-id, destinationpoint-id).
        Note that you have to name the filename like *name*.yaml.

# License 

    ISC-License
    Copyright 2022 Falk Centner