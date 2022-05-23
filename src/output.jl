using YAML
# 
# The createYAML-function produce the YAML-output-file of this prototype.
# The file is named with the given filename which has to be in a "*name*.yaml" style (so with the .yaml).
# A given description is needed and will be setted in the file.
#
# In this version there is no information of the data-source in the file. 
#     TODO: add data-source information (OpenStreetMap).
# 
function createYAML(description::String, filename::String, datas::Any)
    dataVector=datas
    d=Dict()
    d2=Dict(:name => description,  :sectionStarts => nothing, :sectionStarts_kmh => dataVector)
    push!(d,:path => d2)
    YAML.write_file(filename, d)
end


