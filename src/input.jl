
using LightXML
include("./download.jl")
# `
# TODO: change variable names like Array(which are most time Any's).
# `

wayArray = []
nodeArray = []
filteredWayArray = []
filteredNodeArray = []


# 
# This function returns the filteredWayArray (which is an Any).
# 
function getFilteredWayArray()
    return filteredWayArray
end


# 
# This function returns the filteredNodeArray (which is an Any).
# 
function getFilteredNodeArray()
    return filteredNodeArray
end


# 
# This function does a filtering of the given xroot and removes all members with a specific role (for example platform-data).
# To get the information which data are relevant, the function needs the relationID where the members are listet.
# 
function filterAllWaysByDataFromRelation(relationID::Union{String, Int},xroot)
    ID=""
    if(typeof(relationID)==Int)
        ID=string(relationID)
    else
        ID=relationID
    end
    xmlRelations=get_elements_by_tagname(xroot, "relation")
    for relation in xmlRelations
        if(attribute(relation,"id")==ID)
            childnodesOfRelation = collect(child_nodes(relation))
            for elements in childnodesOfRelation
                if is_elementnode(elements)
                    if name(elements) == "member"
                        g = XMLElement(elements)
                        if(attribute(g,"role")=="")
                            addToFilteredWayArray(getWayByID(attribute(g,"ref")))
                        end
                    end
                end
            end
        end
    end
end


# 
# This function checks the data-type of the given wayID and afterwards calls the addToFilteredWayArray-function with the ID.
# 
function filterWayToFilteredWayArray(wayID::Union{String, Int})
    ID=""
    if(typeof(wayID)==Int)
        ID=string(wayID)
    else
        ID=wayID
    end
    addToFilteredWayArray(getWayByID(ID))
end


# 
# This function adds all nodes of all ways to the filteredNodeArray by calling the addToFilteredNodeArray-funtion.
# 
function filterAllNodesByDataFromFilteredWayArray(filteredWayArray::Any)
    for way in filteredWayArray
        nodes = way.containedNodeIDs
        for node in nodes
            addToFilteredNodeArray(node)
        end
    end
end


# 
# This function checks if a way is already saved in the filteredWayArray and returns the result with a Bool.
# 
function checkIfAllreadyInFilteredWayArray(newway::NamedTuple)
    for way in filteredWayArray
        if(way==newway)
            return true
        end
    end
    return false
end


# 
# This function checks if a node is already saved in the filteredNodeArray and returns the result with a Bool.
# 
function checkIfAllreadyInFilteredNodeArray(newnode::NamedTuple)
    for node in filteredNodeArray
        if(node==newnode)
            return true
        end
    end
    return false
end


# 
# This function adds a node to the filteredNodeArray if it's not already saved there.
# 
function addToFilteredNodeArray(node::NamedTuple)
    if(!checkIfAllreadyInFilteredNodeArray(node))
        push!(filteredNodeArray,node)
    end
end


# 
# This function adds a way to the filteredWayArray if it's not already saved there.
# 
function addToFilteredWayArray(way::NamedTuple)
    if(!checkIfAllreadyInFilteredWayArray(way))
        push!(filteredWayArray,way)
    end
end


# 
# This function returns a node-NamedTuple. Therefore the node-ID is required.
# 
function getNodeByID(nodeID::Union{Int,String})
    if(typeof(nodeID)==Int)
        for node in nodeArray
            if(node.nodeID==string(nodeID))
                return node
            end
        end
    else
        for node in nodeArray
            if(node.nodeID==nodeID)
                return node
            end
        end
    end
    @debug "missed Node called. NodeID that is missed is: $nodeID"
end


# 
# This function returns a way-NamedTuple from the wayArray by the wayID.
# 
function getWayByID(wayID::Union{Int,String})
    if(typeof(wayID)==Int)
        for way in wayArray
            if(way.wayID==string(wayID))
                return way
            end
        end
    else
        for way in wayArray
            if(way.wayID==wayID)
                return way
            end
        end
    end
    @debug "missed Way called. WayID that is missed is: $wayID"
end


# 
# This function returns a way in the filteredWayArray by the wayID.
# 
function getWayFromFilteredWayArrayByID(wayID::Union{Int,String})
    if(typeof(wayID)==Int)
        for way in filteredWayArray
            if(way.wayID==string(wayID))
                return way
            end
        end
    else
        for way in filteredWayArray
            if(way.wayID==wayID)
                return way
            end
        end
    end
    @debug "missed Way called. WayID that is missed is: $wayID"
end


