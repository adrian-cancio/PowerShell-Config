# ---------------------------------------------------------------------------
# MATHEMATICAL CONSTANTS AND FUNCTIONS
# ---------------------------------------------------------------------------

# Functions
function Get-Sin {
    param([double]$Angle)
    return [Math]::Sin($Angle)
}

function Get-Cos {
    param([double]$Angle)
    return [Math]::Cos($Angle)
}

function Get-Tan {
    param([double]$Angle)
    return [Math]::Tan($Angle)
}

function Get-Asin {
    param([double]$Value)
    return [Math]::Asin($Value)
}

function Get-Acos {
    param([double]$Value)
    return [Math]::Acos($Value)
}

function Get-Atan {
    param([double]$Value)
    return [Math]::Atan($Value)
}

function Get-Atan2 {
    param([double]$y, [double]$x)
    return [Math]::Atan2($y, $x)
}

function Get-Sqrt {
    param([double]$Number)
    return [Math]::Sqrt($Number)
}

function Get-Pow {
    param([double]$Base, [double]$Exponent)
    return [Math]::Pow($Base, $Exponent)
}

function Get-Log {
    param([double]$Number)
    return [Math]::Log($Number)
}

function Get-Log10 {
    param([double]$Number)
    return [Math]::Log10($Number)
}

function Get-Exp {
    param([double]$Power)
    return [Math]::Exp($Power)
}

function Get-Abs {
    param([double]$Value)
    return [Math]::Abs($Value)
}

function Get-Round {
    param([double]$Value, [int]$Digits = 0)
    return [Math]::Round($Value, $Digits)
}

function Get-Ceiling {
    param([double]$Value)
    return [Math]::Ceiling($Value)
}

function Get-Floor {
    param([double]$Value)
    return [Math]::Floor($Value)
}

function Get-Max {
    param([double]$Val1, [double]$Val2)
    return [Math]::Max($Val1, $Val2)
}

function Get-Min {
    param([double]$Val1, [double]$Val2)
    return [Math]::Min($Val1, $Val2)
}

function Get-Truncate {
    param([double]$Value)
    return [Math]::Truncate($Value)
}

function Get-Sign {
    param([double]$Value)
    return [Math]::Sign($Value)
}

Export-ModuleMember -Function Get-Sin, Get-Cos, Get-Tan, Get-Asin, Get-Acos, Get-Atan, Get-Atan2, Get-Sqrt, Get-Pow, Get-Log, Get-Log10, Get-Exp, Get-Abs, Get-Round, Get-Ceiling, Get-Floor, Get-Max, Get-Min, Get-Truncate, Get-Sign
