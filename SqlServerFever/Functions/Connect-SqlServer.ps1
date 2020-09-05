<#
    .SYNOPSIS
        Validate the connection details and store them in the default parameter
        values for SQL commands.

    .DESCRIPTION
        Use the Test-SqlConnection command to test the connection. If it was
        successful, store the connection details in the PSDefaultParameterValues
        variable:
        - *-Dba*:SqlInstance
        - *-Dba*:SqlCredential
        - *-Sql*:SqlInstance
        - *-Sql*:SqlCredential
        - *-Sql*:ServerInstance
        - *-Sql*:Credential

    .INPUTS
        None.

    .OUTPUTS
        None.

    .LINK
        https://github.com/claudiospizzi/SqlServerFever
#>
function Connect-SqlServer
{
    [CmdletBinding()]
    param
    (
        # SQL instance name.
        [Parameter(Mandatory = $true)]
        [System.String]
        $SqlInstance,

        # SQL Login. If not specified, use integrated security.
        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        $SqlCredential,

        # Optionally store the database name to connect to.
        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [System.String]
        $Database
    )

    try
    {
        if ($PSBoundParameters.ContainsKey('SqlCredential'))
        {
            Test-SqlConnection -SqlInstance $SqlInstance -SqlCredential $SqlCredential -WarningAction 'SilentlyContinue' -ErrorAction 'Stop' | Out-Null

            $Global:PSDefaultParameterValues['*-Dba*:SqlInstance'] = $SqlInstance
            $Global:PSDefaultParameterValues['*-Dba*:SqlCredential'] = $SqlCredential

            $Global:PSDefaultParameterValues['*-Sql*:SqlInstance'] = $SqlInstance
            $Global:PSDefaultParameterValues['*-Sql*:SqlCredential'] = $SqlCredential

            $Global:PSDefaultParameterValues['*-Sql*:ServerInstance'] = $SqlInstance
            $Global:PSDefaultParameterValues['*-Sql*:Credential'] = $SqlCredential
        }
        else
        {
            Test-SqlConnection -SqlInstance $SqlInstance -WarningAction 'SilentlyContinue' -ErrorAction 'Stop' | Out-Null

            $Global:PSDefaultParameterValues['*-Dba*:SqlInstance'] = $SqlInstance
            $Global:PSDefaultParameterValues.Remove('*-Dba*:SqlCredential')

            $Global:PSDefaultParameterValues['*-Sql*:SqlInstance'] = $SqlInstance
            $Global:PSDefaultParameterValues.Remove('*-Sql*:SqlCredential')

            $Global:PSDefaultParameterValues['*-Sql*:ServerInstance'] = $SqlInstance
            $Global:PSDefaultParameterValues.Remove('*-Sql*:Credential')
        }

        if ($PSBoundParameters.ContainsKey('Database'))
        {
            $Global:PSDefaultParameterValues['*-Dba*:Database'] = $Database

            $Global:PSDefaultParameterValues['*-Sql*:Database'] = $Database
        }
        else
        {
            $Global:PSDefaultParameterValues.Remove('*-Dba*:Database')

            $Global:PSDefaultParameterValues.Remove('*-Sql*:Database')
        }
    }
    catch
    {
        throw "Failed to connect to the SQL Server $SqlInstance with error: $_"
    }
}