# 
# The createNodes-function transfers the data from a given XMLElement to a NamedTuple and pushs this NamedTuple to the filteredNodeArray.
# In the transfer of the data the node-ID, the lat and lon coordinates and additional Bools for signal and switch information are stored in the NamedTuple.
# 
function createNodes(xroot::XMLElement)
    xmlNodes = get_elements_by_tagname(xroot, "node")
    for node in xmlNodes
        issignal = false
        isswitch = false
        if(has_children(node))
            element = child_nodes(node)
            for c in element
                if(is_elementnode(c))
                    e= XMLElement(c)
                    if(attribute(e,"k")=="railway" && attribute(e,"v")=="signal")
                        issignal=true
                    end
                    if(attribute(e,"k")=="railway:switch"||(attribute(e,"k")=="railway"&&attribute(e,"v")=="switch"))
                        isswitch=true
                    end
                end
            end
        end
        nd = (nodeID = attribute(node,"id"), lat=parse(Float64,attribute(node,"lat")), lon=parse(Float64,attribute(node,"lon")), issignal=issignal, isswitch=isswitch)
        push!(nodeArray,nd)
    end
end


# 
# The createWay-function transfers the data from a given XMLElement to a NamedTuple and pushs this NamedTuple to the filteredWayArray
# In the transfer of the data the way-ID, the containened Nodes (NamedTuples of the nodes), the maxspeed (NamedTuples because of direction-dependent maxspeeds) and the inclines (NamedTuples because of direction-dependent inclines) are stored in the NamedTuple.
# 
function createWays(xroot::XMLElement)
    xmlWays = get_elements_by_tagname(xroot, "way")
    for way in xmlWays
        w = (wayID = attribute(way,"id"), containedNodeIDs = getWayNodeIDs(way),vmax=getWayMaxspeed(way),incline=getWayIncline(way))
        push!(wayArray,w)
    end
end


# 
# This function returns a NamedTuple with the direction-dependent inclines of a given way-XMLElement.
# The values in the OSM are percent while in german train-tracks the unit perthousand is common.
# To avoid an unit-change-mistake, the units are converted in this function.
# 
function getWayIncline(xWay::XMLElement)
    elements = child_nodes(xWay.node)
    incline = 0.0
    for e in elements 
        if(is_elementnode(e))
            x = XMLElement(e)
            if(attribute(x,"k")=="incline")
                value = attribute(x,"v")
                if(value=="down"||value=="up")
                else incline = parse(Float64,replace(attribute(x,"v"),"%"=>""))
                end
            end
        end
    end
    return (forward=incline*10,backward=incline*(-10))                              # *10 necessary for change from % to per thousand -> (typically used for german-rail-incline)
end


# 
# The getWayMaxspeed-function returns a NamedTuple with the OSM-maxspeed-data in which the maxspeed is listet with the direction for which the value is valid.
# If the OSM-data specify a direction with :forward and :backward, this will be safed in the NamedTuple.
# If there is no specification of the direction, both will be saved with the maxspeed-value.
# If there is no maxspeed in one or both directions, the value(s) will be saved with "UNKNOWN".
# 
function getWayMaxspeed(xWay::XMLElement)
    element = child_nodes(xWay.node)
    maxspeedforward = "UNKNOWN"
    maxspeedbackward = "UNKNOWN"
    for c in element
        if(is_elementnode(c))
            e = XMLElement(c)
            if(attribute(e,"k")=="maxspeed")
                return maxspeed = (forward = attribute(e,"v"), backward = attribute(e,"v"))
            elseif (attribute(e,"k")=="maxspeed:forward")
                maxspeedforward = attribute(e,"v")
            elseif (attribute(e,"k")=="maxspeed:backward")
                maxspeedbackward = attribute(e,"v")
            end
        end
    end
    if(maxspeedforward=="UNKNOWN"&&maxspeedbackward=="UNKNOWN")
        return maxspeed=(forward = "UNKNOWN", backward = "UNKNOWN")
    else return maxspeed = (forward = maxspeedforward, backward = maxspeedbackward)
    end
end


# 
# This function returns an Any which contains the NamedTuples of the Nodes from the given way-XMLElement.
# To get the Nodes for the Any, the getNodeByID-funtion is used.
# 
function getWayNodeIDs(xWay::XMLElement)
    nodeIDs = []
    element = child_nodes(xWay.node)
    for c in element
        if(is_elementnode(c))
            e = XMLElement(c)
            if(name(e)=="nd")
                #push!(nodeIDs,(attribute(e,"ref")))
                #or entweder nur die Nummer oder den ganzen Knoten
                push!(nodeIDs,getNodeByID(attribute(e,"ref")))
            end
        end
    end
    # println(attribute(xWay, "id")," = ", length(nodeIDs))
    return nodeIDs
end


