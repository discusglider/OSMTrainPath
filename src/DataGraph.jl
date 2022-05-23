using Graphs, MetaGraphs, GraphPlot, Plots, GraphRecipes, Fontconfig, Cairo, Compose

include("./input.jl")
include("./output.jl")

nodeDict = Dict()
g = Graphs.SimpleDiGraph(1)
mdg = MetaDiGraph(g)
nodeXPositions = Float64[]
nodeYPositions = Float64[]
vecXCoordinates, vecYCoordinates = spring_layout(mdg)   # This set the layout for the Graph-Packge, witch is used for plotting
nodeColorArray = []
nodeLabelArray = []


# 
# The createGraph-function set a all data from the input-class in a MetaDiGraph.
# Therefore are some nested functions implemented.
# 
# addDataToDiGraph creates the vertices and the edges in the MetaDiGraph. The data from the NamedTuples will be stored in these graph-objects.
# 
# getNodeColorIndex returns an index-number which will be used later to color the nodes.
# 
# getCartesianX and getCartesianY are used to transfer the lat&lon-coordinates in cartesian coordinates which are used for a plot of the graph (function->plotGraph()).
#
function createGraph()
    g = Graphs.SimpleDiGraph(length(getFilteredNodeArray()))
    global mdg=MetaDiGraph(g)

    function addDatasToDiGraph(filteredNodeArray::Vector{Any},filteredWayArray::Vector{Any})
        lonCorrection=0
        for node in filteredNodeArray
            lonCorrection=lonCorrection+node.lon
        end
        lonCorrection=lonCorrection/length(filteredNodeArray)
        for node in filteredNodeArray
            push!(nodeDict,node.nodeID=>(length(nodeDict)+1))
            set_prop!(mdg,get(nodeDict,node.nodeID,"default value"),:id, node.nodeID)
            push!(nodeColorArray,getNodeColorIndex(node.issignal,node.isswitch))
            append!(nodeXPositions,getCartesianX(node.lon-lonCorrection,node.lat))
            append!(nodeYPositions,getCartesianY(node.lon-lonCorrection,node.lat))
            push!(nodeLabelArray,node.nodeID)       
        end

        for way in filteredWayArray
            bufferNode = first(way.containedNodeIDs)
            for node in way.containedNodeIDs
                if(node == first(way.containedNodeIDs))
                else
                    Graphs.add_edge!(mdg,get(nodeDict,bufferNode.nodeID,"default value"),get(nodeDict,node.nodeID,"default value"))
                    set_prop!(mdg,Graphs.Edge(get(nodeDict,bufferNode.nodeID,"default value"),get(nodeDict,node.nodeID,"default value")), :maxspeed,way.vmax.forward)
                    set_prop!(mdg,Graphs.Edge(get(nodeDict,bufferNode.nodeID,"default value"),get(nodeDict,node.nodeID,"default value")), :wayID, way.wayID)
                    set_prop!(mdg,Graphs.Edge(get(nodeDict,bufferNode.nodeID,"default value"),get(nodeDict,node.nodeID,"default value")), :length, getEdgelength(node.lat,node.lon,bufferNode.lat,bufferNode.lon))
                    set_prop!(mdg,Graphs.Edge(get(nodeDict,bufferNode.nodeID,"default value"),get(nodeDict,node.nodeID,"default value")), :incline, way.incline.forward)
                    
                    Graphs.add_edge!(mdg,get(nodeDict,node.nodeID,"default value"),get(nodeDict,bufferNode.nodeID,"default value"))
                    set_prop!(mdg,Graphs.Edge(get(nodeDict,node.nodeID,"default value"),get(nodeDict,bufferNode.nodeID,"default value")), :maxspeed,way.vmax.backward)
                    set_prop!(mdg,Graphs.Edge(get(nodeDict,node.nodeID,"default value"),get(nodeDict,bufferNode.nodeID,"default value")), :wayID, way.wayID)
                    set_prop!(mdg,Graphs.Edge(get(nodeDict,node.nodeID,"default value"),get(nodeDict,bufferNode.nodeID,"default value")), :length, getEdgelength(node.lat,node.lon,bufferNode.lat,bufferNode.lon))
                    set_prop!(mdg,Graphs.Edge(get(nodeDict,node.nodeID,"default value"),get(nodeDict,bufferNode.nodeID,"default value")), :incline, way.incline.backward)
                    bufferNode = node
                end
            end
        end
    end

    function getNodeColorIndex(issignal::Bool,isswitch::Bool)
        if(issignal==false&&isswitch==false)
            return 1
        elseif(issignal==true&&isswitch==false)
            return 2
        elseif(issignal==false&&isswitch==true)
            return 3
        else error("signal and switch in one node")
        end
    end

    function getCartesianY(lon::Float64,lat::Float64)
        return cos(deg2rad(lon))*cos(deg2rad(lat))*6371000
    end

    function getCartesianX(lon::Float64,lat::Float64)
        return cos(deg2rad(lat))*sin(deg2rad(lon))*6371000
    end
    addDatasToDiGraph(getFilteredNodeArray(),getFilteredWayArray())
    println("Graph created")
