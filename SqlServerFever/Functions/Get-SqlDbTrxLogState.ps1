<#
    .SYNOPSIS
        Get the current state of a SQL Server database transaction log file.
#>
function Get-SqlDbTrxLogState
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

        # Database to connect, be default master.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Database
    )

    # Define and verify the connection splat to the SQL Server.
    $sqlConnection = @{
        SqlInstance = $SqlInstance
        Database    = $Database
    }
    if ($PSBoundParameters.ContainsKey('SqlCredential'))
    {
        $sqlConnection['SqlCredential'] = $SqlCredential
    }

    # Query the SQL Server about the
    $logFile = Get-DbaDbFile @sqlConnection -Verbose:$false | Where-Object { $_.Type -eq 1 } | Select-Object -First 1
    $logInfo = Invoke-DbaQuery @sqlConnection -Query 'DBCC LOGINFO'

    # Show the current state of the database transaction log file.
    [PSCustomObject] @{
        PSTypeName  = 'SqlServerFever.DatabaseTransactionLogState'
        SqlInstance = $SqlInstance
        Database    = $Database
        LogFile     = $logFile.LogicalName
        FileSize    = $logFile.Size.Byte
        VlfCount    = @($logInfo).Count
    }
}
