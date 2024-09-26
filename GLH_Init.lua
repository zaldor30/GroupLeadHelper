local _, ns = ... -- Namespace (myaddon, namespace)
ns = {}

GLH = LibStub('AceAddon-3.0'):NewAddon('GroupLeadHelper', 'AceConsole-3.0', 'AceEvent-3.0', 'AceTimer-3.0')
GLH.title = C_AddOns.GetAddOnMetadata('GroupLeadHelper', 'Title')
GLH.author  = C_AddOns.GetAddOnMetadata('GroupLeadHelper', 'Author')
GLH.version = C_AddOns.GetAddOnMetadata('GroupLeadHelper', 'Version')
GLH.ICON_PATH = 'Interface\\AddOns\\GroupLeadHelper\\Images\\'