
using LightOSM, HTTP, LightXML


#
# This function was created in the LightOSM-Package and is under the Copyright of this Package -> https://github.com/DeloitteDigitalAPAC/LightOSM.jl
# For the usage in this prototype the original LightOSM-function was addapted.
# The function checks if the overpass-server are available. 
# Adaption of the original function: a print-information was removed.
#
function overpass_request(data::String)::String                 
    LightOSM.check_overpass_server_availability()
    return String(HTTP.post("http://overpass-api.de/api/interpreter",body=data).body)
end


#
# This function was created in the LightOSM-Package and is under the Copyright of this Package -> https://github.com/DeloitteDigitalAPAC/LightOSM.jl
# For the usage in this prototype the original LightOSM-function was addapted.
# It calls the overpass_request-function with the given string and a filepath for the datafile, which is also created with this function.
# The filetype is allways setted to "osm". 
# Adaption of the original function: some given parameters were removed, additionally there usage in the function.
#
function download_osm_network(save_to_file_location,datas)::Union{XMLDocument,Dict{String,Any}}  
    data = overpass_request(datas)
    #@info "Downloaded osm network data from $(["$k: $v" for (k, v) in download_kwargs]) in $download_format format"

        if !(save_to_file_location isa Nothing)
        save_to_file_location = LightOSM.validate_save_location(save_to_file_location, "osm")
        write(save_to_file_location, data)
        @info "Saved osm network data to disk: $save_to_file_location"
        end

    deserializer = LightOSM.string_deserializer(:osm)
    return deserializer(data)
end


#
# This funtion is used to call the download_osm_network-function with a specific download-query-String, which is created by this function with the given OSM-ID.
#
function getOSMRelationXML(relationID::Int) 
    return download_osm_network("./Buffer.osm","[out:xml][timeout:25];relation("*string(relationID)*");(._;>>;);out;")
end


#
# This funtion is used to call the download_osm_network-function with a specific download-query-String, which is created by this function with the given OSM-ID.
#
function getOSMWayXML(wayID::Int)
    return download_osm_network("./Buffer.osm","[out:xml][timeout:25];way("*string(wayID)*");(._;>>;);out;")
end

