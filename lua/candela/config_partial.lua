--- @class (exact) Candela.Config : Candela.ConfigStrict
--- @field window? Candela.WindowConfigPartial
--- @field engine? Candela.EngineConfigPartial
--- @field matching? Candela.MatchingConfigPartial
--- @field lightbox? Candela.LightboxConfigPartial
--- @field icons? Candela.IconsConfigPartial
--- @field palette? Candela.PaletteConfigPartial
--- @field syntax_highlighting? Candela.SyntaxHighlightingConfigPartial

--- @class (exact) Candela.WindowConfigPartial : Candela.WindowConfig, {}

--- @class (exact) Candela.EngineConfigPartial : Candela.EngineConfig, {}

--- @class (exact) Candela.MatchingConfigPartial : Candela.MatchingConfig, {}

--- @class (exact) Candela.LightboxConfigPartial : Candela.LightboxConfig, {}

--- @class (exact) Candela.IconsConfigPartial : Candela.IconsConfig, {}
--- @field highlight? Candela.IconsConfig.HighlightPartial
--- @field lightbox? Candela.IconsConfig.LightboxPartial
--- @field selection? Candela.IconsConfig.SelectionPartial
---
--- @class (exact) Candela.IconsConfig.HighlightPartial : Candela.IconsConfig.Highlight, {}
---
--- @class (exact) Candela.IconsConfig.LightboxPartial : Candela.IconsConfig.Lightbox, {}
---
--- @class (exact) Candela.IconsConfig.SelectionPartial : Candela.IconsConfig.Selection, {}

--- @class (exact) Candela.PaletteConfigPartial : Candela.PaletteConfig, {}
--- @field colors? Candela.PaletteConfig.ColorsPartial
--- @field swatches? Candela.PaletteConfig.SwatchesPartial
---
--- @class (exact) Candela.PaletteConfig.ColorsPartial : Candela.PaletteConfig.Colors, {}
---
--- @class (exact) Candela.PaletteConfig.SwatchesPartial : Candela.PaletteConfig.Swatches, {}

--- @class (exact) Candela.SyntaxHighlightingConfigPartial : Candela.SyntaxHighlightingConfig, {}
