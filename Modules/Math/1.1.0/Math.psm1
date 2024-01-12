$MathEvaluator = new-object LoreSoft.MathExpressions.MathEvaluator

function Invoke-MathEvaluator {
    <#
        .SYNOPSIS
            Evaluates mathematical expressions, with support for basic functions (sqrt, cos, etc.) and conversions ([in->ft] and [ft->m] etc.) and variables.
        .DESCRIPTION
            This is currently using the old LoreSoft.Calculator engine https://github.com/loresoft/Calculator

            It supports:
            - Math expressions as strings, including grouping
            - Trigonometry and various other functions
            - Common unit conversions in Length, Mass, Speed, Temperature, Time, and Volume
            - Variables including the last "answer"

        .EXAMPLE
            math 2^5

            32
        .EXAMPLE
            math "(2 ^ 3) * sqrt(pi)"

            14.179630807244127
        .EXAMPLE
            math "120 [in->ft]"

            10

            C:\PS> math answer [ft->m]

            3.048
    #>
    [Alias("ime", "math", "calc", "c")]
    [CmdletBinding()]
    param(
        # A mathematical expression
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ValueFromRemainingArguments)]
        [string[]]$Expression
    )
    end {
        Write-Verbose "$Expression"
        $MathEvaluator.Evaluate("$Expression")
    }
}

function Set-MathVariable {
    <#
        .SYNOPSIS
            Set a variable that's usable for math expressions. Note that the values are currently always stored using doubles.
        .EXAMPLE
            Set-MathVariable α 2.5029

            Defines an approximation of one of Feigenbaum's constants
        .EXAMPLE
            Set-MathVariable δ 4.6692

            Defines an approximation of one of Feigenbaum's constants
        .EXAMPLE
            Set-MathVariable φ 1.618033988749895

            Defines an approximation of the golden ratio
    #>
    [Alias("smv")]
    [CmdletBinding()]
    param(
        # The name of the variable
        [Parameter(Mandatory)]
        [string]$Name,

        # The value of the variable (as a double)
        [Parameter(Mandatory)]
        [double]$Value
    )
    end {
        $MathEvaluator.Variables[$Name] = $Value
    }
}


Export-ModuleMember -Function * -Alias * -Variable MathEvaluator