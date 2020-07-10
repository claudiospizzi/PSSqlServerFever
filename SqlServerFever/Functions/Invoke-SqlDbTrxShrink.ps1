<#
    .SYNOPSIS
        Shrink a transaction log file of a SQL Server Database. After shrinking,
        the file will be expandet to the target size.

    .DESCRIPTION


    .LINK
        https://github.com/claudiospizzi/SqlServerFever
#>
function Invoke-SqlDbTrxShrink
{
    [CmdletBinding(SupportsShouldProcess = $true,  ConfirmImpact = 'High')]
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
        $Database,

        # The target size of the transaction log file.
        [Parameter(Mandatory = $true)]
        [System.Int64]
        $TargetSize,

        # Database where SQL Maintenance Solution Jobs by Ola Hallengren are
        # stored in.
        [Parameter(Mandatory = $false)]
        [System.String]
        $MaintenanceSolutionDatabase = 'DBATools',

        # Validity time for the transaction log backup created by the SQL
        # Maintenance Solution.
        [Parameter(Mandatory = $false)]
        [System.Int32]
        $MaintenanceSolutionCleanupTime = 72,

        # Auto-shrink to the target size.
        [Parameter(Mandatory = $false)]
        [Switch]
        $Auto
    )

    # # Update target size for SQL Server.
    # $TargetSize = $TargetSize / 1024 * 1000

    # Define and verify the connection splat to the SQL Server.
    $sqlConnection = @{
        SqlInstance = $SqlInstance
        Database    = $Database
    }
    if ($PSBoundParameters.ContainsKey('SqlCredential'))
    {
        $sqlConnection['SqlCredential'] = $SqlCredential
    }
    Test-SqlConnection @sqlConnection -Verbose:$false | Out-Null

    $databaseLogFileName = Get-DbaDbFile @sqlConnection -Verbose:$false | Where-Object { $_.Type -eq 1 } | Select-Object -First 1 -ExpandProperty 'LogicalName'

    # Prepare the transaction log backup query.
    $queryBackup  = "EXECUTE [{0}].[dbo].[DatabaseBackup] @Databases = '{1}', @BackupType = 'LOG', @Compress = 'Y', @Verify = 'Y', @CleanupTime = {2}, @CheckSum = 'Y', @LogToTable = 'Y'" -f $MaintenanceSolutionDatabase, $Database, $MaintenanceSolutionCleanupTime
    $queryShrink  = "DBCC SHRINKFILE('{0}', 1)" -f $databaseLogFileName
    $queryResize  = "ALTER DATABASE [{0}] MODIFY FILE ( NAME = N'{1}', SIZE = {2}KB )" -f $Database, $databaseLogFileName, (($TargetSize / 1KB) -as [System.Int64])

    # Get and show the transaction log state
    $state = Get-SqlDbTrxLogState @sqlConnection
    Write-Output $state

    while (($state.FileSize -gt $TargetSize -or $state.VlfCount -gt 8) -and ($Auto.IsPresent -or $PSCmdlet.ShouldProcess($state.LogFile, $queryShrink)))
    {
        Write-Verbose 'SQL TRX SHRINK: Invoke database transaction log backup'
        Invoke-DbaQuery @sqlConnection -Query $queryBackup | Out-Null

        Write-Verbose 'SQL TRX SHRINK: Invoke transaction log shrink command'
        Invoke-DbaQuery @sqlConnection -Query $queryShrink | Out-Null

        # Get and show the transaction log state
        $state = Get-SqlDbTrxLogState @sqlConnection
        Write-Output $state
    }

    if ($state.FileSize -lt $TargetSize -and ($Auto.IsPresent -or $PSCmdlet.ShouldProcess($state.Logfile, $queryResize)))
    {
        Write-Verbose 'SQL TRX SHRINK: Set database transaction log to target size'
        Invoke-DbaQuery @sqlConnection -Query $queryResize

        # Get and show the transaction log state
        $state = Get-SqlDbTrxLogState @sqlConnection
        Write-Output $state
    }
}