end


# 
# The plotGraph-function is used by the user to plot the Graph in it's current data status.
# Therefore the allready filled Arrays with the Node-Coordinates will be converted to vectors (necessary for GraphPlot-Package).
# Afterwards the function starts to find the horizontal an vertical size for the plot to distort it to an satellite-like view.
# Then the function fills the wayLabelArray and the wayColorArray to set them in the graph. The data for the Nodes are allready setted in the nodeColorArray and the nodeLabelArray.
# Finaly the function starts the gplot-function from the GraphPlot-Package.
# You can change all plot-settings in the gplot-function as it's descripted in the GraphPlot-Package: https://github.com/JuliaGraphs/GraphPlot.jl  
# 
function plotGraph()
    println("start building vectors")
    vecXCoordinates = vec(nodeXPositions)
    vecYCoordinates = vec(nodeYPositions)
    horizontal = (maximum(vecXCoordinates)-minimum(vecXCoordinates))
    vertical = (maximum(vecYCoordinates)-minimum(vecYCoordinates))
    wayLabelArray = []
    wayColorArray = []
    graphEdges = collect(Graphs.edges(mdg))
    # println(Graphs.ne(mdg))                                                   # print's the actuell numbers of edges in the Graph
    for graphEdge in graphEdges
        push!(wayLabelArray,string(get_prop(mdg,graphEdge,:length))*" m, Way-ID="*string(get_prop(mdg,graphEdge,:wayID))*", maxspeed="*string(get_prop(mdg,graphEdge,:maxspeed))*", incline="*string(round(get_prop(mdg,graphEdge,:incline),digits=4)))
        push!(wayColorArray, getEdgeColorIndex(get_prop(mdg,graphEdge,:maxspeed)))
    end
    nodeColor = [colorant"blue",colorant"red",colorant"orange"]
    nodefillc = nodeColor[nodeColorArray]
    edgestrokec = wayColorArray
    println("start plotting")
    draw(PDF("DataGraph-Plot.pdf",horizontal, vertical), gplot(mdg, vecXCoordinates, vecYCoordinates,nodelabel=nodeLabelArray, edgelabel=wayLabelArray, edgestrokec = edgestrokec, EDGELINEWIDTH = 1.0 / sqrt(Graphs.nv(g)),nodefillc = nodefillc ,arrowlengthfrac=0.0006 / sqrt(Graphs.nv(g)),NODESIZE = 0.0002 / sqrt(Graphs.nv(g))))
    # draw(PDF("DataGraph-Plot.pdf"), gplot(mdg, vecXCoordinates, vecYCoordinates,nodelabel=nodeLabelArray, edgelabel=wayLabelArray, edgestrokec = edgestrokec, EDGELINEWIDTH = 1.0 / sqrt(Graphs.nv(g)),nodefillc = nodefillc ,arrowlengthfrac=0.0006 / sqrt(Graphs.nv(g)),NODESIZE = 0.0002 / sqrt(Graphs.nv(g))))
    # draw(PDF("PlotSaveTestBS-UELZEN.pdf",horizontal, vertical), gplot(mdg, vecXN, vecYN, edgelabel=waylabel, edgestrokec = edgestrokec, EDGELINEWIDTH = 2.5 / sqrt(Graphs.nv(g)),nodefillc = nodefillc ,arrowlengthfrac=0.01 / sqrt(Graphs.nv(g)),NODESIZE = 0.005 / sqrt(Graphs.nv(g))))
    println("Plot finished. Saved to DataGraph-Plot.pdf")
end