# 
# This function is used to add an OSM-Relation to the prototype memory.
# In contrast to the "addRelation"-funtion, this function reads the data from a given XML/OSM-file. 
# Therefore the filepath and the OSM-Relation-ID is required.
# With these data the function calls the createWays/createNodes-functions and filters the NamedTuples with the filter***-functions.
# 
function addRelationFromFile(id::Int,filepath::String)
    xdoc = parse_file(filepath)
    xroot = root(xdoc)
    createNodes(xroot)
    createWays(xroot)
    println(length(nodeArray)," Nodes in nodeArray")
    println(length(wayArray)," Ways in wayArray")
    filterAllWaysByDataFromRelation(id,xroot)
    filterAllNodesByDataFromFilteredWayArray(filteredWayArray)
    println(length(filteredWayArray)," Ways in filteredWayArray")
    println(length(filteredNodeArray)," Nodes in filteredNodeArray")
end


# 
# This function is used to add an OSM-Way to the prototype memory.
# In contrast to the "addWay"-funtion this function reads the data from a given XML/OSM-file. 
# Therefore the filepath and the OSM-Way-ID is required.
# With these data the function calls the createWays/createNodes-functions and filters the NamedTuples with the filter***-functions.
# 
function addWayFromFile(id::Int,filepath::String)
    xdoc = parse_file(filepath) 
    xroot = root(xdoc)
    createNodes(xroot)
    createWays(xroot)
    println(length(nodeArray)," Nodes in nodeArray")
    println(length(wayArray)," Ways in wayArray")
    filterWayToFilteredWayArray(id)
    filterAllNodesByDataFromFilteredWayArray(filteredWayArray)
    println(length(filteredWayArray)," Ways in filteredWayArray")
    println(length(filteredNodeArray)," Nodes in filteredNodeArray")  
end


# 
# This function is used to add an OSM-Relation to the prototype memory.
# It calls the Overpass-API via the download-class. Therefore the OSM-Relation-ID is required.
# After the download the function reads the Buffer.osm-file with the data and imports them.
# With these data the function calls the createWays/createNodes-functions and filters the NamedTuples with the filter***-functions.
# 
function addRelation(id::Int)
    getOSMRelationXML(id)
    xdoc = parse_file("./Buffer.osm")
    xroot = root(xdoc)
    createNodes(xroot)
    createWays(xroot)
    println(length(nodeArray)," Nodes in nodeArray")
    println(length(wayArray)," Ways in wayArray")
    filterAllWaysByDataFromRelation(id,xroot)
    filterAllNodesByDataFromFilteredWayArray(filteredWayArray)
    println(length(filteredWayArray)," Ways in filteredWayArray")
    println(length(filteredNodeArray)," Nodes in filteredNodeArray")
end


# 
# This function is used to add an OSM-Way to the prototype memory.
# It calls the Overpass-API via the download-class. Therefore the OSM-Way-ID is required.
# After the download the function reads the Buffer.osm-file with the data and imports them.
# With these data the function calls the createWays/createNodes-functions and filters the NamedTuples with the filter***-functions.
# 
function addWay(id::Int)
    getOSMWayXML(id)
    xdoc = parse_file("./Buffer.osm") 
    xroot = root(xdoc)
    createNodes(xroot)
    createWays(xroot)
    println(length(nodeArray)," Nodes in nodeArray")
    println(length(wayArray)," Ways in wayArray")
    filterWayToFilteredWayArray(id)
    filterAllNodesByDataFromFilteredWayArray(filteredWayArray)
    println(length(filteredWayArray)," Ways in filteredWayArray")
    println(length(filteredNodeArray)," Nodes in filteredNodeArray")  
end


# 
# This function is used to clear all collected data in any Arrays.
# 
function clearAllArrays()
    empty!(wayArray)
    empty!(nodeArray)
    empty!(filteredWayArray)
    empty!(filteredNodeArray)
end


# 
# This function prints the ways without maxspeed-information.
# 
function checkWaySpeed()
    waysWithoutSpeed=[]
    for way in filteredWayArray
        if(way.vmax.forward==""||way.vmax.backward=="")
            push!(waysWithoutSpeed,way)
        end
    end
    println("The following ways have none or one-directional only maxpeed")
    for way in waysWithoutSpeed
        println(way.wayID," maxspeed forward = ", way.vmax.forward, ", maxspeed backward = ",way.vmax.backward)
    end
end


# 
# This function can set the speed of a way. Therefore maxspeed-information for both direction and the OSM-ID of the Way is required.
# 
function setWaySpeed(wayID::Union{Int,String}, maxspeedforward::Int, maxspeedbackward::Int)
    w = getWayFromFilteredWayArrayByID(wayID)
    newW = (wayID = w.wayID, containedNodeIDs = w.containedNodeIDs,vmax=(forward = string(maxspeedforward), backward = string(maxspeedbackward)))
    replace!(filteredWayArray,w=>newW)
end


# 
# This function can remove a way from the data. Therefore the OSM-ID of the Way is required.
# 
function removeWay(id::Int)
    println(indexin(getWayByID(id),filteredWayArray))
    println("removed the way")
end
