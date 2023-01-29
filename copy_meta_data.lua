--[[----------------------------------------------------------------------------------------------------------

Jpeg2RawMetaCopy Lightoom Classic Plugin

Copyright 2023 by Frank Eberle (https://www.frank-eberle.de)

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions
  and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

------------------------------------------------------------------------------------------------------------]]

local LrDialogs = import 'LrDialogs'
local LrApplication = import 'LrApplication'
local LrLogger = import 'LrLogger'
local LrTasks = import 'LrTasks'
local LrPathUtils = import "LrPathUtils"
local LrFileUtils = import "LrFileUtils"
local LrProgressScope = import "LrProgressScope"
local LrFunctionContext = import "LrFunctionContext"
local LrView = import "LrView"
local LrBinding = import "LrBinding"


local logger = LrLogger(_PLUGIN.id)
logger:enable('logfile')


local function firstUpper(str)
    return (str:gsub("^%l", string.upper))
end


local function mergeTables(t1, t2)
    local target = {}
    for _, v in ipairs(t1) do
        target[#target+1] = v
    end
    for _, v in ipairs(t2) do
        target[#target+1] = v
    end
    return target
end


local function doCopy(funcArgs)
    local protocol = ""
    local processed = 0
    local matched = 0
    local copyStarRating = funcArgs.copyStarRating
    local copyColorLabel = funcArgs.copyColorLabel
    local dryRun = funcArgs.dryRun
    local catalog = LrApplication.activeCatalog()
    local photos = catalog:getTargetPhotos()
    catalog:withWriteAccessDo("copyMeta", function()
        for _, sourcePhoto in ipairs(photos) do
            if sourcePhoto:getFormattedMetadata("fileType") == "JPEG" then
                processed = processed + 1
                local basename = LrPathUtils.removeExtension(sourcePhoto:getFormattedMetadata("fileName")) .. "."
                logger:debug(basename)
                local matches = catalog:findPhotos {
                    searchDesc = {
                        {
                            criteria = "filename",
                            operation = "beginsWith",
                            value = basename,
                        },
                        {
                            {
                                criteria = "fileFormat",
                                operation = "==",
                                value = "RAW",
                            },
                            {
                                criteria = "fileFormat",
                                operation = "==",
                                value = "DNG",
                            },
                            combine = "union"
                        },
                        combine = "intersect"
                    }
                }
                if #matches > 0 then
                    starRating = sourcePhoto:getRawMetadata("rating")
                    colorLabel = sourcePhoto:getRawMetadata("colorNameForLabel")
                    for _, targetPhoto in pairs(matches) do
                        if targetPhoto:getRawMetadata("isVirtualCopy") == false then
                            matched = matched + 1
                            logger:debug("Target: " .. targetPhoto:getFormattedMetadata("fileName"))
                            if not dryRun then
                                if copyStarRating then
                                    logger:debug("Copying star rating")
                                    targetPhoto:setRawMetadata("rating", starRating)
                                end
                                if copyColorLabel then
                                    logger:debug("Copying color label")
                                    targetPhoto:setRawMetadata("colorNameForLabel", colorLabel)
                                end
                            end
                        end
                    end
                else
                    logger:debug("not found")
                end
            end
        end
    end)
    return processed, matched, protocol
end


local function settingsDialog(properties)
    local f = LrView.osFactory()
    local dialog = f:column {
        bind_to_object = properties,
        width = 600,
        f:group_box {
            title = "Meta Data",
            fill_horizontal = 1,
            spacing = f:control_spacing(),
            f:row {
                f:column {
                    f:checkbox {
                        title = "Star Rating",
                        value = LrView.bind("copyStarRating"),
                    },
                    f:checkbox {
                        title = "Color Label",
                        value = LrView.bind("copyColorLabel"),
                    },    
                },
                f:column {
                    f:checkbox {
                        title = "Title (TODO)",
                        value = LrView.bind("copyTitle"),
                    },
                    f:checkbox {
                        title = "GPS Data (TODO)",
                        value = LrView.bind("copyGpsData"),
                    },    
                }    
            }
        },
        f:group_box {
            title = "Options",
            fill_horizontal = 1,
            spacing = f:control_spacing(),
            f:row {
                f:column {
                    f:checkbox {
                        title = "Show Protocol",
                        value = LrView.bind("showProtocol"),
                    },        
                },
                f:column {
                    f:checkbox {
                        title = "Dry-Run",
                        value = LrView.bind("dryRun"),
                    },        
                }
            }
        }
    }
    local res = LrDialogs.presentModalDialog(
        {
            title = "Copy Meta Data",
            contents = dialog,
            blockTask = true,
        }
    )
    return "ok" == res
end


local function main()
    logger:debug("main() begin")
    LrFunctionContext.postAsyncTaskWithContext("copyMeta", function(context)
        context:addFailureHandler(function(status, err)
            LrDialogs.message("Internal Error: " .. err)
        end)
        local properties = LrBinding.makePropertyTable(context)
        properties.showProtocol = false
        properties.dryRun = false
        local options = {"dryRun"}
        local metaTypes = {"copyStarRating", "copyColorLabel", "copyTitle", "copyGpsData"}
        for _, key in ipairs(metaTypes) do
            properties[key] = true
        end
        local res = settingsDialog(properties)
        if res then
            args = {}
            for _, key in ipairs(mergeTables(options, metaTypes)) do
                logger:debug("Arg: " .. key)
                logger:debug(properties[key])
                args[key] = properties[key]
            end
            local processed, matched, protocol = doCopy(args)
            LrDialogs.showBezel(string.format("Completed: %d JPEGs processed, %d RAWs matched", processed, matched), 5)
        end
        logger:debug("main() end")
    end)
end


main()