# 
# The getYAMLExportArray-function is normaly used by the exportPathToYAML-function.
# It first finds a route and saves the points of the route in "pointsOfRoute".
# After that, the exportDataArray will be filled with the parameters for TrainRun.
# For the return this exportDataArray will be converted to a vector.
# 
function getYAMLExportArray(startpoint::Int,destinationpoint::Int)
    exportDataArray=[]
    sumlength=0
    pointsOfRoute = Graphs.enumerate_paths(Graphs.dijkstra_shortest_paths(mdg,get(nodeDict,string(startpoint),"default value")),get(nodeDict,string(destinationpoint),"default value"))
    bufferNode = first(pointsOfRoute)
    for node in pointsOfRoute
        if(node==first(pointsOfRoute))
        else
        push!(exportDataArray,[round(get_prop(mdg,Graphs.Edge(bufferNode,node), :length)+sumlength,digits=2),parse(Int,get_prop(mdg,Graphs.Edge(bufferNode,node), :maxspeed)),round(get_prop(mdg,Graphs.Edge(bufferNode,node),:incline),digits=4)])
        sumlength=sumlength+get_prop(mdg,Graphs.Edge(bufferNode,node), :length)
        bufferNode=node
        end
    end
    dataVector=vec(exportDataArray)
    println("export-vector created")
    return dataVector
end


#
# The exportPathToYAML-function calls an other function from the "output.jl"-class. Therefore it needs a description (saved in the yaml-file), a filename and the startpoint and the destinationpoint of the route.
# It doesn't matter if you've allready filtered the Path onedirectional or not.
# Note that it's possible to export only a part of the path of the plot.
#
function exportPathToYAML(description::String, filename::String, startpoint::Int,destinationpoint::Int)
    createYAML(description, filename, getYAMLExportArray(startpoint,destinationpoint))
end


# 
# The getEdgelength-function returns the length between two coordinate-positions.
# The length is calculated by a formula for spherical geometry, cause the standard coordinates (latitude & longitude) are for a globe and not a typical x-y-chart (cartesian).
# It returns a value in meter rounded to two  positions after decimal point (cm).
# 
function getEdgelength(lat1,lon1,lat2,lon2)
    c=acos(sin(lat1*pi/180)*sin(lat2*pi/180)+cos(lat1*pi/180)*cos(lat2*pi/180)*cos(lon1*pi/180-lon2*pi/180))
    length = round(c*6371000,digits=2)
    if(length==0.00)
        return 0.01                 #This is necessary because TrainRun is unable to work with an edgelength below 0.01m
    else return length
    end
end


# 
# The getEdgeColorIndex-function returns a color for a given String. It's normaly used by the plotGraph()-function.
# 
function getEdgeColorIndex(maxspeed::String)
    if(maxspeed=="UNKNOWN")
        return colorant"orange"
    elseif(maxspeed!="UNKNOWN")
        return colorant"green"
    end
end


#
# filterOnedirectional needs a startpoint and an endpoint to remove all unused edges.
# CAUTION!: This function is seraching for the shortest path in the graph. 
#   If there are multiple possiblitys to connect startpoint and endpoint, this function may not find the astimated path.
#   Prepare the Graph with the "removeWayFromGraph()"-function so there is only one possible path in the graph.
#
function filterOnedirectional(startpoint::Int,destinationpoint::Int)
    pointsOfRoute = Graphs.enumerate_paths(Graphs.dijkstra_shortest_paths(mdg,get(nodeDict,string(destinationpoint),"default value")),get(nodeDict,string(startpoint),"default value"))
    remainingEdges = []
    bufferNode = first(pointsOfRoute)
    for node in pointsOfRoute
        if(node==first(pointsOfRoute))
        else
        push!(remainingEdges,Graphs.Edge(node,bufferNode))
        bufferNode=node
        end
    end

    for edge in collect(MetaGraphs.edges(mdg))
        if(in(edge,remainingEdges))          
        else MetaGraphs.rem_edge!(mdg,edge)
        end
    end  
    println("path filtered between "*string(startpoint)*" and "*string(destinationpoint))
end


#
# The changeWaySpeed-function changes the speed of a way. It doesn't matter what the previous value was. 
# NOTE!: If you haven't allready filtered the path onedirectional, you change the speed for both directions.
# It ist highly recommended to filter onedirectional bevore using this function.
# To filter onedirectional you can use the filterOnedirectional-function.
# 
function changeWaySpeed(wayID::Int,newSpeed::Int)
    for edge in MetaGraphs.edges(mdg)
        if(get_prop(mdg,edge, :wayID)==string(wayID))
            set_prop!(mdg,edge, :maxspeed, string(newSpeed))
        end
    end
    println("set new Wayspeed "*string(newSpeed)*" for Way "*string(wayID))
end


#
# The removeWayFromGraph-function removes a given way from the graph, if the given way (found by it's OSM-ID) is in the graph.
#
function removeWayFromGraph(wayID::Int)
    for edge in collect(MetaGraphs.edges(mdg))
        if(get_prop(mdg,edge, :wayID)==string(wayID))
            clear_props!(mdg,edge)
            Graphs.rem_edge!(mdg,edge)
        end
    end
    println("Way "*string(wayID)*" was removed from the Graph")
end
