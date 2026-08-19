--[[
    types (ModuleScript)
    Path: ReplicatedFirst → G3 → Base
    Parent: Base
    Properties:
        Disabled: false
    Exported: 2026-08-19 06:16:26 (web)
]]

local T = {}

export type func = (...any) -> ...any

export type callback = () -> ()

export type dict = {[string]: any}

export type array = {[number]: any}

export type key = any 

export type table = {[key]: any}

export type metatable = typeof(setmetatable({}, {}))

--A point describing the part's spatial data
export type g3Point = {
	["Position"]: Vector2,
	["Offset"]: number,
	["Rotation"]: Vector3,
	
	--Only on g3Guis
	["RotationCenter"]: Vector3?
}

--Used to lookup spatial data for the positioning script by going through parent and child relations
export type pointLookup = {
	--All g3Guis will be in this top level
	[Model]: {
		--All g3 parts will be below their parent's point
		--This is a nice optimization as this data structure stores all the data that g3 will need to reposition parts
		--This would also mean that it has to only get the parent's data once, instead of every time
		[BasePart]: g3Point
	}
}
export type parentPointLookup = {
	[Instance]: g3Point
}

--Used in every g3 instance to add custom property functionality
export type customPropertyData = {
	["customCallbacks"]: {[key]: callback},
	[key]: any
}

--Used internally to set bounds on config values
export type bounds = {
	--Defines the type that the config value should be
	["type"]: string?,
	
	--Defines a min and a max for the config value
	["clamp"]: {min: number, max: number}?,
	
	--Blacklists an array of values that the config can be
	["no"]: array?,
	
	--Whitelists an array of values that the config cna be
	["yes"]: array?
}


--Base layer for all parts to get added to
--If you put a g3Gui inside another g3Gui, absolute values like position and rotation will stay absolute and not relative on the parent g3Gui
export type g3Gui = {
	--Internal data used in the g3 module
	--All the actual values of the object are stored in this internal storage
	["__internal"]: 
		{
			--Stores custom property data (only used internally by the g3 module)
			["customPropertyData"]: customPropertyData, 
			
			--Custom properties that can only be read from
			["readOnly"]: array,
			
			--All default g3 properties are stored here
			[string]: any?
		},
	
	--All parts have a model that all parts are added to
	["Model"]: Model,
	
	--[[ Properties ]]--
	
	--the Name property is used for all binded top level instances of the part
	["Name"]: string,

	--The parent g3 part the part is based off of
	--Defaults to main if its a top-level part
	["Parent"]: g3Gui,

	--Describes absolute position the origin point for which all parts will deviate from
	--You can set this to a UDim2 to define relative scaling to the screen, you can modify this behavior in the config
	["Position"]: Vector2 | UDim2,

	--Describes the absolute (origin) rotation that all parts will deviate from
	["Rotation"]: Vector3,
	
	--Define a shift to the rotation center of the g3Gui
	--By default, the rotation center is 0, 0, 0, or the center of the model
	--Think of this as X and Y as the positions, and Z is the offset
	["RotationCenter"]: Vector3,

	--Determines absolute offset from the camera (how far it is), for which all parts will deviate from
	["Offset"]: number,

	--Determines if the part is enabled (visible) or disabled
	["Enabled"]: boolean,

	--Describes various children of the g3Gui, such as g3Guis
	["Children"]: array,

	--Describes the parts of the g3Gui
	["Parts"]: array,
	
	--[[ Custom methods ]]--

	--Add a new custom property to the g3Gui
	["CustomProperty"]: (table: g3Gui, key: string, value: any, customCallback: (g3Gui: g3Gui, oldValue: any, newValue: any) -> ()?) -> (),
	
	--Bind an instance to the top level of the table (mostly for internal g3 usage)
	["BindPartToTable"]: (table: g3Gui, value: Instance, nameOfValue: string) -> (),
	
	--Destroys the G3Gui (USE OVER g3Gui.Model:Destroy() !!!!)
	["Destroy"]: (table: g3Gui) -> (),
	
	--Clones the given g3Gui
	["Clone"]: (table: g3Gui) -> g3Gui,
	
	--Change the spatial data of the g3Gui according to the given point
	--Think of it as applying a velocity to the g3Gui for one frame
	["Velocity"]: (table: g3Gui, point: g3Point) -> (),
	
	--Change the spatial data of the g3Gui and all of its children according to the given point
	["VelocityIterative"]: (table: g3Gui, point: g3Point) -> ()
}


--Describes a single part in a g3Gui
export type g3Part = {
	--Internal data used in the g3 module
	--All the actual values of the object are stored in this internal storage]
	["__internal"]: 
		{
			["customPropertyData"]: customPropertyData, 
			["readOnly"]: array,
			[string]: any?
		},
	
	--Access original part properties if neccesary
	["Part"]: Part,

	--[[ Properties ]]--
	
	--Explained above
	["Name"]: string,
	["Parent"]: table,
	["Type"]: string,
	["Enabled"]: boolean,

	--Describes its position from the screen relative to the g3Gui
	--You can set this to a UDim2 to define relative scaling to the gui + the screen, you can modify this behavior in the config
	["Position"]: Vector2 | UDim2,

	--Describes relative rotation from the g3Gui
	["Rotation"]: Vector3,

	--Describes the size of the part in "2D" size
	--You can set this to a UDim2 to define relative scaling to the screen, you can modify this behavior in the config
	["Size"]: Vector2 | UDim2,

	--Determines the thickness of the part (its size in the Z axis)
	["Thickness"]: number,

	--Determines relative offset from the g3Gui, movement in the axis of the Camera's look vector
	["Offset"]: number,

	--[[ Custom methods ]]

	--Explained above
	["CustomProperty"]: (table: g3Part, key: string, value: any, customCallback: (g3Gui: g3Gui, oldValue: any, newValue: any) -> ()?) -> (),
	["BindPartToTable"]: (table: g3Part, value: Instance, nameOfValue: string) -> (),
	["Destroy"]: (table: g3Part) -> (),
	["Clone"]: (table: g3Part) -> g3Part,
	["Velocity"]: (table: g3Part, point: g3Point) -> (),
	
	--Attaches a surface gui to the part and returns the instance
	--You can attach a gui to a part, then clone ui elements from screenGUIs to it to make it functional (just keep in mind aspect ratio)
	["AttachSurfaceGUI"]: (table: g3Part, name: string?) -> SurfaceGui
}

--Stores all custom g3 types
export type g3Any = g3Gui | g3Part


return T
